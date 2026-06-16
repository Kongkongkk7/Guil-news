Clear-Host
Write-Host "=================================================="
Write-Host "     Guilin University News Center"
Write-Host "           Service Launcher"
Write-Host "=================================================="
Write-Host ""

$rootPath = $PSScriptRoot
$backendPath = $rootPath
$frontendPath = Join-Path $rootPath "frontend"

$backendPort = 8080
$frontendPort = 5173

Write-Host "[1/5] Checking Node.js..."
$nodeCmd = Get-Command node -ErrorAction SilentlyContinue
if (-not $nodeCmd) {
    Write-Host "  ERROR: Node.js not found!" -ForegroundColor Red
    Write-Host "  Please install Node.js 18+ from https://nodejs.org" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}
$nodeVersion = node --version
Write-Host "  Node.js $nodeVersion detected" -ForegroundColor Green

Write-Host ""
Write-Host "[2/5] Checking Maven..."
$mvnCmd = Get-Command mvn -ErrorAction SilentlyContinue
if (-not $mvnCmd) {
    Write-Host "  ERROR: Maven not found!" -ForegroundColor Red
    Write-Host "  Please install Maven 3.6+ from https://maven.apache.org" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}
$mvnVersion = mvn --version | Select-Object -First 1
Write-Host "  Maven detected" -ForegroundColor Green

Write-Host ""
Write-Host "[3/5] Checking and releasing ports..."
$ports = @($backendPort, $frontendPort)
foreach ($port in $ports) {
    $procs = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess -Unique
    if ($procs) {
        Write-Host "  Port $port is occupied, releasing..."
        foreach ($procId in $procs) {
            try {
                Stop-Process -Id $procId -Force -ErrorAction SilentlyContinue
                Write-Host "    Success"
            } catch {
                Write-Host "    Failed"
            }
        }
    } else {
        Write-Host "  Port $port is available"
    }
}

Write-Host ""
Write-Host "[4/5] Installing frontend dependencies..."
if (-not (Test-Path (Join-Path $frontendPath "node_modules"))) {
    Write-Host "  Installing frontend dependencies..."
    Push-Location $frontendPath
    npm install --silent
    Pop-Location
    Write-Host "  Frontend dependencies installed" -ForegroundColor Green
} else {
    Write-Host "  Frontend dependencies already exist"
}

Write-Host ""
Write-Host "[5/5] Starting servers..."
Write-Host "  Starting Java backend (Maven + Tomcat)..."
Start-Process -FilePath "cmd.exe" -ArgumentList "/k cd /d `"$backendPath`" && mvn tomcat7:run" -WindowStyle Normal

Start-Sleep -Seconds 8

Write-Host "  Starting React frontend..."
Start-Process -FilePath "cmd.exe" -ArgumentList "/k cd /d `"$frontendPath`" && npm run dev" -WindowStyle Normal

Write-Host ""
Write-Host "=================================================="
Write-Host "              All Services Started!"
Write-Host "=================================================="
Write-Host ""
Write-Host "Backend: http://localhost:$backendPort/guilin-news" -ForegroundColor Cyan
Write-Host "Frontend: http://localhost:$frontendPort" -ForegroundColor Cyan
Write-Host ""
Write-Host "Open browser and visit: http://localhost:$frontendPort" -ForegroundColor Yellow
Write-Host ""
Read-Host "Press Enter to exit"