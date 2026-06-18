# 桂林学院新闻中心 - 一键启动脚本
# 支持在任意 Windows 电脑上克隆后直接运行
# 自动检测/安装依赖、配置国内镜像源

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ========== 自动提权 ==========
$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "需要管理员权限来安装依赖，正在请求提权..." -ForegroundColor Yellow
    $scriptPath = $MyInvocation.MyCommand.Path
    # 使用 -NoExit 确保提权后的窗口不会闪退
    Start-Process powershell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-NoExit", "-File", "`"$scriptPath`"" -Verb RunAs
    exit
}

# ========== 全局变量 ==========
$rootPath = $PSScriptRoot
$frontendPath = Join-Path $rootPath "frontend"
$backendPort = 8080
$frontendPort = 5173
$m2Path = Join-Path $env:USERPROFILE ".m2"
$m2Settings = Join-Path $m2Path "settings.xml"
$localMavenSettings = Join-Path $rootPath "maven-settings.xml"

# ========== 工具函数 ==========
function Write-Step($msg) {
    Write-Host ""
    Write-Host "[INFO] $msg" -ForegroundColor Cyan
}

function Write-OK($msg) {
    Write-Host "  [OK] $msg" -ForegroundColor Green
}

function Write-Warn($msg) {
    Write-Host "  [!] $msg" -ForegroundColor Yellow
}

function Write-Err($msg) {
    Write-Host "  [X] $msg" -ForegroundColor Red
}

function Test-Command($cmd) {
    return [bool](Get-Command $cmd -ErrorAction SilentlyContinue)
}

function Test-Port($port) {
    try {
        $conn = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
        return $null -ne $conn
    } catch {
        $tcp = New-Object System.Net.Sockets.TcpClient
        try {
            $tcp.Connect("127.0.0.1", $port)
            $tcp.Close()
            return $true
        } catch {
            return $false
        }
    }
}

function Get-PortProcessId($port) {
    try {
        $conn = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
        if ($conn) {
            return $conn.OwningProcess | Select-Object -First 1
        }
    } catch {}
    return $null
}

function Stop-PortProcess($port) {
    $procId = Get-PortProcessId $port
    if ($procId) {
        try {
            $proc = Get-Process -Id $procId -ErrorAction Stop
            $procName = $proc.ProcessName
            # 只自动关闭 java/node 相关进程，避免误杀其他程序
            if ($procName -match 'java|node|mvn') {
                Write-Warn "端口 $port 被进程 $procName (PID: $procId) 占用，正在关闭..."
                Stop-Process -Id $procId -Force -ErrorAction SilentlyContinue
                Start-Sleep -Seconds 2
                if (-not (Test-Port $port)) {
                    Write-OK "已关闭占用进程 $procName，端口 $port 已释放"
                    return $true
                } else {
                    return $false
                }
            } else {
                Write-Warn "端口 $port 被进程 $procName (PID: $procId) 占用（非本项目进程）"
                return $false
            }
        } catch {
            return $false
        }
    }
    return $true
}

function Find-AvailablePort($startPort) {
    $port = $startPort
    while ($port -lt ($startPort + 100)) {
        if (-not (Test-Port $port)) {
            return $port
        }
        $port++
    }
    return $startPort
}

function Get-JavaVersion {
    $oldEAP = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $output = & java -version 2>&1 | Out-String
        if ($output -match 'version "(\d+)') {
            $ver = [int]$matches[1]
            # Java 8 的版本号是 1.8，需要特殊处理
            if ($output -match 'version "1\.(\d+)') {
                $ver = [int]$matches[1]
            }
            return $ver
        }
    } catch {} finally {
        $ErrorActionPreference = $oldEAP
    }
    return 0
}

