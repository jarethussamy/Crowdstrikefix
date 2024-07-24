@echo off
setlocal

rem Check if running as administrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo This script must be run as an administrator. >> "%temp%\boot_and_cleanup.log"
    echo This script must be run as an administrator.
    pause
    exit /b 1
)

rem Log actions to a file
set LOG_FILE=%temp%\boot_and_cleanup.log
echo Script started at %date% %time% >> "%LOG_FILE%"

rem Suspend BitLocker on the system drive
echo Suspending BitLocker protection... >> "%LOG_FILE%"
manage-bde -protectors -disable %SystemDrive% >> "%LOG_FILE%" 2>&1
if %errorLevel% neq 0 (
    echo Failed to suspend BitLocker protection. >> "%LOG_FILE%"
    echo Failed to suspend BitLocker protection.
    pause
    exit /b 1
)

rem Boot into Safe Mode with Networking
echo Configuring Safe Mode with Networking... >> "%LOG_FILE%"
bcdedit /set {current} safeboot network >> "%LOG_FILE%" 2>&1
if %errorLevel% neq 0 (
    echo Failed to set Safe Mode with Networking. >> "%LOG_FILE%"
    echo Failed to set Safe Mode with Networking.
    pause
    exit /b 1
)

rem Create a scheduled task to run this script after user logon in Safe Mode
echo Creating scheduled task... >> "%LOG_FILE%"
schtasks /create /tn BootAndCleanup /tr "\"%~dpnx0\" -run" /sc onstart /f >> "%LOG_FILE%" 2>&1
if %errorLevel% neq 0 (
    echo Failed to create scheduled task. >> "%LOG_FILE%"
    echo Failed to create scheduled task.
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

:RunScript
rem Wait for the system to restart
timeout /t 60 /nobreak

rem After reboot, we should be in Safe Mode
rem Check if we are in Safe Mode
echo Checking Safe Mode status... >> "%LOG_FILE%"
for /f "tokens=2 delims=[]" %%i in ('bcdedit /enum {current} ^| findstr /r /c:"safeboot"') do set "SAFEBOOT_OPTION=%%i"
if /i "%SAFEBOOT_OPTION%"=="network" (
    echo System is in Safe Mode with Networking >> "%LOG_FILE%"

    rem Navigate to the CrowdStrike directory
    cd /d %WINDIR%\System32\drivers\CrowdStrike >> "%LOG_FILE%" 2>&1
    if %errorLevel% neq 0 (
        echo Failed to navigate to CrowdStrike directory. >> "%LOG_FILE%"
        echo Failed to navigate to CrowdStrike directory.
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

    rem Boot back into normal mode
    echo Configuring boot back to normal mode... >> "%LOG_FILE%"
    bcdedit /deletevalue {current} safeboot >> "%LOG_FILE%" 2>&1
    if %errorLevel% neq 0 (
        echo Failed to reset boot configuration. >> "%LOG_FILE%"
        echo Failed to reset boot configuration.
        pause
        exit /b 1
    )

    rem Resume BitLocker protection
    echo Resuming BitLocker protection... >> "%LOG_FILE%"
    manage-bde -protectors -enable %SystemDrive% >> "%LOG_FILE%" 2>&1
    if %errorLevel% neq 0 (
        echo Failed to resume BitLocker protection. >> "%LOG_FILE%"
        echo Failed to resume BitLocker protection.
        pause
        exit /b 1
    )

    rem Restart the system again
    echo Restarting the system again... >> "%LOG_FILE%"
    shutdown /r /t 0
    if %errorLevel% neq 0 (
        echo Failed to restart the system again. >> "%LOG_FILE%"
        echo Failed to restart the system again.
        pause
        exit /b 1
    )
) else (
    rem If we are not in Safe Mode, ensure we boot normally
    echo System is not in Safe Mode. Exiting... >> "%LOG_FILE%"
    bcdedit /deletevalue {current} safeboot >> "%LOG_FILE%" 2>&1
    manage-bde -protectors -enable %SystemDrive% >> "%LOG_FILE%" 2>&1
    if %errorLevel% neq 0 (
        echo Failed to resume BitLocker protection. >> "%LOG_FILE%"
        echo Failed to resume BitLocker protection.
        pause
        exit /b 1
    )
    pause
    exit /b 1
)

endlocal
