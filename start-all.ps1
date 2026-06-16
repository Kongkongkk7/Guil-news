Clear-Host
Write-Host "=================================================="
Write-Host "     Guilin University News Center"
Write-Host "           Service Launcher"
Write-Host "=================================================="
Write-Host ""

# 自动获取脚本所在目录（支持任意电脑）
$rootPath = $PSScriptRoot
$backendPath = $rootPath
$frontendPath = Join-Path $rootPath "frontend"

$backendPort = 4001
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
Write-Host "[2/5] Checking and releasing ports..."
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
Write-Host "[3/5] Installing dependencies..."
# 后端依赖
if (-not (Test-Path (Join-Path $backendPath "node_modules"))) {
    Write-Host "  Installing backend dependencies..."
    Push-Location $backendPath
    npm install --silent
    Pop-Location
    Write-Host "  Backend dependencies installed" -ForegroundColor Green
} else {
    Write-Host "  Backend dependencies already exist"
}

# 前端依赖
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
Write-Host "[4/5] Starting backend server..."
try {
    Start-Process -FilePath "cmd.exe" -ArgumentList "/k cd /d `"$backendPath`" && npx tsx index.ts" -WindowStyle Normal
    Write-Host "  Backend server started" -ForegroundColor Green
} catch {
    Write-Host "  ERROR: Failed to start backend" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[5/5] Waiting for backend and starting frontend..."
Start-Sleep -Seconds 3

try {
    if (Test-Path (Join-Path $frontendPath "package.json")) {
        Start-Process -FilePath "cmd.exe" -ArgumentList "/k cd /d `"$frontendPath`" && npm run dev" -WindowStyle Normal
        Write-Host "  Frontend server started" -ForegroundColor Green
    } else {
        Write-Host "  ERROR: package.json not found" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "  ERROR: Failed to start frontend" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=================================================="
Write-Host "              All Services Started!"
Write-Host "=================================================="
Write-Host ""
Write-Host "Backend: http://localhost:$backendPort" -ForegroundColor Cyan
Write-Host "Frontend: http://localhost:$frontendPort" -ForegroundColor Cyan
Write-Host ""
Write-Host "Open browser and visit: http://localhost:$frontendPort" -ForegroundColor Yellow
Write-Host ""
Read-Host "Press Enter to exit"