# ========== 检查管理员权限 ==========
function Test-Administrator {
    $user = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($user)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# ========== 自动安装函数 ==========

function Install-Java {
    Write-Step "正在安装 JDK 17 ..."

    # 优先使用 winget（Windows 10 1809+ 自带）
    if (Test-Command "winget") {
        Write-Host "  使用 winget 安装 Microsoft OpenJDK 17..."
        try {
            winget install --id Microsoft.OpenJDK.17 --accept-source-agreements --accept-package-agreements --silent
            # 刷新环境变量
            $env:JAVA_HOME = "C:\Program Files\Microsoft\jdk-17"
            $env:Path = "$env:JAVA_HOME\bin;$env:Path"
            if (Test-Command "java") {
                Write-OK "JDK 17 安装成功（winget）"
                return $true
            }
        } catch {
            Write-Warn "winget 安装失败，尝试手动下载..."
        }
    }

    # 手动下载安装
    $jdkUrl = "https://download.microsoft.com/openjdk/17.0.13/openjdk-17.0.13_windows-x64_bin.zip"
    $jdkZip = Join-Path $env:TEMP "openjdk-17.zip"
    $jdkDir = "C:\Program Files\Microsoft\jdk-17"

    Write-Host "  下载 OpenJDK 17..."
    try {
        # 设置 TLS 1.2
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $jdkUrl -OutFile $jdkZip -UseBasicParsing -TimeoutSec 120
    } catch {
        Write-Err "下载 JDK 失败: $($_.Exception.Message)"
        Write-Host ""
        Write-Host "  请手动安装 JDK 17+:" -ForegroundColor Yellow
        Write-Host "  下载地址: https://learn.microsoft.com/java/openjdk/"
        Write-Host "  或使用国内镜像: https://mirrors.tuna.tsinghua.edu.cn/Adoptium/"
        return $false
    }

    Write-Host "  解压安装..."
    try {
        if (Test-Path $jdkDir) { Remove-Item $jdkDir -Recurse -Force }
        Expand-Archive -Path $jdkZip -DestinationPath "C:\Program Files\Microsoft" -Force
        # 重命名目录
        $extracted = Get-ChildItem "C:\Program Files\Microsoft" -Directory -Filter "jdk-17*"
        if ($extracted) {
            Rename-Item $extracted.FullName $jdkDir
        }
        Remove-Item $jdkZip -Force
    } catch {
        Write-Err "解压 JDK 失败: $($_.Exception.Message)"
        return $false
    }

    # 设置环境变量
    $env:JAVA_HOME = $jdkDir
    $env:Path = "$jdkDir\bin;$env:Path"
    [Environment]::SetEnvironmentVariable("JAVA_HOME", $jdkDir, "Machine")
    $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    if ($machinePath -notlike "*$jdkDir\bin*") {
        [Environment]::SetEnvironmentVariable("Path", "$jdkDir\bin;$machinePath", "Machine")
    }

    if (Test-Command "java") {
        Write-OK "JDK 17 安装成功"
        return $true
    }
    Write-Err "JDK 安装后仍无法使用"
    return $false
}

function Install-Maven {
    Write-Step "正在安装 Maven 3.9 ..."

    $mavenVersion = "3.9.9"

    # 尝试从官方页面动态获取最新的 3.9.x 版本号，避免旧版本被移除导致 404
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    try {
        $dlcdnPage = Invoke-WebRequest -Uri "https://dlcdn.apache.org/maven/maven-3/" -UseBasicParsing -TimeoutSec 10
        if ($dlcdnPage.Content -match 'href="(3\.9\.\d+)/"') {
            $mavenVersion = $matches[1]
            Write-Host "  检测到最新版本: Maven $mavenVersion"
        }
    } catch {
        Write-Warn "无法检测最新版本，使用默认 $mavenVersion"
    }

    # 下载源列表：清华镜像 → 官方 dlcdn → Apache 归档（永久保留所有版本）
    $mavenUrls = @(
        @{ Url = "https://mirrors.tuna.tsinghua.edu.cn/apache/maven/maven-3/$mavenVersion/binaries/apache-maven-$mavenVersion-bin.zip"; Name = "清华镜像" },
        @{ Url = "https://dlcdn.apache.org/maven/maven-3/$mavenVersion/binaries/apache-maven-$mavenVersion-bin.zip"; Name = "官方地址" },
        @{ Url = "https://archive.apache.org/dist/maven/maven-3/$mavenVersion/binaries/apache-maven-$mavenVersion-bin.zip"; Name = "Apache 归档" }
    )
    $mavenZip = Join-Path $env:TEMP "apache-maven-$mavenVersion-bin.zip"
    $mavenDir = "C:\Program Files\Apache\maven"

    $downloaded = $false
    foreach ($source in $mavenUrls) {
        Write-Host "  下载 Maven $mavenVersion（$($source.Name)）..."
        try {
            Invoke-WebRequest -Uri $source.Url -OutFile $mavenZip -UseBasicParsing -TimeoutSec 120
            $downloaded = $true
            Write-OK "下载成功（$($source.Name)）"
            break
        } catch {
            Write-Warn "$($source.Name)下载失败: $($_.Exception.Message)"
        }
    }

    if (-not $downloaded) {
        Write-Err "所有下载源均失败"
        Write-Host "  请手动安装 Maven 3.6+:" -ForegroundColor Yellow
        Write-Host "  下载地址: https://maven.apache.org/download.cgi"
        return $false
    }

    Write-Host "  解压安装..."
    try {
        $tempExtract = Join-Path $env:TEMP "maven-extract"
        if (Test-Path $tempExtract) { Remove-Item $tempExtract -Recurse -Force }
        Expand-Archive -Path $mavenZip -DestinationPath $tempExtract -Force
        $extractedDir = Get-ChildItem $tempExtract -Directory | Select-Object -First 1
        if (Test-Path $mavenDir) { Remove-Item $mavenDir -Recurse -Force }
        New-Item -ItemType Directory -Path $mavenDir -Force | Out-Null
        Copy-Item "$($extractedDir.FullName)\*" $mavenDir -Recurse -Force
        Remove-Item $tempExtract -Recurse -Force
        Remove-Item $mavenZip -Force
    } catch {
        Write-Err "解压 Maven 失败: $($_.Exception.Message)"
        return $false
    }

    # 设置环境变量
    $env:Path = "$mavenDir\bin;$env:Path"
    [Environment]::SetEnvironmentVariable("MAVEN_HOME", $mavenDir, "Machine")
    $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    if ($machinePath -notlike "*$mavenDir\bin*") {
        [Environment]::SetEnvironmentVariable("Path", "$mavenDir\bin;$machinePath", "Machine")
    }

    if (Test-Command "mvn") {
        Write-OK "Maven $mavenVersion 安装成功"
        return $true
    }
    Write-Err "Maven 安装后仍无法使用"
    return $false
}

function Install-Node {
    Write-Step "正在安装 Node.js 20 LTS ..."

    # 优先使用 winget
    if (Test-Command "winget") {
        Write-Host "  使用 winget 安装 Node.js LTS..."
        try {
            winget install --id OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements --silent
            # 刷新环境变量
            $nodePath = "C:\Program Files\nodejs"
            $env:Path = "$nodePath;$env:Path"
            if (Test-Command "node") {
                Write-OK "Node.js 安装成功（winget）"
                return $true
            }
        } catch {
            Write-Warn "winget 安装失败，尝试手动下载..."
        }
    }

    # 手动下载安装
    $nodeUrl = "https://npmmirror.com/mirrors/node/v20.18.1/node-v20.18.1-win-x64.zip"
    $nodeZip = Join-Path $env:TEMP "node-v20.zip"
    $nodeDir = "C:\Program Files\nodejs"

    Write-Host "  下载 Node.js 20（国内镜像 npmmirror.com）..."
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    try {
        Invoke-WebRequest -Uri $nodeUrl -OutFile $nodeZip -UseBasicParsing -TimeoutSec 180
    } catch {
        Write-Err "下载 Node.js 失败: $($_.Exception.Message)"
        Write-Host "  请手动安装 Node.js 18+:" -ForegroundColor Yellow
        Write-Host "  下载地址: https://nodejs.org/"
        Write-Host "  国内镜像: https://npmmirror.com/mirrors/node/"
        return $false
    }

    Write-Host "  解压安装..."
    try {
        $tempExtract = Join-Path $env:TEMP "node-extract"
        if (Test-Path $tempExtract) { Remove-Item $tempExtract -Recurse -Force }
        Expand-Archive -Path $nodeZip -DestinationPath $tempExtract -Force
        $extractedDir = Get-ChildItem $tempExtract -Directory | Select-Object -First 1
        if (Test-Path $nodeDir) { Remove-Item $nodeDir -Recurse -Force }
        New-Item -ItemType Directory -Path $nodeDir -Force | Out-Null
        Copy-Item "$($extractedDir.FullName)\*" $nodeDir -Recurse -Force
        Remove-Item $tempExtract -Recurse -Force
        Remove-Item $nodeZip -Force
    } catch {
        Write-Err "解压 Node.js 失败: $($_.Exception.Message)"
        return $false
    }

    # 设置环境变量
    $env:Path = "$nodeDir;$env:Path"
    [Environment]::SetEnvironmentVariable("NODE_HOME", $nodeDir, "Machine")
    $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    if ($machinePath -notlike "*$nodeDir*") {
        [Environment]::SetEnvironmentVariable("Path", "$nodeDir;$machinePath", "Machine")
    }

    if (Test-Command "node") {
        Write-OK "Node.js 20 安装成功"
        return $true
    }
    Write-Err "Node.js 安装后仍无法使用"
    return $false
}

# ========== 镜像配置函数 ==========

function Setup-MavenMirror {
    Write-Step "配置 Maven 阿里云镜像..."

    # 确保项目自带配置存在
    if (-not (Test-Path $localMavenSettings)) {
        Write-Warn "项目 maven-settings.xml 不存在，跳过"
        return
    }

    # 复制到用户 .m2 目录
    if (-not (Test-Path $m2Path)) {
        New-Item -ItemType Directory -Path $m2Path -Force | Out-Null
    }

    # 检查是否已配置或是否需要更新
    $needUpdate = $true
    if (Test-Path $m2Settings) {
        $existingContent = Get-Content $m2Settings -Raw -ErrorAction SilentlyContinue
        $newContent = Get-Content $localMavenSettings -Raw
        if ($existingContent -eq $newContent) {
            $needUpdate = $false
        }
    }

    if ($needUpdate) {
        Copy-Item $localMavenSettings $m2Settings -Force
        Write-OK "Maven 阿里云镜像已配置到 $m2Settings"
    } else {
        Write-OK "Maven 阿里云镜像已存在，跳过"
    }
}

function Setup-NpmMirror {
    Write-Step "配置 npm 国内镜像源..."

    try {
        # 设置淘宝镜像
        & npm config set registry https://registry.npmmirror.com
        & npm config set sass_binary_site https://npmmirror.com/mirrors/node-sass
        & npm config set electron_mirror https://npmmirror.com/mirrors/electron/
        & npm config set puppeteer_download_host https://npmmirror.com/mirrors
        Write-OK "npm 镜像已设置为 registry.npmmirror.com"
    } catch {
        Write-Warn "npm 镜像配置失败，将使用默认源"
    }
}

# ========== 主流程 ==========

Clear-Host
Write-Host "==========================================" -ForegroundColor DarkGreen
Write-Host "      桂林学院新闻中心 - 一键启动" -ForegroundColor Green
Write-Host "      Guilin University News Center" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor DarkGreen
Write-Host ""

# 检查管理员权限（已在脚本开头自动提权，此处仅做提示）
Write-Host "  管理员权限: 已确认" -ForegroundColor Gray
Write-Host ""

# [1/7] 检查并处理端口占用
Write-Step "[1/7] 检查端口占用..."

# 后端端口处理
if (Test-Port $backendPort) {
    Write-Warn "后端端口 $backendPort 被占用"
    $cleaned = Stop-PortProcess $backendPort
    if (-not $cleaned) {
        # 无法清理，自动寻找可用端口
        $newPort = Find-AvailablePort ($backendPort + 1)
        Write-Warn "自动切换后端端口: $backendPort -> $newPort"
        $backendPort = $newPort
    }
}
Write-OK "后端端口: $backendPort"

# 前端端口处理
if (Test-Port $frontendPort) {
    Write-Warn "前端端口 $frontendPort 被占用"
    $cleaned = Stop-PortProcess $frontendPort
    if (-not $cleaned) {
        # 无法清理，自动寻找可用端口
        $newPort = Find-AvailablePort ($frontendPort + 1)
        Write-Warn "自动切换前端端口: $frontendPort -> $newPort"
        $frontendPort = $newPort
    }
}
Write-OK "前端端口: $frontendPort"

# [2/7] 检查/安装 Java
Write-Step "[2/7] 检查 Java 环境..."
if (Test-Command "java") {
    $javaVersionStr = ""
    $oldEAP = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $javaVersionStr = (& java -version 2>&1 | Out-String).Split("`n")[0].Trim()
    } catch {}
    $ErrorActionPreference = $oldEAP
    $javaVer = Get-JavaVersion
    if ($javaVer -ge 11) {
        Write-OK "Java 已安装: $javaVersionStr"
    } else {
        # 版本较低但可能仍可用，只警告不退出
        Write-Warn "Java 版本较低: $javaVersionStr（建议 11+，将尝试继续运行）"
    }
} else {
    Write-Warn "未检测到 Java"
    if ($isAdmin) {
        if (Install-Java) { } else { Read-Host "按 Enter 键退出"; exit 1 }
    } else {
        Write-Host "  请以管理员身份运行脚本以自动安装，或手动安装 JDK 11+" -ForegroundColor Yellow
        Read-Host "按 Enter 键退出"
        exit 1
    }
}

