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
set LOG_FILE=%temp%\boot_back_to_normal_mode.log
echo Script started at %date% %time% >> "%LOG_FILE%"

rem Check if we are in Safe Mode
echo Checking Safe Mode status... >> "%LOG_FILE%"
for /f "tokens=2 delims=[]" %%i in ('bcdedit /enum {current} ^| findstr /r /c:"safeboot"') do set "SAFEBOOT_OPTION=%%i"
if /i "%SAFEBOOT_OPTION%"=="network" (
    echo System is in Safe Mode with Networking >> "%LOG_FILE%"
) else (
    echo System is not in Safe Mode. Exiting... >> "%LOG_FILE%"
    pause
    exit /b 1
)

rem Navigate to the CrowdStrike directory
echo Navigating to CrowdStrike directory... >> "%LOG_FILE%"
cd /d %WINDIR%\System32\drivers\CrowdStrike >> "%LOG_FILE%" 2>&1
if %errorLevel% neq 0 (
    echo Failed to navigate to CrowdStrike directory. >> "%LOG_FILE%"
    pause
    exit /b 1
)

rem Delete the matching file
set fileDeleted=false
for %%f in (C-00000291*.sys) do (
    if exist "%%f" (
        del /f /q "%%f"
        set fileDeleted=true
    ) else (
        echo File not found: %%f >> "%LOG_FILE%"
    )
)

rem Confirmation dialog if the file was deleted
if "%fileDeleted%" == "true" (
    powershell -command "Add-Type -AssemblyName PresentationCore,PresentationFramework;[System.Windows.MessageBox]::Show('File(s) deleted successfully.', 'Confirmation')" >> "%LOG_FILE%" 2>&1
) else (
    powershell -command "Add-Type -AssemblyName PresentationCore,PresentationFramework;[System.Windows.MessageBox]::Show('No matching file found to delete.', 'Confirmation')" >> "%LOG_FILE%" 2>&1
)

rem Configure boot back to normal mode
echo Configuring boot back to normal mode... >> "%LOG_FILE%"
bcdedit /deletevalue {current} safeboot >> "%LOG_FILE%" 2>&1
if %errorLevel% neq 0 (
    echo Failed to reset boot configuration. >> "%LOG_FILE%"
    pause
    exit /b 1
)

rem Restart the system again to ensure normal boot
echo Restarting the system... >> "%LOG_FILE%"
shutdown /r /t 0
if %errorLevel% neq 0 (
    echo Failed to restart the system. >> "%LOG_FILE%"
    pause
    exit /b 1
)

endlocal
