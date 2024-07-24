@echo off
setlocal

rem Check if running as administrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo This script must be run as an administrator.
    pause
    exit /b 1
)

rem If the script is running with the -run parameter, proceed with the cleanup
if "%1" == "-run" goto :RunScript

rem Suspend BitLocker on the system drive
manage-bde -protectors -disable %SystemDrive%
if %errorLevel% neq 0 (
    echo Failed to suspend BitLocker protection.
    pause
    exit /b 1
)

rem Boot into Safe Mode with Networking
bcdedit /set {current} safeboot network

rem Create a scheduled task to run this script after user logon in Safe Mode
schtasks /create /tn BootAndCleanup /tr "\"%~dpnx0\" -run" /sc onstart /f

rem Restart the system
shutdown /r /t 0
exit /b 0

:RunScript
rem Wait for the system to restart
timeout /t 60 /nobreak

rem After reboot, we should be in Safe Mode
rem Check if we are in Safe Mode
echo Checking Safe Mode status...
for /f "tokens=2 delims=[]" %%i in ('bcdedit /enum {current} ^| findstr /r /c:"safeboot"') do set "SAFEBOOT_OPTION=%%i"
if /i "%SAFEBOOT_OPTION%"=="network" (
    echo System is in Safe Mode with Networking

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
        powershell -command "Add-Type -AssemblyName PresentationCore,PresentationFramework;[System.Windows.MessageBox]::Show('File(s) deleted successfully.', 'Confirmation')"
    ) else (
        powershell -command "Add-Type -AssemblyName PresentationCore,PresentationFramework;[System.Windows.MessageBox]::Show('No matching file found to delete.', 'Confirmation')"
    )

    rem Boot back into normal mode
    bcdedit /deletevalue {current} safeboot

    rem Resume BitLocker protection
    manage-bde -protectors -enable %SystemDrive%
    if %errorLevel% neq 0 (
        echo Failed to resume BitLocker protection.
        pause
        exit /b 1
    )

    rem Restart the system again
    shutdown /r /t 0
    exit /b 0
) else (
    rem If we are not in Safe Mode, ensure we boot normally
    echo System is not in Safe Mode. Exiting...
    bcdedit /deletevalue {current} safeboot

    rem Resume BitLocker protection
    manage-bde -protectors -enable %SystemDrive%
    if %errorLevel% neq 0 (
        echo Failed to resume BitLocker protection.
        pause
        exit /b 1
    )

    pause
    exit /b 1
)

endlocal
