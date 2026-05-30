Clear-Host
Write-Host "=================================================="
Write-Host "     Guilin University News Center"
Write-Host "           Service Launcher"
Write-Host "=================================================="
Write-Host ""

$backendPort = 4001
$frontendPort = 5173
$backendPath = "d:\demo1"
$frontendPath = "d:\demo1\frontend"
$bunPath = "C:\Users\10492\.bun\bin\bun.exe"

Write-Host "[1/4] Checking and releasing ports..."

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
Write-Host "[2/4] Starting backend server..."
try {
    if (Test-Path $bunPath) {
        Start-Process -FilePath "cmd.exe" -ArgumentList "/k cd /d $backendPath && ""$bunPath"" run index.ts" -WindowStyle Normal
        Write-Host "  Backend server started"
    } else {
        Write-Host "  ERROR: Bun not found"
        exit 1
    }
} catch {
    Write-Host "  ERROR: Failed to start backend"
    exit 1
}

Write-Host ""
Write-Host "[3/4] Waiting for backend..."
Start-Sleep -Seconds 2

Write-Host ""
Write-Host "[4/4] Starting frontend server..."
try {
    if (Test-Path "$frontendPath\package.json") {
        Start-Process -FilePath "cmd.exe" -ArgumentList "/k cd /d $frontendPath && npm run dev" -WindowStyle Normal
        Write-Host "  Frontend server started"
    } else {
        Write-Host "  ERROR: package.json not found"
        exit 1
    }
} catch {
    Write-Host "  ERROR: Failed to start frontend"
    exit 1
}

Write-Host ""
Write-Host "=================================================="
Write-Host "              All Services Started!"
Write-Host "=================================================="
Write-Host ""
Write-Host "Backend: http://localhost:$backendPort"
Write-Host "Frontend: http://localhost:$frontendPort"
Write-Host ""
Write-Host "Open browser and visit: http://localhost:$frontendPort"
Write-Host ""
Read-Host "Press Enter to exit"