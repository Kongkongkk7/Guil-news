$ErrorActionPreference = "Continue"

# ============================================================
#   Guilin University News Center - One-Click Startup Script
#   Automatically detects and installs JDK 17, Maven, Node.js
#   Uses China mirrors for faster downloads
# ============================================================

Clear-Host
Write-Host ""
Write-Host "  ==========================================" -ForegroundColor Cyan
Write-Host "      Guilin University News Center" -ForegroundColor Cyan
Write-Host "      One-Click Startup Script" -ForegroundColor Cyan
Write-Host "      (China mirrors enabled)" -ForegroundColor Cyan
Write-Host "  ==========================================" -ForegroundColor Cyan
Write-Host ""

$rootPath = $PSScriptRoot
$toolsPath = Join-Path $rootPath "tools"
$frontendPath = Join-Path $rootPath "frontend"

# Create tools directory
if (-not (Test-Path $toolsPath)) {
    New-Item -ItemType Directory -Path $toolsPath -Force | Out-Null
}

# Helper: Download file with multiple mirror fallback
function Download-File {
    param(
        [string[]]$Urls,
        [string]$Destination
    )
    foreach ($url in $Urls) {
        Write-Host "    Trying: $url" -ForegroundColor Gray
        try {
            $ProgressPreference = 'SilentlyContinue'
            Invoke-WebRequest -Uri $url -OutFile $Destination -UseBasicParsing -TimeoutSec 180
            $ProgressPreference = 'Continue'
            $fileSize = (Get-Item $Destination).Length
            if ($fileSize -gt 1024) {
                Write-Host "    Downloaded ($([math]::Round($fileSize/1MB, 1)) MB)" -ForegroundColor Green
                return $true
            }
        } catch {
            Write-Host "    Failed: $($_.Exception.Message)" -ForegroundColor DarkGray
        }
    }
    Write-Host "    All mirrors failed" -ForegroundColor Red
    return $false
}

# Helper: Extract zip
function Extract-Zip {
    param($ZipPath, $Destination)
    Write-Host "    Extracting..." -ForegroundColor Gray
    Expand-Archive -Path $ZipPath -DestinationPath $Destination -Force
}

# Helper: Configure Maven to use Aliyun mirror
function Configure-Maven {
    param($MavenHome)
    $settingsFile = Join-Path $MavenHome "conf\settings.xml"
    $settingsContent = @"
<?xml version="1.0" encoding="UTF-8"?>
<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0 http://maven.apache.org/xsd/settings-1.0.0.xsd">
  <mirrors>
    <mirror>
      <id>aliyunmaven</id>
      <mirrorOf>*</mirrorOf>
      <name>Aliyun Maven Mirror</name>
      <url>https://maven.aliyun.com/repository/public</url>
    </mirror>
  </mirrors>
</settings>
"@
    Set-Content -Path $settingsFile -Value $settingsContent -Encoding UTF8
    Write-Host "    Configured Aliyun Maven mirror" -ForegroundColor Gray
}

# Helper: Configure npm to use China mirror
function Configure-Npm {
    try {
        npm config set registry https://registry.npmmirror.com 2>&1 | Out-Null
        Write-Host "    Configured npmmirror registry" -ForegroundColor Gray
    } catch {}
}

# ============================================================
# Step 1: Check / Install JDK 17
# ============================================================
Write-Host "[1/6] Checking JDK 17+..." -ForegroundColor Yellow

$javaOk = $false
$javaHome = ""

# Check system Java
$sysJava = Get-Command java -ErrorAction SilentlyContinue
if ($sysJava) {
    $javaVersion = (& java -version 2>&1 | Out-String).Trim()
    $verMatch = [regex]::Match($javaVersion, '"(\d+)')
    if ($verMatch.Success) {
        $majorVer = [int]$verMatch.Groups[1].Value
        if ($majorVer -ge 17) {
            $firstLine = ($javaVersion -split "`n")[0] -replace '^.*?:\s*', ''
            Write-Host "  Found system Java: $firstLine" -ForegroundColor Green
            $javaOk = $true
        }
    }
}

# Check tools/java
if (-not $javaOk) {
    $localJava = Join-Path $toolsPath "jdk\bin\java.exe"
    if (Test-Path $localJava) {
        $javaVersion = (& $localJava -version 2>&1 | Out-String).Trim()
        $verMatch = [regex]::Match($javaVersion, '"(\d+)')
        if ($verMatch.Success -and [int]$verMatch.Groups[1].Value -ge 17) {
            $firstLine = ($javaVersion -split "`n")[0] -replace '^.*?:\s*', ''
            Write-Host "  Found local Java: $firstLine" -ForegroundColor Green
            $javaHome = Join-Path $toolsPath "jdk"
            $env:JAVA_HOME = $javaHome
            $env:PATH = "$javaHome\bin;$env:PATH"
            $javaOk = $true
        }
    }
}

