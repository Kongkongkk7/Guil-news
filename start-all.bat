@echo off
chcp 65001 >nul
cls
echo ╔══════════════════════════════════════════════════════════════════╗
echo ║           Guilin University News Center - Launcher              ║
echo ╚══════════════════════════════════════════════════════════════════╝
echo.

set "ROOT=%~dp0"
set "BACKEND=%ROOT%"
set "FRONTEND=%ROOT%frontend"
set "BACKEND_PORT=8080"
set "FRONTEND_PORT=5173"

echo [1/5] Checking Java Development Kit...
java -version >nul 2>&1
if errorlevel 1 (
    echo   ERROR: Java not found!
    echo   Please install JDK 17+ from https://adoptium.net/
    pause
    exit /b 1
)
echo   Java detected
echo.

echo [2/5] Checking Maven...
mvn --version >nul 2>&1
if errorlevel 1 (
    echo   ERROR: Maven not found!
    echo   Please install Maven 3.6+ from https://maven.apache.org/download.cgi
    pause
    exit /b 1
)
echo   Maven detected
echo.

echo [3/5] Checking Node.js...
node --version >nul 2>&1
if errorlevel 1 (
    echo   ERROR: Node.js not found!
    echo   Please install Node.js 18+ from https://nodejs.org
    pause
    exit /b 1
)
echo   Node.js detected
echo.

echo [4/5] Installing frontend dependencies...
if not exist "%FRONTEND%\node_modules" (
    echo   Installing frontend dependencies...
    cd /d "%FRONTEND%"
    npm install --silent
    if errorlevel 1 (
        echo   ERROR: Failed to install frontend dependencies
        echo   Please try running 'npm install' manually in the frontend folder
        pause
        exit /b 1
    )
    echo   Frontend dependencies installed successfully
) else (
    echo   Frontend dependencies already exist
)
cd /d "%ROOT%"
echo.

echo ══════════════════════════════════════════════════════════════════
echo                    Starting Services...
echo ══════════════════════════════════════════════════════════════════
echo.

echo   Starting Java Backend (Maven + Tomcat)...
start "Guilin-News-Backend" cmd /k "cd /d "%BACKEND%" && mvn tomcat7:run"
echo   Backend server started in new window
echo.

echo   Waiting for backend to initialize...
timeout /t 10 /nobreak >nul

echo   Starting React Frontend...
start "Guilin-News-Frontend" cmd /k "cd /d "%FRONTEND%" && npm run dev"
echo   Frontend server started in new window
echo.

echo ══════════════════════════════════════════════════════════════════
echo                     All Services Started!
echo ══════════════════════════════════════════════════════════════════
echo.
echo   Backend URL: http://localhost:%BACKEND_PORT%/guilin-news
echo   Frontend URL: http://localhost:%FRONTEND_PORT%
echo.
echo   Open your browser and visit:
echo   http://localhost:%FRONTEND_PORT%
echo.
echo   Tips:
echo   - If you see 'Network Error', wait a few seconds and refresh
echo   - Close both command windows to stop the services
echo.
pause