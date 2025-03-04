@echo off
setlocal

rem Check if running as administrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo This script must be run as an administrator.
    pause
    exit /b 1
)

rem Log actions to a file
set LOG_FILE=%temp%\boot_into_safe_mode.log
echo Script started at %date% %time% >> "%LOG_FILE%"

rem Configure Safe Mode with Networking
echo Configuring Safe Mode with Networking... >> "%LOG_FILE%"
bcdedit /set {current} safeboot network >> "%LOG_FILE%" 2>&1
if %errorLevel% neq 0 (
    echo Failed to set Safe Mode with Networking. >> "%LOG_FILE%"
    echo Failed to set Safe Mode with Networking.
    pause
    exit /b 1
)

rem Restart the system
echo Restarting the system... >> "%LOG_FILE%"
shutdown /r /t 0
if %errorLevel% neq 0 (
    echo Failed to restart the system. >> "%LOG_FILE%"
    echo Failed to restart the system.
    pause
    exit /b 1
)

endlocal
