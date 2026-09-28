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
echo     Modify Gateway and DNS
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
set /p IDX="Enter the [Index] number of your adapter: "

:: 4. Automatically fetch the current IP, Prefix Length, and Name
for /f "tokens=1,2 delims=/" %%a in ('powershell -Command "(Get-NetIPAddress -InterfaceIndex %IDX% -AddressFamily IPv4).IPAddress + '/' + (Get-NetIPAddress -InterfaceIndex %IDX% -AddressFamily IPv4).PrefixLength"') do (
    set "CURRENT_IP=%%a"
    set "PREFIX=%%b"
)
for /f "delims=" %%a in ('powershell -Command "(Get-NetAdapter -InterfaceIndex %IDX%).Name"') do (
    set "ADAPTER_NAME=%%a"
)

if "%CURRENT_IP%"=="" (
    echo [ERROR] Could not retrieve IP info for Index %IDX%. Please double-check the number.
    pause
    exit
)

echo ---------------------------------------------------
echo Adapter Selected: %ADAPTER_NAME% (Index %IDX%)
echo Recorded Current IP: %CURRENT_IP%
echo ---------------------------------------------------

:: 5. Prompt for the Target Gateway
set /p NEW_GW="Enter Target [Gateway] IP (e.g., 192.168.1.1): "

:: 6. Prompt for the Preferred DNS (Separated)
echo.
echo Leave blank and press [Enter] to use the Gateway IP as DNS.
set /p NEW_DNS="Enter Preferred [DNS] IP: "

:: If DNS input is empty, copy the Gateway IP
if "%NEW_DNS%"=="" (
    set "NEW_DNS=%NEW_GW%"
)

echo.
echo Applying new network parameters, please wait...
echo ---------------------------------------------------

:: 7. Force static mode, clear all old gateways, and set new Gateway + DNS (all outputs hidden)
powershell -Command "Set-NetIPInterface -InterfaceIndex %IDX% -Dhcp Disabled -ErrorAction SilentlyContinue" >nul 2>&1
powershell -Command "Remove-NetRoute -InterfaceIndex %IDX% -Confirm:$false -ErrorAction SilentlyContinue" >nul 2>&1
powershell -Command "New-NetIPAddress -InterfaceIndex %IDX% -IPAddress '%CURRENT_IP%' -PrefixLength %PREFIX% -ErrorAction SilentlyContinue" >nul 2>&1
powershell -Command "New-NetRoute -InterfaceIndex %IDX% -DestinationPrefix '0.0.0.0/0' -NextHop '%NEW_GW%' -ErrorAction SilentlyContinue" >nul 2>&1

:: Fallback to netsh for DNS to bypass CIM permission restrictions securely
netsh interface ip set dns name="%ADAPTER_NAME%" source=static addr=%NEW_DNS% validate=no >nul 2>&1

echo ---------------------------------------------------
echo Configuration Complete! Current Active Settings:
echo ---------------------------------------------------
powershell -Command "Get-NetIPConfiguration -InterfaceIndex %IDX%"
echo.

pause