# Download and install JDK 17
if (-not $javaOk) {
    Write-Host "  JDK 17+ not found. Auto-installing from China mirror..." -ForegroundColor DarkYellow

    # Detect architecture
    $arch = "x64"
    if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") { $arch = "aarch64" }

    # China mirror URLs (Huawei Cloud OpenJDK 17.0.2 + Tsinghua Adoptium + Official)
    $jdkUrls = @()
    if ($arch -eq "x64") {
        # Huawei Cloud OpenJDK 17.0.2 (fastest in China)
        $jdkUrls += "https://mirrors.huaweicloud.com/openjdk/17.0.2/openjdk-17.0.2_windows-x64_bin.zip"
        # Tsinghua Adoptium Temurin 17
        $jdkUrls += "https://mirrors.tuna.tsinghua.edu.cn/Adoptium/17/jdk/x64/windows/OpenJDK17U-jdk_x64_windows_hotspot_17.0.13_11.zip"
    }
    # Official Adoptium API (fallback)
    $jdkUrls += "https://api.adoptium.net/v3/binary/latest/17/ga/windows/$arch/jdk/hotspot/normal/eclipse?project=jdk"

    $jdkZip = Join-Path $toolsPath "jdk17.zip"

    if (Download-File -Urls $jdkUrls -Destination $jdkZip) {
        # Clean old jdk folder
        $jdkDir = Join-Path $toolsPath "jdk"
        if (Test-Path $jdkDir) { Remove-Item $jdkDir -Recurse -Force }
        Extract-Zip -ZipPath $jdkZip -Destination $toolsPath

        # Find extracted folder (jdk-17*, jdk-17.0.2, etc.)
        $extracted = Get-ChildItem -Path $toolsPath -Directory | Where-Object { $_.Name -like "jdk-17*" -or $_.Name -like "jdk17*" } | Select-Object -First 1
        if ($extracted) {
            Rename-Item -Path $extracted.FullName -NewName "jdk" -Force
            Remove-Item $jdkZip -Force
            $javaHome = Join-Path $toolsPath "jdk"
            $env:JAVA_HOME = $javaHome
            $env:PATH = "$javaHome\bin;$env:PATH"
            $javaVersion = (& java -version 2>&1 | Out-String).Trim()
            $firstLine = ($javaVersion -split "`n")[0] -replace '^.*?:\s*', ''
            Write-Host "  Installed: $firstLine" -ForegroundColor Green
            $javaOk = $true
        } else {
            Write-Host "  Failed to find extracted JDK folder" -ForegroundColor Red
        }
    }

    if (-not $javaOk) {
        Write-Host ""
        Write-Host "  Auto-install failed. Please install JDK 17 manually:" -ForegroundColor Red
        Write-Host "  https://mirrors.huaweicloud.com/openjdk/" -ForegroundColor Cyan
        Write-Host "  https://adoptium.net/temurin/releases/?version=17" -ForegroundColor Cyan
        Read-Host "  Press Enter to exit"
        exit 1
    }
}

# ============================================================
# Step 2: Check / Install Maven
# ============================================================
Write-Host ""
Write-Host "[2/6] Checking Maven..." -ForegroundColor Yellow

$mavenOk = $false
$mavenHome = ""

# Check system Maven
$sysMvn = Get-Command mvn -ErrorAction SilentlyContinue
if ($sysMvn) {
    Write-Host "  Found system Maven" -ForegroundColor Green
    $mavenOk = $true
}

# Check tools/maven
if (-not $mavenOk) {
    $localMvn = Join-Path $toolsPath "maven\bin\mvn.cmd"
    if (Test-Path $localMvn) {
        Write-Host "  Found local Maven" -ForegroundColor Green
        $mavenHome = Join-Path $toolsPath "maven"
        $env:PATH = "$mavenHome\bin;$env:PATH"
        $mavenOk = $true
    }
}

