@echo off
cls
echo ==========================================
echo     Guilin University News Center
echo ==========================================
echo.

set ROOT=%~dp0
set FRONTEND=%ROOT%frontend

echo [1/5] Checking Java...
java -version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Java not found!
    echo Please install JDK 17+
    pause
    exit /b 1
)
echo Java OK
echo.

echo [2/5] Checking Maven...
mvn --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Maven not found!
    echo Please install Maven 3.6+
    pause
    exit /b 1
)
echo Maven OK
echo.

echo [3/5] Checking Node.js...
node --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Node.js not found!
    echo Please install Node.js 18+
    pause
    exit /b 1
)
echo Node.js OK
echo.

echo [4/5] Installing frontend dependencies...
if not exist "%FRONTEND%\node_modules" (
    echo Installing...
    cd /d "%FRONTEND%"
    npm install --silent
    cd /d "%ROOT%"
    echo Done
) else (
    echo Already installed
)
echo.

echo [5/5] Starting servers...
echo Starting backend...
cd /d "%ROOT%"
start mvn tomcat7:run
echo Starting frontend...
cd /d "%FRONTEND%"
start npm run dev
echo.

echo ==========================================
echo All services started!
echo ==========================================
echo.
echo Backend: http://localhost:8080/guilin-news
echo Frontend: http://localhost:5173
echo.
pause