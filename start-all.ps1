$ErrorActionPreference = "Stop"

Clear-Host
Write-Host "╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║           Guilin University News Center - Launcher              ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$rootPath = $PSScriptRoot
$backendPath = $rootPath
$frontendPath = Join-Path $rootPath "frontend"

$backendPort = 8080
$frontendPort = 5173

function Test-CommandExists {
    param([string]$Command)
    $exists = $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
    return $exists
}

function Invoke-WithRetry {
    param(
        [ScriptBlock]$Script,
        [int]$MaxRetries = 3,
        [string]$ActionName
    )
    $retryCount = 0
    while ($true) {
        try {
            & $Script
            return
        } catch {
            $retryCount++
            if ($retryCount -ge $MaxRetries) {
                Write-Host "ERROR: $ActionName failed after $MaxRetries attempts" -ForegroundColor Red
                throw
            }
            Write-Host "WARNING: $ActionName failed, retrying ($retryCount/$MaxRetries)..." -ForegroundColor Yellow
            Start-Sleep -Seconds 5
        }
    }
}

Write-Host "[1/5] Checking Java Development Kit..." -ForegroundColor White
if (-not (Test-CommandExists "java")) {
    Write-Host "ERROR: Java not found!" -ForegroundColor Red
    Write-Host "Please install JDK 17+ from https://adoptium.net/" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}
try {
    $javaVersion = java -version 2>&1 | Select-Object -First 1
    if ($javaVersion -match 'version "(\d+)\.') {
        $majorVersion = [int]$matches[1]
        if ($majorVersion -lt 17) {
            Write-Host "ERROR: Java version $majorVersion is too old!" -ForegroundColor Red
            Write-Host "Please install JDK 17+" -ForegroundColor Yellow
            Read-Host "Press Enter to exit"
            exit 1
        }
        Write-Host "Java $javaVersion detected" -ForegroundColor Green
    } else {
        Write-Host "Java detected (version check skipped)" -ForegroundColor Green
    }
} catch {
    Write-Host "Java detected (version check failed)" -ForegroundColor Green
}

Write-Host ""
Write-Host "[2/5] Checking Maven..." -ForegroundColor White
if (-not (Test-CommandExists "mvn")) {
    Write-Host "ERROR: Maven not found!" -ForegroundColor Red
    Write-Host "Please install Maven 3.6+ from https://maven.apache.org/download.cgi" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}
try {
    $mvnOutput = mvn --version 2>&1 | Select-Object -First 1
    Write-Host "Maven detected" -ForegroundColor Green
} catch {
    Write-Host "Maven detected" -ForegroundColor Green
}

Write-Host ""
Write-Host "[3/5] Checking Node.js..." -ForegroundColor White
if (-not (Test-CommandExists "node")) {
    Write-Host "ERROR: Node.js not found!" -ForegroundColor Red
    Write-Host "Please install Node.js 18+ from https://nodejs.org" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}
try {
    $nodeVersion = node --version
    Write-Host "Node.js $nodeVersion detected" -ForegroundColor Green
} catch {
    Write-Host "Node.js detected" -ForegroundColor Green
}

Write-Host ""
Write-Host "[4/5] Checking and releasing ports..." -ForegroundColor White
$ports = @($backendPort, $frontendPort)
foreach ($port in $ports) {
    try {
        $procs = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess -Unique
        if ($procs) {
            Write-Host "Port $port is occupied, releasing..." -ForegroundColor Yellow
            foreach ($procId in $procs) {
                try {
                    Stop-Process -Id $procId -Force -ErrorAction SilentlyContinue
                    Write-Host "Process $procId stopped" -ForegroundColor Green
                } catch {
                    Write-Host "Failed to stop process $procId" -ForegroundColor Red
                }
            }
            Start-Sleep -Seconds 1
        } else {
            Write-Host "Port $port is available" -ForegroundColor Green
        }
    } catch {
        Write-Host "Port $port check failed, skipping..." -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "[5/5] Installing frontend dependencies..." -ForegroundColor White
$nodeModulesPath = Join-Path $frontendPath "node_modules"
if (-not (Test-Path $nodeModulesPath)) {
    Write-Host "Installing frontend dependencies..." -ForegroundColor Yellow
    try {
        Push-Location $frontendPath
        Invoke-WithRetry -Script { npm install --silent } -MaxRetries 3 -ActionName "npm install"
        Write-Host "Frontend dependencies installed successfully" -ForegroundColor Green
    } catch {
        Write-Host "ERROR: Failed to install frontend dependencies" -ForegroundColor Red
        Write-Host "Please try running 'npm install' manually in the frontend folder" -ForegroundColor Yellow
        Read-Host "Press Enter to exit"
        exit 1
    } finally {
        Pop-Location
    }
} else {
    Write-Host "Frontend dependencies already exist" -ForegroundColor Green
}

Write-Host ""
Write-Host "══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Starting Services..." -ForegroundColor Cyan
Write-Host "══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

Write-Host "Starting Java Backend (Maven + Tomcat)..." -ForegroundColor Yellow
try {
    $backendCmd = "cd /d `"$backendPath`" && mvn tomcat7:run"
    Start-Process -FilePath "cmd.exe" -ArgumentList "/k $backendCmd" -WindowStyle Normal -ErrorAction Stop
    Write-Host "Backend server started in new window" -ForegroundColor Green
} catch {
    Write-Host "WARNING: Failed to start backend in new window, trying current window..." -ForegroundColor Yellow
    Push-Location $backendPath
    Start-Process -FilePath "mvn" -ArgumentList "tomcat7:run" -WindowStyle Normal
    Pop-Location
}

Write-Host "Waiting for backend to initialize..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

Write-Host "Starting React Frontend..." -ForegroundColor Yellow
try {
    $frontendCmd = "cd /d `"$frontendPath`" && npm run dev"
    Start-Process -FilePath "cmd.exe" -ArgumentList "/k $frontendCmd" -WindowStyle Normal -ErrorAction Stop
    Write-Host "Frontend server started in new window" -ForegroundColor Green
} catch {
    Write-Host "WARNING: Failed to start frontend in new window, trying current window..." -ForegroundColor Yellow
    Push-Location $frontendPath
    Start-Process -FilePath "npm" -ArgumentList "run dev" -WindowStyle Normal
    Pop-Location
}

Write-Host ""
Write-Host "══════════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "All Services Started!" -ForegroundColor Green
Write-Host "══════════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "Backend URL: http://localhost:$backendPort/guilin-news" -ForegroundColor Cyan
Write-Host "Frontend URL: http://localhost:$frontendPort" -ForegroundColor Cyan
Write-Host ""
Write-Host "Open your browser and visit:" -ForegroundColor White
Write-Host "http://localhost:$frontendPort" -ForegroundColor Yellow -BackgroundColor Black
Write-Host ""
Write-Host "Tips:" -ForegroundColor White
Write-Host "- If you see Network Error, wait a few seconds and refresh" -ForegroundColor Gray
Write-Host "- If ports are still occupied, restart your computer" -ForegroundColor Gray
Write-Host "- Close both command windows to stop the services" -ForegroundColor Gray
Write-Host ""
Read-Host "Press Enter to close this launcher"