# [3/7] 检查/安装 Maven
Write-Step "[3/7] 检查 Maven 环境..."
if (Test-Command "mvn") {
    $mvnVersion = ""
    $oldEAP = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $mvnVersion = (& mvn -version 2>&1 | Out-String).Split("`n")[0].Trim()
    } catch {}
    $ErrorActionPreference = $oldEAP
    Write-OK "Maven 已安装: $mvnVersion"
} else {
    Write-Warn "未检测到 Maven"
    if ($isAdmin) {
        if (Install-Maven) { } else { Read-Host "按 Enter 键退出"; exit 1 }
    } else {
        Write-Host "  请以管理员身份运行脚本以自动安装，或手动安装 Maven 3.6+" -ForegroundColor Yellow
        Read-Host "按 Enter 键退出"
        exit 1
    }
}

# [4/7] 检查/安装 Node.js
Write-Step "[4/7] 检查 Node.js 环境..."
if (Test-Command "node") {
    $nodeVersion = & node -version
    Write-OK "Node.js 已安装: $nodeVersion"
    if ($nodeVersion -match 'v(\d+)') {
        $nodeVer = [int]$matches[1]
        if ($nodeVer -lt 16) {
            # 版本较低但可能仍可用，只警告不退出
            Write-Warn "Node.js 版本较低: $nodeVersion（建议 16+，将尝试继续运行）"
        }
    }
} else {
    Write-Warn "未检测到 Node.js"
    if ($isAdmin) {
        if (Install-Node) { } else { Read-Host "按 Enter 键退出"; exit 1 }
    } else {
        Write-Host "  请以管理员身份运行脚本以自动安装，或手动安装 Node.js 16+" -ForegroundColor Yellow
        Read-Host "按 Enter 键退出"
        exit 1
    }
}

