# Guilin University News Center - One-Click Startup Script
# Automatically detects and installs JDK 17, Maven, Node.js
# Uses China mirrors for faster downloads
# Robust error handling for any Windows environment
$ErrorActionPreference = "Continue"
$ProgressPreference = "SilentlyContinue"

# Force UTF-8 output for Chinese characters
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
} catch {}

# ============================================================
# Determine script root path (handle all invocation methods)
# ============================================================
$rootPath = $null
if ($PSCommandPath) {
    $rootPath = Split-Path $PSCommandPath -Parent
} elseif ($MyInvocation.MyCommand.Path) {
    $rootPath = Split-Path $MyInvocation.MyCommand.Path -Parent
} elseif ($PSScriptRoot) {
    $rootPath = $PSScriptRoot
} else {
    # Fallback: use current directory
    $rootPath = (Get-Location).Path
}

if (-not $rootPath -or -not (Test-Path $rootPath)) {
    Write-Host "ERROR: Cannot determine script directory" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

$toolsPath = Join-Path $rootPath "tools"
$frontendPath = Join-Path $rootPath "frontend"

# Verify project structure
if (-not (Test-Path (Join-Path $rootPath "pom.xml"))) {
    Write-Host "ERROR: pom.xml not found in $rootPath" -ForegroundColor Red
    Write-Host "Please run this script from the project root directory" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Create tools directory
if (-not (Test-Path $toolsPath)) {
    New-Item -ItemType Directory -Path $toolsPath -Force | Out-Null
}

# ============================================================
# Header
# ============================================================
Clear-Host
Write-Host ""
Write-Host "  ==========================================" -ForegroundColor Cyan
Write-Host "      Guilin University News Center" -ForegroundColor Cyan
Write-Host "      One-Click Startup Script" -ForegroundColor Cyan
Write-Host "      (China mirrors enabled)" -ForegroundColor Cyan
Write-Host "  ==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Project: $rootPath" -ForegroundColor DarkGray
Write-Host ""

# ============================================================
# Helper functions
# ============================================================

function Write-Step {
    param([string]$Message)
    Write-Host "[*] $Message" -ForegroundColor Yellow
}

function Write-Ok {
    param([string]$Message)
    Write-Host "    [OK] $Message" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Message)
    Write-Host "    [!] $Message" -ForegroundColor DarkYellow
}

function Write-Err {
    param([string]$Message)
    Write-Host "    [X] $Message" -ForegroundColor Red
}

function Write-Info {
    param([string]$Message)
    Write-Host "    $Message" -ForegroundColor Gray
}

function Download-File {
    param(
        [string[]]$Urls,
        [string]$Destination
    )
    foreach ($url in $Urls) {
        Write-Info "Downloading: $url"
        try {
            $oldProgress = $ProgressPreference
            $ProgressPreference = 'SilentlyContinue'
            Invoke-WebRequest -Uri $url -OutFile $Destination -UseBasicParsing -TimeoutSec 300
            $ProgressPreference = $oldProgress
            $fileSize = (Get-Item $Destination -ErrorAction SilentlyContinue).Length
            if ($fileSize -gt 1024) {
                $sizeMB = [math]::Round($fileSize/1MB, 1)
                Write-Ok "Downloaded ($sizeMB MB)"
                return $true
            } else {
                Write-Warn "File too small ($fileSize bytes), trying next mirror"
                Remove-Item $Destination -Force -ErrorAction SilentlyContinue
            }
        } catch {
            Write-Warn "Failed: $($_.Exception.Message)"
        }
    }
    Write-Err "All download mirrors failed"
    return $false
}

function Extract-Zip {
    param([string]$ZipPath, [string]$Destination)
    Write-Info "Extracting..."
    try {
        Expand-Archive -Path $ZipPath -DestinationPath $Destination -Force -ErrorAction Stop
        return $true
    } catch {
        Write-Err "Extraction failed: $($_.Exception.Message)"
        return $false
    }
}

function Configure-Maven {
    param([string]$MavenHome)
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
    # Try global settings.xml first
    $settingsFile = Join-Path $MavenHome "conf\settings.xml"
    try {
        Set-Content -Path $settingsFile -Value $settingsContent -Encoding UTF8 -ErrorAction Stop
        Write-Info "Configured Aliyun Maven mirror (global)"
        return
    } catch {
        # Fallback: user-level settings.xml (~/.m2/settings.xml)
        $m2Dir = Join-Path $env:USERPROFILE ".m2"
        if (-not (Test-Path $m2Dir)) {
            New-Item -ItemType Directory -Path $m2Dir -Force | Out-Null
        }
        $userSettings = Join-Path $m2Dir "settings.xml"
        try {
            Set-Content -Path $userSettings -Value $settingsContent -Encoding UTF8 -ErrorAction Stop
            Write-Info "Configured Aliyun Maven mirror (user: $userSettings)"
        } catch {
            Write-Warn "Cannot write Maven settings, using default repository"
        }
    }
}

function Configure-Npm {
    try {
        $npmCmd = Get-Command npm -ErrorAction SilentlyContinue
        if ($npmCmd) {
            & npm config set registry https://registry.npmmirror.com 2>&1 | Out-Null
            Write-Info "Configured npmmirror registry"
        }
    } catch {}
}

# ============================================================
# Step 1: Check / Install JDK 17
# ============================================================
Write-Step "Step 1/6: Checking JDK 17+..."

$javaOk = $false
$javaHome = ""
$javaExePath = ""

# Method 1: Get-Command java
$sysJava = Get-Command java -ErrorAction SilentlyContinue
if ($sysJava) {
    try {
        $javaVersion = (& java -version 2>&1 | Out-String).Trim()
        $verMatch = [regex]::Match($javaVersion, '"(\d+)')
        if ($verMatch.Success -and [int]$verMatch.Groups[1].Value -ge 17) {
            $firstLine = ($javaVersion -split "`n")[0] -replace '^.*?:\s*', ''
            Write-Ok "Found system Java: $firstLine"
            $javaExePath = $sysJava.Source
            # Determine JAVA_HOME
            if ($env:JAVA_HOME -and (Test-Path $env:JAVA_HOME)) {
                $javaHome = $env:JAVA_HOME
            } else {
                $binPath = Split-Path $javaExePath -Parent
                $candidateHome = Split-Path $binPath -Parent
                if (Test-Path (Join-Path $candidateHome "bin\java.exe")) {
                    $javaHome = $candidateHome
                    $env:JAVA_HOME = $javaHome
                }
            }
            $javaOk = $true
        } else {
            Write-Warn "System Java version too old, need 17+"
        }
    } catch {
        Write-Warn "System java command failed"
    }
}

# Method 2: JAVA_HOME environment variable
if (-not $javaOk -and $env:JAVA_HOME) {
    $candidateJava = Join-Path $env:JAVA_HOME "bin\java.exe"
    if (Test-Path $candidateJava) {
        try {
            $javaVersion = (& $candidateJava -version 2>&1 | Out-String).Trim()
            $verMatch = [regex]::Match($javaVersion, '"(\d+)')
            if ($verMatch.Success -and [int]$verMatch.Groups[1].Value -ge 17) {
                $firstLine = ($javaVersion -split "`n")[0] -replace '^.*?:\s*', ''
                Write-Ok "Found Java (JAVA_HOME): $firstLine"
                $javaHome = $env:JAVA_HOME
                $javaExePath = $candidateJava
                $env:PATH = "$javaHome\bin;$env:PATH"
                $javaOk = $true
            }
        } catch {}
    }
}

# Method 3: Common installation paths
if (-not $javaOk) {
    $commonJavaPaths = @(
        "C:\Program Files\Java\jdk-17*\bin\java.exe",
        "C:\Program Files\Java\jdk-2*\bin\java.exe",
        "C:\Program Files\Eclipse Adoptium\jdk-17*\bin\java.exe",
        "C:\Program Files\Microsoft\jdk-17*\bin\java.exe",
        "C:\Program Files\Zulu\zulu-17*\bin\java.exe",
        "C:\Program Files\Amazon Corretto\jdk17*\bin\java.exe",
        "D:\Java\jdk-17*\bin\java.exe",
        "D:\jdk-17*\bin\java.exe"
    )
    foreach ($p in $commonJavaPaths) {
        $resolved = Get-Item $p -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($resolved) {
            try {
                $javaVersion = (& $resolved.FullName -version 2>&1 | Out-String).Trim()
                $verMatch = [regex]::Match($javaVersion, '"(\d+)')
                if ($verMatch.Success -and [int]$verMatch.Groups[1].Value -ge 17) {
                    $firstLine = ($javaVersion -split "`n")[0] -replace '^.*?:\s*', ''
                    Write-Ok "Found Java: $firstLine"
                    $javaExePath = $resolved.FullName
                    $binPath = Split-Path $javaExePath -Parent
                    $javaHome = Split-Path $binPath -Parent
                    $env:JAVA_HOME = $javaHome
                    $env:PATH = "$javaHome\bin;$env:PATH"
                    $javaOk = $true
                    break
                }
            } catch {}
        }
    }
}

# Method 4: Check tools/jdk
if (-not $javaOk) {
    $localJava = Join-Path $toolsPath "jdk\bin\java.exe"
    if (Test-Path $localJava) {
        try {
            $javaVersion = (& $localJava -version 2>&1 | Out-String).Trim()
            $verMatch = [regex]::Match($javaVersion, '"(\d+)')
            if ($verMatch.Success -and [int]$verMatch.Groups[1].Value -ge 17) {
                $firstLine = ($javaVersion -split "`n")[0] -replace '^.*?:\s*', ''
                Write-Ok "Found local Java: $firstLine"
                $javaHome = Join-Path $toolsPath "jdk"
                $javaExePath = $localJava
                $env:JAVA_HOME = $javaHome
                $env:PATH = "$javaHome\bin;$env:PATH"
                $javaOk = $true
            }
        } catch {}
    }
}

# Method 5: Auto-download JDK 17
if (-not $javaOk) {
    Write-Warn "JDK 17+ not found. Auto-installing from China mirror..."

    $arch = "x64"
    if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") { $arch = "aarch64" }

    $jdkUrls = @()
    if ($arch -eq "x64") {
        $jdkUrls += "https://mirrors.huaweicloud.com/openjdk/17.0.2/openjdk-17.0.2_windows-x64_bin.zip"
        $jdkUrls += "https://mirrors.tuna.tsinghua.edu.cn/Adoptium/17/jdk/x64/windows/OpenJDK17U-jdk_x64_windows_hotspot_17.0.13_11.zip"
    }
    $jdkUrls += "https://api.adoptium.net/v3/binary/latest/17/ga/windows/$arch/jdk/hotspot/normal/eclipse?project=jdk"

    $jdkZip = Join-Path $toolsPath "jdk17.zip"

    if (Download-File -Urls $jdkUrls -Destination $jdkZip) {
        $jdkDir = Join-Path $toolsPath "jdk"
        if (Test-Path $jdkDir) { Remove-Item $jdkDir -Recurse -Force }
        if (Extract-Zip -ZipPath $jdkZip -Destination $toolsPath) {
            $extracted = Get-ChildItem -Path $toolsPath -Directory | Where-Object { $_.Name -like "jdk-17*" -or $_.Name -like "jdk17*" } | Select-Object -First 1
            if ($extracted) {
                Rename-Item -Path $extracted.FullName -NewName "jdk" -Force
                Remove-Item $jdkZip -Force -ErrorAction SilentlyContinue
                $javaHome = Join-Path $toolsPath "jdk"
                $javaExePath = Join-Path $javaHome "bin\java.exe"
                $env:JAVA_HOME = $javaHome
                $env:PATH = "$javaHome\bin;$env:PATH"
                try {
                    $javaVersion = (& $javaExePath -version 2>&1 | Out-String).Trim()
                    $firstLine = ($javaVersion -split "`n")[0] -replace '^.*?:\s*', ''
                    Write-Ok "Installed: $firstLine"
                    $javaOk = $true
                } catch {
                    Write-Err "JDK installed but java.exe failed"
                }
            } else {
                Write-Err "Cannot find extracted JDK folder"
            }
        }
    }

    if (-not $javaOk) {
        Write-Err "Auto-install failed. Please install JDK 17 manually:"
        Write-Host "    https://mirrors.huaweicloud.com/openjdk/" -ForegroundColor Cyan
        Write-Host "    https://adoptium.net/temurin/releases/?version=17" -ForegroundColor Cyan
        Read-Host "Press Enter to exit"
        exit 1
    }
}

# ============================================================
# Step 2: Check / Install Maven
# ============================================================
Write-Host ""
Write-Step "Step 2/6: Checking Maven..."

$mavenOk = $false
$mavenHome = ""
$mavenBinPath = ""
$mvnExePath = ""

# Method 1: Get-Command (try mvn, mvn.cmd, mvn.bat)
$sysMvn = Get-Command mvn -ErrorAction SilentlyContinue
if (-not $sysMvn) { $sysMvn = Get-Command mvn.cmd -ErrorAction SilentlyContinue }
if (-not $sysMvn) { $sysMvn = Get-Command mvn.bat -ErrorAction SilentlyContinue }

# Method 2: where.exe
if (-not $sysMvn) {
    try {
        $whereResult = (where.exe mvn 2>$null | Where-Object { $_ })
        if ($whereResult) {
            $firstMatch = $whereResult | Select-Object -First 1
            $sysMvn = [PSCustomObject]@{ Source = $firstMatch }
        }
    } catch {}
}

# Method 3: MAVEN_HOME / M2_HOME
if (-not $sysMvn) {
    $mavenHomeEnv = $env:MAVEN_HOME
    if (-not $mavenHomeEnv) { $mavenHomeEnv = $env:M2_HOME }
    if ($mavenHomeEnv) {
        foreach ($exeName in @("mvn.cmd", "mvn.bat", "mvn")) {
            $candidateMvn = Join-Path $mavenHomeEnv "bin\$exeName"
            if (Test-Path $candidateMvn) {
                $sysMvn = [PSCustomObject]@{ Source = $candidateMvn }
                break
            }
        }
    }
}

# Method 4: Common installation paths
if (-not $sysMvn) {
    $commonMvnPaths = @(
        "C:\Program Files\Apache\maven\bin\mvn.cmd",
        "C:\Program Files\apache-maven*\bin\mvn.cmd",
        "C:\apache-maven*\bin\mvn.cmd",
        "C:\maven\bin\mvn.cmd",
        "D:\maven\bin\mvn.cmd",
        "D:\apache-maven*\bin\mvn.cmd",
        "$env:USERPROFILE\apache-maven*\bin\mvn.cmd",
        "$env:LOCALAPPDATA\Programs\apache-maven*\bin\mvn.cmd"
    )
    foreach ($p in $commonMvnPaths) {
        $resolved = Get-Item $p -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($resolved) {
            $sysMvn = [PSCustomObject]@{ Source = $resolved.FullName }
            break
        }
    }
}

if ($sysMvn) {
    $mvnExePath = $sysMvn.Source
    $mavenBinPath = Split-Path $mvnExePath -Parent
    $mavenHome = Split-Path $mavenBinPath -Parent

    # Verify by checking version
    try {
        $mvnVersion = (& $mvnExePath --version 2>&1 | Out-String).Trim()
        $firstLine = ($mvnVersion -split "`n")[0]
        Write-Ok "Found Maven: $firstLine"
        Write-Info "Path: $mvnExePath"
    } catch {
        Write-Ok "Found Maven at: $mvnExePath"
    }

    if ($env:PATH -notlike "*$mavenBinPath*") {
        $env:PATH = "$mavenBinPath;$env:PATH"
    }
    if (-not $env:MAVEN_HOME) {
        $env:MAVEN_HOME = $mavenHome
    }
    $mavenOk = $true
}

# Method 5: Check tools/maven
if (-not $mavenOk) {
    foreach ($exeName in @("mvn.cmd", "mvn.bat", "mvn")) {
        $localMvn = Join-Path $toolsPath "maven\bin\$exeName"
        if (Test-Path $localMvn) {
            Write-Ok "Found local Maven"
            $mavenHome = Join-Path $toolsPath "maven"
            $mavenBinPath = Join-Path $mavenHome "bin"
            $mvnExePath = $localMvn
            $env:PATH = "$mavenBinPath;$env:PATH"
            $env:MAVEN_HOME = $mavenHome
            $mavenOk = $true
            break
        }
    }
}

# Method 6: Auto-download Maven
if (-not $mavenOk) {
    Write-Warn "Maven not found. Auto-installing from China mirror..."

    $mvnUrls = @(
        "https://mirrors.tuna.tsinghua.edu.cn/apache/maven/maven-3/3.9.9/binaries/apache-maven-3.9.9-bin.zip",
        "https://mirrors.huaweicloud.com/apache/maven/maven-3/3.9.9/binaries/apache-maven-3.9.9-bin.zip",
        "https://dlcdn.apache.org/maven/maven-3/3.9.9/binaries/apache-maven-3.9.9-bin.zip"
    )
    $mvnZip = Join-Path $toolsPath "maven.zip"

    if (Download-File -Urls $mvnUrls -Destination $mvnZip) {
        $mvnDir = Join-Path $toolsPath "maven"
        if (Test-Path $mvnDir) { Remove-Item $mvnDir -Recurse -Force }
        if (Extract-Zip -ZipPath $mvnZip -Destination $toolsPath) {
            $extracted = Get-ChildItem -Path $toolsPath -Directory | Where-Object { $_.Name -like "apache-maven-*" } | Select-Object -First 1
            if ($extracted) {
                Rename-Item -Path $extracted.FullName -NewName "maven" -Force
                Remove-Item $mvnZip -Force -ErrorAction SilentlyContinue
                $mavenHome = Join-Path $toolsPath "maven"
                $mavenBinPath = Join-Path $mavenHome "bin"
                $mvnExePath = Join-Path $mavenBinPath "mvn.cmd"
                $env:PATH = "$mavenBinPath;$env:PATH"
                $env:MAVEN_HOME = $mavenHome
                Configure-Maven -MavenHome $mavenHome
                Write-Ok "Installed: Maven 3.9.9 (with Aliyun mirror)"
                $mavenOk = $true
            }
        }
    }

    if (-not $mavenOk) {
        Write-Err "Auto-install failed. Please install Maven manually:"
        Write-Host "    https://maven.apache.org/download.cgi" -ForegroundColor Cyan
        Read-Host "Press Enter to exit"
        exit 1
    }
} elseif ($mavenHome -and (Test-Path (Join-Path $mavenHome "conf\settings.xml"))) {
    # Ensure Aliyun mirror is configured for existing Maven
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
Write-Step "Step 3/6: Checking Node.js 18+..."

$nodeOk = $false
$nodeExePath = ""

# Method 1: Get-Command node
$sysNode = Get-Command node -ErrorAction SilentlyContinue
if ($sysNode) {
    try {
        $nodeVersion = (& node --version 2>&1 | Out-String).Trim()
        $verMatch = [regex]::Match($nodeVersion, 'v(\d+)')
        if ($verMatch.Success -and [int]$verMatch.Groups[1].Value -ge 18) {
            Write-Ok "Found system Node.js: $nodeVersion"
            $nodeExePath = $sysNode.Source
            $nodeOk = $true
        } else {
            Write-Warn "System Node.js version too old, need 18+"
        }
    } catch {
        Write-Warn "System node command failed"
    }
}

# Method 2: where.exe
if (-not $nodeOk) {
    try {
        $whereResult = (where.exe node 2>$null | Where-Object { $_ })
        if ($whereResult) {
            $firstMatch = $whereResult | Select-Object -First 1
            try {
                $nodeVersion = (& $firstMatch --version 2>&1 | Out-String).Trim()
                $verMatch = [regex]::Match($nodeVersion, 'v(\d+)')
                if ($verMatch.Success -and [int]$verMatch.Groups[1].Value -ge 18) {
                    Write-Ok "Found Node.js: $nodeVersion"
                    $nodeExePath = $firstMatch
                    $nodeDir = Split-Path $nodeExePath -Parent
                    $env:PATH = "$nodeDir;$env:PATH"
                    $nodeOk = $true
                }
            } catch {}
        }
    } catch {}
}

# Method 3: Common installation paths
if (-not $nodeOk) {
    $commonNodePaths = @(
        "C:\Program Files\nodejs\node.exe",
        "C:\Program Files (x86)\nodejs\node.exe",
        "$env:LOCALAPPDATA\Programs\nodejs\node.exe",
        "$env:APPDATA\npm\node.exe",
        "D:\nodejs\node.exe"
    )
    foreach ($p in $commonNodePaths) {
        if (Test-Path $p) {
            try {
                $nodeVersion = (& $p --version 2>&1 | Out-String).Trim()
                $verMatch = [regex]::Match($nodeVersion, 'v(\d+)')
                if ($verMatch.Success -and [int]$verMatch.Groups[1].Value -ge 18) {
                    Write-Ok "Found Node.js: $nodeVersion"
                    $nodeExePath = $p
                    $nodeDir = Split-Path $nodeExePath -Parent
                    $env:PATH = "$nodeDir;$env:PATH"
                    $nodeOk = $true
                    break
                }
            } catch {}
        }
    }
}

# Method 4: Check tools/nodejs
if (-not $nodeOk) {
    $localNode = Join-Path $toolsPath "nodejs\node.exe"
    if (Test-Path $localNode) {
        try {
            $nodeVersion = (& $localNode --version 2>&1 | Out-String).Trim()
            $verMatch = [regex]::Match($nodeVersion, 'v(\d+)')
            if ($verMatch.Success -and [int]$verMatch.Groups[1].Value -ge 18) {
                Write-Ok "Found local Node.js: $nodeVersion"
                $nodeExePath = $localNode
                $nodeHome = Join-Path $toolsPath "nodejs"
                $env:PATH = "$nodeHome;$env:PATH"
                $nodeOk = $true
            }
        } catch {}
    }
}

# Method 5: Auto-download Node.js
if (-not $nodeOk) {
    Write-Warn "Node.js 18+ not found. Auto-installing from China mirror..."

    $nodeArch = "x64"
    if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") { $nodeArch = "arm64" }

    # Get latest LTS version
    $ltsVersion = $null
    $versionApis = @(
        "https://registry.npmmirror.com/-/binary/node/index.json",
        "https://nodejs.org/dist/index.json"
    )
    foreach ($apiUrl in $versionApis) {
        try {
            $nodeData = Invoke-RestMethod -Uri $apiUrl -TimeoutSec 15
            $ltsVersion = ($nodeData | Where-Object { $_.lts -ne $false } | Select-Object -First 1).version
            if ($ltsVersion) { break }
        } catch {}
    }
    if (-not $ltsVersion) { $ltsVersion = "v22.11.0" }

    $nodeUrls = @(
        "https://registry.npmmirror.com/-/binary/node/$ltsVersion/node-$ltsVersion-win-$nodeArch.zip",
        "https://nodejs.org/dist/$ltsVersion/node-$ltsVersion-win-$nodeArch.zip"
    )
    $nodeZip = Join-Path $toolsPath "nodejs.zip"

    if (Download-File -Urls $nodeUrls -Destination $nodeZip) {
        $nodeDir = Join-Path $toolsPath "nodejs"
        if (Test-Path $nodeDir) { Remove-Item $nodeDir -Recurse -Force }
        if (Extract-Zip -ZipPath $nodeZip -Destination $toolsPath) {
            $extracted = Get-ChildItem -Path $toolsPath -Directory | Where-Object { $_.Name -like "node-v*" } | Select-Object -First 1
            if ($extracted) {
                Rename-Item -Path $extracted.FullName -NewName "nodejs" -Force
                Remove-Item $nodeZip -Force -ErrorAction SilentlyContinue
                $nodeHome = Join-Path $toolsPath "nodejs"
                $nodeExePath = Join-Path $nodeHome "node.exe"
                $env:PATH = "$nodeHome;$env:PATH"
                try {
                    $nodeVersion = (& $nodeExePath --version 2>&1 | Out-String).Trim()
                    Write-Ok "Installed: Node.js $nodeVersion"
                    $nodeOk = $true
                } catch {
                    Write-Err "Node.js installed but node.exe failed"
                }
            }
        }
    }

    if (-not $nodeOk) {
        Write-Err "Auto-install failed. Please install Node.js manually:"
        Write-Host "    https://registry.npmmirror.com/binary.html?path=node/" -ForegroundColor Cyan
        Write-Host "    https://nodejs.org/" -ForegroundColor Cyan
        Read-Host "Press Enter to exit"
        exit 1
    }
}

# ============================================================
# Step 4: Install frontend dependencies
# ============================================================
Write-Host ""
Write-Step "Step 4/6: Installing frontend dependencies..."

Configure-Npm

$nodeModules = Join-Path $frontendPath "node_modules"
if (-not (Test-Path $nodeModules)) {
    Write-Info "Running npm install (first time may take a few minutes)..."
    Push-Location $frontendPath
    try {
        $npmResult = & npm install --registry=https://registry.npmmirror.com 2>&1
        $npmExitCode = $LASTEXITCODE
        Pop-Location
        if ($npmExitCode -eq 0) {
            Write-Ok "Frontend dependencies installed"
        } else {
            Write-Warn "npm install had warnings (exit code: $npmExitCode)"
            Write-Info "Last output: $($npmResult | Select-Object -Last 3)"
        }
    } catch {
        Pop-Location
        Write-Err "npm install failed: $($_.Exception.Message)"
        Read-Host "Press Enter to exit"
        exit 1
    }
} else {
    Write-Ok "Dependencies already installed"
}

# ============================================================
# Step 5: Kill processes on ports 8080 and 5173
# ============================================================
Write-Host ""
Write-Step "Step 5/6: Checking ports..."

foreach ($port in @(8080, 5173)) {
    try {
        $conn = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
        if ($conn) {
            $procIds = $conn.OwningProcess | Where-Object { $_ -ne 0 -and $_ -ne 4 } | Select-Object -Unique
            foreach ($p in $procIds) {
                $proc = Get-Process -Id $p -ErrorAction SilentlyContinue
                if ($proc) {
                    Write-Warn "Port $port in use by $($proc.Name) (PID: $p), stopping..."
                    Stop-Process -Id $p -Force -ErrorAction SilentlyContinue
                }
            }
            Start-Sleep -Seconds 2
        }
    } catch {
        # Get-NetTCPConnection may fail on some systems, use netstat as fallback
        try {
            $netstatResult = (netstat -ano | Select-String ":$port\s.*LISTENING")
            if ($netstatResult) {
                foreach ($line in $netstatResult) {
                    $parts = $line -split '\s+'
                    $pidStr = $parts[-1]
                    if ($pidStr -match '^\d+$' -and [int]$pidStr -ne 0 -and [int]$pidStr -ne 4) {
                        $proc = Get-Process -Id $pidStr -ErrorAction SilentlyContinue
                        if ($proc) {
                            Write-Warn "Port $port in use by $($proc.Name) (PID: $pidStr), stopping..."
                            Stop-Process -Id $pidStr -Force -ErrorAction SilentlyContinue
                        }
                    }
                }
                Start-Sleep -Seconds 2
            }
        } catch {}
    }
}
Write-Ok "Ports ready"

# ============================================================
# Step 6: Start servers
# ============================================================
Write-Host ""
Write-Step "Step 6/6: Starting servers..."

# --- Build backend batch script with explicit paths ---
Write-Info "Starting backend (port 8080)..."
$backendBatContent = "@echo off`r`n"
$backendBatContent += "chcp 65001 >nul 2>&1`r`n"
$backendBatContent += "title Guilin News - Backend (Maven Tomcat)`r`n"
$backendBatContent += "cd /d `"$rootPath`"`r`n"
if ($javaHome) {
    $backendBatContent += "set `"`JAVA_HOME=$javaHome`"`r`n"
    $backendBatContent += "set `"`PATH=%JAVA_HOME%\bin;%PATH%`"`r`n"
}
if ($mavenBinPath) {
    $backendBatContent += "set `"`PATH=$mavenBinPath;%PATH%`"`r`n"
}
if ($env:MAVEN_HOME) {
    $backendBatContent += "set `"`MAVEN_HOME=$env:MAVEN_HOME`"`r`n"
}
$backendBatContent += "echo Starting Maven Tomcat...`r`n"
$backendBatContent += "echo.`r`n"
$backendBatContent += "call mvn tomcat7:run`r`n"
$backendBatContent += "echo.`r`n"
$backendBatContent += "echo ========================================`r`n"
$backendBatContent += "echo Backend has stopped`r`n"
$backendBatContent += "echo Check the messages above for any errors`r`n"
$backendBatContent += "echo ========================================`r`n"
$backendBatContent += "pause`r`n"

$backendBat = Join-Path $env:TEMP "guilin_backend.bat"
Set-Content -Path $backendBat -Value $backendBatContent -Encoding Default -Force
Start-Process -FilePath "cmd.exe" -ArgumentList "/k", "`"$backendBat`"" -WindowStyle Normal
Write-Ok "Backend starting..."

# --- Wait for backend port 8080 ---
Write-Info "Waiting for backend to be ready (first-time build may take several minutes)..."
$backendReady = $false
$maxWaitSeconds = 360
$waitedSeconds = 0
$lastProgressSeconds = 0
$noJavaCount = 0

while ($waitedSeconds -lt $maxWaitSeconds) {
    Start-Sleep -Seconds 3
    $waitedSeconds += 3

    # Check if port 8080 is listening
    $portListening = $false
    try {
        $conn = Get-NetTCPConnection -LocalPort 8080 -State Listen -ErrorAction SilentlyContinue
        if ($conn) {
            $realProc = $conn.OwningProcess | Where-Object { $_ -ne 0 -and $_ -ne 4 } | Select-Object -First 1
            if ($realProc) { $portListening = $true }
        }
    } catch {
        # Fallback: use netstat
        try {
            $netstatCheck = (netstat -ano 2>$null | Select-String ":8080\s.*LISTENING")
            if ($netstatCheck) { $portListening = $true }
        } catch {}
    }

    if ($portListening) {
        $backendReady = $true
        break
    }

    # Check if Java process is running (compiling or running)
    # Note: process may be 'java' or 'javaw'
    $javaProcs = Get-Process -Name java, javaw -ErrorAction SilentlyContinue
    if ($javaProcs) {
        $noJavaCount = 0
    } else {
        $noJavaCount++
        # If no Java process for 30 seconds (10 checks), backend likely crashed
        if ($noJavaCount -ge 10 -and $waitedSeconds -gt 30) {
            Write-Err "No Java process detected for 30s, backend may have failed"
            Write-Err "Please check the backend command window for errors"
            break
        }
    }

    # Show progress every 15 seconds
    if ($waitedSeconds - $lastProgressSeconds -ge 15) {
        $lastProgressSeconds = $waitedSeconds
        if ($javaProcs) {
            Write-Info "Still building/starting... ($waitedSeconds s, Java running)"
        } else {
            Write-Info "Still waiting... ($waitedSeconds s)"
        }
    }
}

if ($backendReady) {
    Write-Ok "Backend ready! (took $waitedSeconds s)"
} else {
    Write-Warn "Backend not ready, starting frontend anyway..."
    Write-Warn "(If backend has errors, check the backend command window)"
}

# --- Start frontend ---
Write-Info "Starting frontend (port 5173)..."
$frontendBatContent = "@echo off`r`n"
$frontendBatContent += "chcp 65001 >nul 2>&1`r`n"
$frontendBatContent += "title Guilin News - Frontend (Vite)`r`n"
$frontendBatContent += "cd /d `"$frontendPath`"`r`n"
$frontendBatContent += "call npm run dev`r`n"
$frontendBatContent += "echo.`r`n"
$frontendBatContent += "echo ========================================`r`n"
$frontendBatContent += "echo Frontend has stopped`r`n"
$frontendBatContent += "echo ========================================`r`n"
$frontendBatContent += "pause`r`n"

$frontendBat = Join-Path $env:TEMP "guilin_frontend.bat"
Set-Content -Path $frontendBat -Value $frontendBatContent -Encoding Default -Force
Start-Process -FilePath "cmd.exe" -ArgumentList "/k", "`"$frontendBat`"" -WindowStyle Normal
Write-Ok "Frontend starting..."

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
Write-Host "  Press Enter to exit this window (services keep running)" -ForegroundColor Yellow
Read-Host
