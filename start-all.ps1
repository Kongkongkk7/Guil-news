$ErrorActionPreference = "Continue"

# ============================================================
#   Guilin University News Center - One-Click Startup Script
#   Automatically detects and installs JDK 17, Maven, Node.js
# ============================================================

Clear-Host
Write-Host ""
Write-Host "  ==========================================" -ForegroundColor Cyan
Write-Host "      Guilin University News Center" -ForegroundColor Cyan
Write-Host "      One-Click Startup Script" -ForegroundColor Cyan
Write-Host "  ==========================================" -ForegroundColor Cyan
Write-Host ""

$rootPath = $PSScriptRoot
$toolsPath = Join-Path $rootPath "tools"
$frontendPath = Join-Path $rootPath "frontend"

# Create tools directory
if (-not (Test-Path $toolsPath)) {
    New-Item -ItemType Directory -Path $toolsPath -Force | Out-Null
}

# Helper: Download file with progress
function Download-File {
    param($Url, $Destination)
    Write-Host "    Downloading from $Url ..." -ForegroundColor Gray
    try {
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $Url -OutFile $Destination -UseBasicParsing -TimeoutSec 120
        $ProgressPreference = 'Continue'
        return $true
    } catch {
        Write-Host "    Download failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Helper: Extract zip
function Extract-Zip {
    param($ZipPath, $Destination)
    Write-Host "    Extracting..." -ForegroundColor Gray
    Expand-Archive -Path $ZipPath -DestinationPath $Destination -Force
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
            Write-Host "  Found local Java: $($javaVersion.Split("`n")[0])" -ForegroundColor Green
            $javaHome = Join-Path $toolsPath "jdk"
            $env:JAVA_HOME = $javaHome
            $env:PATH = "$javaHome\bin;$env:PATH"
            $javaOk = $true
        }
    }
}

# Download and install JDK 17
if (-not $javaOk) {
    Write-Host "  JDK 17+ not found. Auto-installing..." -ForegroundColor DarkYellow

    # Detect architecture
    $arch = "x64"
    if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") { $arch = "aarch64" }

    # Eclipse Temurin JDK 17 (portable zip)
    $jdkUrl = "https://api.adoptium.net/v3/binary/latest/17/ga/windows/$arch/jdk/hotspot/normal/eclipse?project=jdk"
    $jdkZip = Join-Path $toolsPath "jdk17.zip"

    if (Download-File -Url $jdkUrl -Destination $jdkZip) {
        # Clean old jdk folder
        $jdkDir = Join-Path $toolsPath "jdk"
        if (Test-Path $jdkDir) { Remove-Item $jdkDir -Recurse -Force }
        Extract-Zip -ZipPath $jdkZip -Destination $toolsPath

        # Find extracted folder (e.g., jdk-17.0.x+x)
        $extracted = Get-ChildItem -Path $toolsPath -Directory | Where-Object { $_.Name -like "jdk-17*" } | Select-Object -First 1
        if ($extracted) {
            Rename-Item -Path $extracted.FullName -NewName "jdk" -Force
            Remove-Item $jdkZip -Force
            $javaHome = Join-Path $toolsPath "jdk"
            $env:JAVA_HOME = $javaHome
            $env:PATH = "$javaHome\bin;$env:PATH"
            $javaVersion = (& java -version 2>&1 | Out-String).Trim()
            Write-Host "  Installed: $($javaVersion.Split("`n")[0])" -ForegroundColor Green
            $javaOk = $true
        } else {
            Write-Host "  Failed to find extracted JDK folder" -ForegroundColor Red
        }
    }

    if (-not $javaOk) {
        Write-Host ""
        Write-Host "  Auto-install failed. Please install JDK 17 manually:" -ForegroundColor Red
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
    Write-Host "  Maven not found. Auto-installing..." -ForegroundColor DarkYellow

    $mvnUrl = "https://dlcdn.apache.org/maven/maven-3/3.9.9/binaries/apache-maven-3.9.9-bin.zip"
    $mvnZip = Join-Path $toolsPath "maven.zip"

    if (Download-File -Url $mvnUrl -Destination $mvnZip) {
        $mvnDir = Join-Path $toolsPath "maven"
        if (Test-Path $mvnDir) { Remove-Item $mvnDir -Recurse -Force }
        Extract-Zip -ZipPath $mvnZip -Destination $toolsPath

        $extracted = Get-ChildItem -Path $toolsPath -Directory | Where-Object { $_.Name -like "apache-maven-*" } | Select-Object -First 1
        if ($extracted) {
            Rename-Item -Path $extracted.FullName -NewName "maven" -Force
            Remove-Item $mvnZip -Force
            $mavenHome = Join-Path $toolsPath "maven"
            $env:PATH = "$mavenHome\bin;$env:PATH"
            Write-Host "  Installed: Maven 3.9.9" -ForegroundColor Green
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
    Write-Host "  Node.js 18+ not found. Auto-installing..." -ForegroundColor DarkYellow

    # Detect architecture
    $nodeArch = "x64"
    if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") { $nodeArch = "arm64" }

    # Get latest LTS version
    $nodeApiUrl = "https://nodejs.org/dist/index.json"
    try {
        $ProgressPreference = 'SilentlyContinue'
        $nodeData = Invoke-RestMethod -Uri $nodeApiUrl -TimeoutSec 15
        $ltsVersion = ($nodeData | Where-Object { $_.lts -ne $false } | Select-Object -First 1).version
        $ProgressPreference = 'Continue'
    } catch {
        $ltsVersion = "v22.11.0"
    }

    $nodeUrl = "https://nodejs.org/dist/$ltsVersion/node-$ltsVersion-win-$nodeArch.zip"
    $nodeZip = Join-Path $toolsPath "nodejs.zip"

    if (Download-File -Url $nodeUrl -Destination $nodeZip) {
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
        Write-Host "  https://nodejs.org/" -ForegroundColor Cyan
        Read-Host "  Press Enter to exit"
        exit 1
    }
}

# ============================================================
# Step 4: Install frontend dependencies
# ============================================================
Write-Host ""
Write-Host "[4/6] Installing frontend dependencies..." -ForegroundColor Yellow

$nodeModules = Join-Path $frontendPath "node_modules"
if (-not (Test-Path $nodeModules)) {
    Write-Host "  Running npm install (first time may take a few minutes)..." -ForegroundColor Gray
    Push-Location $frontendPath
    npm install --silent 2>&1 | Out-Null
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