# [5/7] 配置国内镜像源
Write-Step "[5/7] 配置国内镜像源（加速下载）..."
Setup-MavenMirror
Setup-NpmMirror

# [6/7] 安装前端依赖
Write-Step "[6/7] 安装前端依赖..."
$nodeModules = Join-Path $frontendPath "node_modules"
if (-not (Test-Path $nodeModules)) {
    Write-Host "  首次运行，正在安装依赖（使用国内镜像）..."
    Push-Location $frontendPath
    try {
        & npm install --registry=https://registry.npmmirror.com 2>&1 | ForEach-Object {
            if ($_ -match 'added|removed|changed|npm warn') { Write-Host "    $_" }
        }
        Write-OK "前端依赖安装完成"
    } catch {
        Write-Err "前端依赖安装失败: $($_.Exception.Message)"
        Write-Host "  请尝试手动运行: cd frontend && npm install" -ForegroundColor Yellow
        Pop-Location
        Read-Host "按 Enter 键退出"
        exit 1
    }
    Pop-Location
} else {
    Write-OK "前端依赖已存在，跳过安装"
}

# [7/7] 启动服务
Write-Step "[7/7] 启动服务..."

# 启动前先清理可能残留的旧进程（避免端口占用）
Write-Host "  清理残留进程..." -ForegroundColor Gray
Get-NetTCPConnection -LocalPort $backendPort -State Listen -ErrorAction SilentlyContinue | ForEach-Object {
    Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue
}
Get-NetTCPConnection -LocalPort $frontendPort -State Listen -ErrorAction SilentlyContinue | ForEach-Object {
    Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue
}
Start-Sleep -Seconds 1