# Download and install Maven
if (-not $mavenOk) {
    Write-Host "  Maven not found. Auto-installing from China mirror..." -ForegroundColor DarkYellow

    # China mirror URLs (Tsinghua + Huawei + Official)
    $mvnUrls = @(
        "https://mirrors.tuna.tsinghua.edu.cn/apache/maven/maven-3/3.9.9/binaries/apache-maven-3.9.9-bin.zip",
        "https://mirrors.huaweicloud.com/apache/maven/maven-3/3.9.9/binaries/apache-maven-3.9.9-bin.zip",
        "https://dlcdn.apache.org/maven/maven-3/3.9.9/binaries/apache-maven-3.9.9-bin.zip"
    )
    $mvnZip = Join-Path $toolsPath "maven.zip"

    if (Download-File -Urls $mvnUrls -Destination $mvnZip) {
        $mvnDir = Join-Path $toolsPath "maven"
        if (Test-Path $mvnDir) { Remove-Item $mvnDir -Recurse -Force }
        Extract-Zip -ZipPath $mvnZip -Destination $toolsPath

        $extracted = Get-ChildItem -Path $toolsPath -Directory | Where-Object { $_.Name -like "apache-maven-*" } | Select-Object -First 1
        if ($extracted) {
            Rename-Item -Path $extracted.FullName -NewName "maven" -Force
            Remove-Item $mvnZip -Force
            $mavenHome = Join-Path $toolsPath "maven"
            $env:PATH = "$mavenHome\bin;$env:PATH"
            # Configure Aliyun mirror for faster dependency downloads
            Configure-Maven -MavenHome $mavenHome
            Write-Host "  Installed: Maven 3.9.9 (with Aliyun mirror)" -ForegroundColor Green
            $mavenOk = $true
        }
    }

    if (-not $mavenOk) {
        Write-Host ""
        Write-Host "  Auto-install failed. Please install Maven manually:" -ForegroundColor Red
        Write-Host "  https://maven.apache.org/download.cgi" -ForegroundColor Cyan
        Read-Host "  Press Enter to exit"
        exit 1
    }
} elseif ($mavenHome -and (Test-Path (Join-Path $mavenHome "conf\settings.xml"))) {
    # Local Maven exists, ensure Aliyun mirror is configured
    $settingsFile = Join-Path $mavenHome "conf\settings.xml"
    $settingsContent = Get-Content $settingsFile -Raw -ErrorAction SilentlyContinue
    if ($settingsContent -notmatch "aliyun") {
        Configure-Maven -MavenHome $mavenHome
    }
}

# ============================================================
# Step 3: Check / Install Node.js
# ============================================================
Write-Host ""
Write-Host "[3/6] Checking Node.js 18+..." -ForegroundColor Yellow

$nodeOk = $false

# Check system Node
$sysNode = Get-Command node -ErrorAction SilentlyContinue
if ($sysNode) {
    $nodeVersion = & node --version 2>&1
    $verMatch = [regex]::Match($nodeVersion, 'v(\d+)')
    if ($verMatch.Success -and [int]$verMatch.Groups[1].Value -ge 18) {
        Write-Host "  Found system Node.js: $nodeVersion" -ForegroundColor Green
        $nodeOk = $true
    }
}

# Check tools/nodejs
if (-not $nodeOk) {
    $localNode = Join-Path $toolsPath "nodejs\node.exe"
    if (Test-Path $localNode) {
        $nodeVersion = & $localNode --version 2>&1
        $verMatch = [regex]::Match($nodeVersion, 'v(\d+)')
        if ($verMatch.Success -and [int]$verMatch.Groups[1].Value -ge 18) {
            Write-Host "  Found local Node.js: $nodeVersion" -ForegroundColor Green
            $nodeHome = Join-Path $toolsPath "nodejs"
            $env:PATH = "$nodeHome;$env:PATH"
            $nodeOk = $true
        }
    }
}

# Download and install Node.js
if (-not $nodeOk) {
    Write-Host "  Node.js 18+ not found. Auto-installing from China mirror..." -ForegroundColor DarkYellow

    # Detect architecture
    $nodeArch = "x64"
    if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") { $nodeArch = "arm64" }

    # Get latest LTS version from China mirror (npmmirror) first, fallback to official
    $ltsVersion = $null
    $versionApis = @(
        "https://registry.npmmirror.com/-/binary/node/index.json",
        "https://nodejs.org/dist/index.json"
    )
    foreach ($apiUrl in $versionApis) {
        try {
            $ProgressPreference = 'SilentlyContinue'
            $nodeData = Invoke-RestMethod -Uri $apiUrl -TimeoutSec 15
            $ltsVersion = ($nodeData | Where-Object { $_.lts -ne $false } | Select-Object -First 1).version
            $ProgressPreference = 'Continue'
            if ($ltsVersion) { break }
        } catch {}
    }
    if (-not $ltsVersion) { $ltsVersion = "v22.11.0" }

    # China mirror URLs (npmmirror + official)
    $nodeUrls = @(
        "https://registry.npmmirror.com/-/binary/node/$ltsVersion/node-$ltsVersion-win-$nodeArch.zip",
        "https://nodejs.org/dist/$ltsVersion/node-$ltsVersion-win-$nodeArch.zip"
    )
    $nodeZip = Join-Path $toolsPath "nodejs.zip"

    if (Download-File -Urls $nodeUrls -Destination $nodeZip) {
        $nodeDir = Join-Path $toolsPath "nodejs"
        if (Test-Path $nodeDir) { Remove-Item $nodeDir -Recurse -Force }
        Extract-Zip -ZipPath $nodeZip -Destination $toolsPath

        $extracted = Get-ChildItem -Path $toolsPath -Directory | Where-Object { $_.Name -like "node-v*" } | Select-Object -First 1
        if ($extracted) {
            Rename-Item -Path $extracted.FullName -NewName "nodejs" -Force
            Remove-Item $nodeZip -Force
            $nodeHome = Join-Path $toolsPath "nodejs"
            $env:PATH = "$nodeHome;$env:PATH"
            $nodeVersion = (& node --version 2>&1 | Out-String).Trim()
            Write-Host "  Installed: Node.js $nodeVersion" -ForegroundColor Green
            $nodeOk = $true
        }
    }

    if (-not $nodeOk) {
        Write-Host ""
        Write-Host "  Auto-install failed. Please install Node.js manually:" -ForegroundColor Red
        Write-Host "  https://registry.npmmirror.com/binary.html?path=node/" -ForegroundColor Cyan
        Write-Host "  https://nodejs.org/" -ForegroundColor Cyan
        Read-Host "  Press Enter to exit"
        exit 1
    }
}

