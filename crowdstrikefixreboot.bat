
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
timeout /t 60 /nobreak

rem After reboot, we should be in Safe Mode
:SafeMode
netsh wlan show interfaces >nul 2>&1
if %errorLevel% neq 0 (
    echo Not in Safe Mode with Networking, exiting...
    pause
    exit /b 1
)

rem Navigate to the CrowdStrike directory
cd /d %WINDIR%\System32\drivers\CrowdStrike

rem Delete the matching file
set fileDeleted=false
for %%f in (C-00000291*.sys) do (
    if exist "%%f" (
        del /f /q "%%f"
        set fileDeleted=true
    ) else (
        echo File not found: %%f
    )
)

rem Confirmation dialog if the file was deleted
if "%fileDeleted%" == "true" (
    echo File(s) deleted successfully.
    pause
) else (
    echo No matching file found to delete.
    pause
)

rem Boot back into normal mode
bcdedit /deletevalue {current} safeboot

rem Restart the system again
shutdown /r /t 0

endlocal