# 启动后端（使用动态端口）
Write-Host "  启动后端服务 (端口 $backendPort)..." -ForegroundColor White
# 清理旧的 Tomcat 配置避免冲突
$tomcatConf = Join-Path $rootPath "target\tomcat"
if (Test-Path $tomcatConf) {
    Remove-Item $tomcatConf -Recurse -Force -ErrorAction SilentlyContinue
}
$backendCmd = "cd /d `"$rootPath`" && mvn tomcat7:run -s `"$m2Settings`" -Dmaven.tomcat.port=$backendPort"
Start-Process -FilePath "cmd.exe" -ArgumentList "/k", "title Guilin-News-Backend && $backendCmd"
Write-Host "  等待后端启动..." -ForegroundColor White
Start-Sleep -Seconds 12

# 启动前端（通过环境变量传递端口）
Write-Host "  启动前端服务 (端口 $frontendPort)..." -ForegroundColor White
$frontendCmd = "cd /d `"$frontendPath`" && set VITE_BACKEND_PORT=$backendPort && set VITE_FRONTEND_PORT=$frontendPort && npm run dev -- --port $frontendPort --strictPort"
Start-Process -FilePath "cmd.exe" -ArgumentList "/k", "title Guilin-News-Frontend && $frontendCmd"
Start-Sleep -Seconds 3

# 等待服务就绪并自动打开浏览器
Write-Host ""
Write-Host "  等待服务完全启动..." -ForegroundColor White
$maxWait = 90
$backendReady = $false
$frontendReady = $false
$proxyReady = $false

for ($i = 0; $i -lt $maxWait; $i++) {
    Start-Sleep -Seconds 1
    # 检测后端是否真正就绪（HTTP 请求而非仅端口检测）
    if (-not $backendReady) {
        try {
            $r = Invoke-WebRequest -Uri "http://localhost:$backendPort/guilin-news/api/news?type=xxxw" -UseBasicParsing -TimeoutSec 2
            if ($r.StatusCode -eq 200) {
                $backendReady = $true
                Write-OK "后端服务已就绪"
            }
        } catch {}
    }
    # 检测前端是否就绪
    if (-not $frontendReady -and (Test-Port $frontendPort)) {
        $frontendReady = $true
        Write-OK "前端服务已就绪"
    }
    # 检测前端代理是否真正可用（通过前端端口访问 API）
    if ($backendReady -and $frontendReady -and -not $proxyReady) {
        try {
            $r = Invoke-WebRequest -Uri "http://localhost:$frontendPort/api/news?type=xxxw" -UseBasicParsing -TimeoutSec 3
            if ($r.StatusCode -eq 200) {
                $proxyReady = $true
                Write-OK "前端代理已就绪"
            }
        } catch {}
    }
    if ($proxyReady) {
        break
    }
}

# 输出结果
Write-Host ""
Write-Host "==========================================" -ForegroundColor DarkGreen
if ($proxyReady) {
    Write-Host "  所有服务启动成功!" -ForegroundColor Green
} else {
    Write-Host "  服务启动中，请稍候..." -ForegroundColor Yellow
    if (-not $backendReady) { Write-Warn "后端可能还在启动中，请查看后端窗口" }
    if (-not $frontendReady) { Write-Warn "前端可能还在启动中，请查看前端窗口" }
    if ($backendReady -and $frontendReady -and -not $proxyReady) { Write-Warn "前端代理未就绪，请检查 vite.config.ts 配置" }
}
Write-Host "==========================================" -ForegroundColor DarkGreen
Write-Host ""
Write-Host "  前端地址: http://localhost:$frontendPort" -ForegroundColor Cyan
Write-Host "  后端地址: http://localhost:$backendPort/guilin-news" -ForegroundColor Cyan
Write-Host ""
Write-Host "  首次启动可能需要 30-60 秒，请耐心等待" -ForegroundColor Gray
Write-Host "  关闭对应的 cmd 窗口即可停止服务" -ForegroundColor Gray
Write-Host ""

# 自动打开浏览器（仅在代理就绪时）
if ($proxyReady) {
    Write-Host "  正在打开浏览器..." -ForegroundColor White
    Start-Process "http://localhost:$frontendPort"
}

Write-Host ""
Read-Host "按 Enter 键退出此窗口（服务将继续在后台运行）"
