@echo off
cls

:: 1. Check for Administrator privileges
openfiles >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Please run as Administrator.
    echo.
    pause
    exit /B
)

echo ===================================================
echo     Revert to DHCP 
echo ===================================================
echo.

:: 2. List all active network adapters with perfect alignment
echo [INFO] Detecting active network adapters:
echo ---------------------------------------------------
echo Index   Adapter Name (Description)
echo -----   --------------------------
powershell -Command "Get-NetAdapter | Where-Object {$_.Status -eq 'Up'} | ForEach-Object { '{0,-7} {1} ({2})' -f $_.InterfaceIndex, $_.Name, $_.InterfaceDescription }"
echo ---------------------------------------------------
echo.

:: 3. Prompt user for the Index number
set /p IDX="Enter the [Index] number of your adapter to restore: "

:: 4. Automatically check if the Index exists and fetch the name
for /f "delims=" %%a in ('powershell -Command "(Get-NetAdapter -InterfaceIndex %IDX% -ErrorAction SilentlyContinue).Name"') do (
    set "ADAPTER_NAME=%%a"
)

if "%ADAPTER_NAME%"=="" (
    echo [ERROR] Invalid Index number. Please double-check the list.
    pause
    exit
)

echo ---------------------------------------------------
echo Adapter Selected: %ADAPTER_NAME% (Index %IDX%)
echo Status: Purging cached gateways and enabling DHCP...
echo ---------------------------------------------------
echo.

:: 5. [FIXED] Forcefully clear any sticky/grayed-out static gateways first, then enable DHCP
powershell -Command "Remove-NetRoute -InterfaceIndex %IDX% -Confirm:$false -ErrorAction SilentlyContinue" >nul 2>&1
powershell -Command "Set-NetIPInterface -InterfaceIndex %IDX% -Dhcp Enabled -ErrorAction SilentlyContinue" >nul 2>&1
powershell -Command "Set-DnsClientServerAddress -InterfaceIndex %IDX% -ResetServerAddresses -ErrorAction SilentlyContinue" >nul 2>&1

echo Reconfiguring network via DHCP, please wait...
echo ---------------------------------------------------

:: 6. Force a quick refresh to fetch new IP from your main router
ipconfig /renew %ADAPTER_NAME% >nul 2>&1

echo ---------------------------------------------------
echo Success! DHCP Restored. Current Active Settings:
echo ---------------------------------------------------
powershell -Command "Get-NetIPConfiguration -InterfaceIndex %IDX%"
echo.

pause
