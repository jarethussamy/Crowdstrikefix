# Function to check if the script is running with administrative privileges
function Check-Admin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "This script must be run as an administrator." -ForegroundColor Red
        exit 1
    }
}

# Function to suspend BitLocker protection
function Suspend-BitLocker {
    try {
        manage-bde -protectors -disable $env:SystemDrive
    } catch {
        Write-Host "Failed to suspend BitLocker protection." -ForegroundColor Red
        exit 1
    }
}

# Function to resume BitLocker protection
function Resume-BitLocker {
    try {
        manage-bde -protectors -enable $env:SystemDrive
    } catch {
        Write-Host "Failed to resume BitLocker protection." -ForegroundColor Red
        exit 1
    }
}

# Function to set Safe Mode with Networking
function Set-SafeMode {
    bcdedit /set {current} safeboot network
}

# Function to delete Safe Mode settings
function Delete-SafeMode {
    bcdedit /deletevalue {current} safeboot
}

# Function to schedule the script to run at system startup
function Schedule-Task {
    $scriptPath = $MyInvocation.MyCommand.Definition
    schtasks /create /tn "BootAndCleanup" /tr "powershell.exe -File `"$scriptPath`" -run" /sc onstart /f
}

# Function to restart the system
function Restart-System {
    shutdown /r /t 0
}

# Function to show a confirmation dialog
function Show-Confirmation {
    param ([string]$message)
    Add-Type -AssemblyName PresentationCore,PresentationFramework
    [System.Windows.MessageBox]::Show($message, "Confirmation", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
}

# Function to delete matching files in the CrowdStrike directory
function Delete-Files {
    $crowdStrikeDir = Join-Path $env:windir "System32\drivers\CrowdStrike"
    $files = Get-ChildItem -Path $crowdStrikeDir -Filter "C-00000291*.sys"
    $fileDeleted = $false

    foreach ($file in $files) {
        try {
            Remove-Item -Path $file.FullName -Force
            $fileDeleted = $true
        } catch {
            Write-Host "Failed to delete file: $($file.FullName)" -ForegroundColor Red
        }
    }

    if ($fileDeleted) {
        Show-Confirmation "File(s) deleted successfully."
    } else {
        Show-Confirmation "No matching file found to delete."
    }
}

# Function to check if the system is in Safe Mode
function Check-SafeMode {
    $output = bcdedit /enum {current}
    return $output -match "safeboot"
}

# Main script logic
Check-Admin

if ($args -contains "-run") {
    Start-Sleep -Seconds 60
    if (Check-SafeMode) {
        Delete-Files
        Delete-SafeMode
        Resume-BitLocker
        Restart-System
    } else {
        Write-Host "The system is not in Safe Mode. Exiting..." -ForegroundColor Red
        Delete-SafeMode
        Resume-BitLocker
        exit 1
    }
} else {
    Suspend-BitLocker
    Set-SafeMode
    Schedule-Task
    Restart-System
}
