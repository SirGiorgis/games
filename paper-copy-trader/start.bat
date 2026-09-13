@echo off
cd /d "%~dp0"
echo.
echo =============================================
echo  PAPER TRADING — NO REAL ORDERS
echo =============================================
echo.
where node >nul 2>&1
if errorlevel 1 (
  echo Node.js was not found.
  echo Install the LTS build from https://nodejs.org then run this file again.
  pause
  exit /b 1
)
if not exist node_modules (
  echo Installing dependencies...
  call npm install
  if errorlevel 1 (
    echo npm install failed.
    pause
    exit /b 1
  )
)
echo.
echo This PC:     http://localhost:3000
echo Phone/Wi-Fi: http://YOUR-WINDOWS-PC-LAN-IP:3000
echo   1. On Windows, run: ipconfig
echo   2. Use the IPv4 address of your Wi-Fi adapter.
echo   3. Phone and PC must be on the same network.
echo   4. Allow Node.js through Windows Firewall if the phone cannot connect.
echo.
npm run dev
