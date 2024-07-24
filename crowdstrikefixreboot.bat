
@echo off
setlocal

rem Check if running as administrator
net session >nul 2>&1
if %errorlevel% neq 0 (
  echo This script must be run as an administrator.
  pause
  exit /b 1
)

rem Boot into Safe Mode with Networking
bcdedit /set {current} safeboot network

rem Restart the system
shutdown /r /t 0
timeout /t 60 /nobreak

rem Ensure that we are now in Safe Mode
:SafeMode
rem Check if we are in Safe Mode with Networking
if /i "%SAFEBOOT_OPTION%"=="network" (
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
  
  rem Confirmation message with choice
  if "%fileDeleted%" == "true" (
    echo File(s) deleted successfully.
  ) else (
    echo No matching file found to delete.
  )
  
  choice /c YN /m Do you want to reboot to normal mode? && (
    bcdedit /deletevalue {current} safeboot
    shutdown /r /t 0
  )
)

endlocal