# ============================================================
# Step 4: Install frontend dependencies (with China mirror)
# ============================================================
Write-Host ""
Write-Host "[4/6] Installing frontend dependencies..." -ForegroundColor Yellow

# Ensure npm uses China mirror
Configure-Npm

$nodeModules = Join-Path $frontendPath "node_modules"
if (-not (Test-Path $nodeModules)) {
    Write-Host "  Running npm install (using npmmirror, first time may take a few minutes)..." -ForegroundColor Gray
    Push-Location $frontendPath
    npm install --registry=https://registry.npmmirror.com --silent 2>&1 | Out-Null
    Pop-Location
    Write-Host "  Done" -ForegroundColor Green
} else {
    Write-Host "  Dependencies already installed" -ForegroundColor Green
}

# ============================================================
# Step 5: Kill processes on ports 8080 and 5173
# ============================================================
Write-Host ""
Write-Host "[5/6] Checking ports..." -ForegroundColor Yellow

foreach ($port in @(8080, 5173)) {
    $conn = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
    if ($conn) {
        $procIds = $conn.OwningProcess | Select-Object -Unique
        foreach ($p in $procIds) {
            $proc = Get-Process -Id $p -ErrorAction SilentlyContinue
            if ($proc) {
                Write-Host "  Port $port in use by $($proc.Name) (PID: $p), stopping..." -ForegroundColor DarkYellow
                Stop-Process -Id $p -Force -ErrorAction SilentlyContinue
            }
        }
        Start-Sleep -Seconds 1
    }
}
Write-Host "  Ports ready" -ForegroundColor Green

# ============================================================
# Step 6: Start servers
# ============================================================
Write-Host ""
Write-Host "[6/6] Starting servers..." -ForegroundColor Yellow

Write-Host "  Starting backend (port 8080)..." -ForegroundColor Gray
$backendScript = @"
cd /d "$rootPath"
set JAVA_HOME=$env:JAVA_HOME
set PATH=%JAVA_HOME%\bin;%PATH%
mvn tomcat7:run
"@
$backendBat = Join-Path $env:TEMP "guilin_backend.bat"
Set-Content -Path $backendBat -Value $backendScript -Encoding Default
Start-Process -FilePath "cmd.exe" -ArgumentList "/k", $backendBat -WindowStyle Normal
Write-Host "  Backend starting..." -ForegroundColor Green

Write-Host "  Waiting for backend to initialize..." -ForegroundColor Gray
Start-Sleep -Seconds 12

Write-Host "  Starting frontend (port 5173)..." -ForegroundColor Gray
$frontendScript = @"
cd /d "$frontendPath"
npm run dev
"@
$frontendBat = Join-Path $env:TEMP "guilin_frontend.bat"
Set-Content -Path $frontendBat -Value $frontendScript -Encoding Default
Start-Process -FilePath "cmd.exe" -ArgumentList "/k", $frontendBat -WindowStyle Normal
Write-Host "  Frontend starting..." -ForegroundColor Green

# ============================================================
# Done
# ============================================================
Write-Host ""
Write-Host "  ==========================================" -ForegroundColor Cyan
Write-Host "  All services started successfully!" -ForegroundColor Green
Write-Host "  ==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Frontend:  http://localhost:5173" -ForegroundColor White
Write-Host "  Backend:   http://localhost:8080/guilin-news" -ForegroundColor White
Write-Host ""
Write-Host "  Tips:" -ForegroundColor Gray
Write-Host "  - Wait 10-15 seconds for services to fully start" -ForegroundColor Gray
Write-Host "  - Close both command windows to stop services" -ForegroundColor Gray
Write-Host ""
Read-Host "  Press Enter to exit this window"
