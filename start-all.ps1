$ErrorActionPreference = "Stop"

Clear-Host
Write-Host "=========================================="
Write-Host "    Guilin University News Center"
Write-Host "=========================================="
Write-Host ""

$rootPath = $PSScriptRoot
$frontendPath = Join-Path $rootPath "frontend"
$backendPort = 8080
$frontendPort = 5173

Write-Host "[1/5] Checking Java..."
if (-not (Get-Command java -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: Java not found!"
    Write-Host "Please install JDK 17+"
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Host "Java OK"

Write-Host ""
Write-Host "[2/5] Checking Maven..."
if (-not (Get-Command mvn -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: Maven not found!"
    Write-Host "Please install Maven 3.6+"
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Host "Maven OK"

Write-Host ""
Write-Host "[3/5] Checking Node.js..."
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: Node.js not found!"
    Write-Host "Please install Node.js 18+"
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Host "Node.js OK"

Write-Host ""
Write-Host "[4/5] Installing frontend dependencies..."
$nodeModules = Join-Path $frontendPath "node_modules"
if (-not (Test-Path $nodeModules)) {
    Write-Host "Installing..."
    Push-Location $frontendPath
    npm install --silent
    Pop-Location
    Write-Host "Done"
} else {
    Write-Host "Already installed"
}

Write-Host ""
Write-Host "[5/5] Starting servers..."
Write-Host "Starting backend..."
$backendCmd = "cd /d `"$rootPath`" && mvn tomcat7:run"
Start-Process -FilePath "cmd.exe" -ArgumentList "/k", $backendCmd
Start-Sleep -Seconds 10

Write-Host "Starting frontend..."
$frontendCmd = "cd /d `"$frontendPath`" && npm run dev"
Start-Process -FilePath "cmd.exe" -ArgumentList "/k", $frontendCmd

Write-Host ""
Write-Host "=========================================="
Write-Host "All services started!"
Write-Host "=========================================="
Write-Host ""
Write-Host "Backend: http://localhost:$backendPort/guilin-news"
Write-Host "Frontend: http://localhost:$frontendPort"
Write-Host ""
Read-Host "Press Enter to exit"