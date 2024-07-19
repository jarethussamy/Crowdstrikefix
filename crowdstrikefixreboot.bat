@echo off
setlocal

rem Check if running as administrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo This script must be run as an administrator.
    pause
    exit /b 1
)

rem Boot into Safe Mode with Networking
bcdedit /set {current} safeboot network

rem Restart the system
shutdown /r /t 0
timeout /t 60

rem Ensure that we are now in Safe Mode
if /i "%SAFEBOOT_OPTION%"=="network" (
    rem Navigate to the CrowdStrike directory
    cd /d %WINDIR%\System32\drivers\CrowdStrike
    
    rem Delete the matching file
    for %%f in (C-00000291*.sys) do del /f /q "%%f"
    
    rem Boot into normal mode
    bcdedit /deletevalue {current} safeboot
    
    rem Restart the system again
    shutdown /r /t 0
)

endlocal
