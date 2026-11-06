Get-ItemProperty "HKCU:\Software\Microsoft\Windows Photo Viewer\Slideshow\Screensaver" | Format-List *

$ErrorActionPreference = "Stop"

$folder = "C:\ProgramData\CompanyScreensaver"

# Create folder
New-Item -Path $folder -ItemType Directory -Force | Out-Null

Write-Output "PSScriptRoot = $PSScriptRoot"

# Show package contents
Get-ChildItem $PSScriptRoot

# Verify files exist
if (-not (Test-Path "$PSScriptRoot\image1.jpg")) {
    Write-Error "image1.jpg not found."
    exit 1
}

if (-not (Test-Path "$PSScriptRoot\image2.jpg")) {
    Write-Error "image2.jpg not found."
    exit 1
}

# Copy images
Copy-Item "$PSScriptRoot\image1.jpg" "$folder\image1.jpg" -Force
Copy-Item "$PSScriptRoot\image2.jpg" "$folder\image2.jpg" -Force

# Registry
New-Item `
    -Path "HKLM:\SOFTWARE\CompanyScreensaver" `
    -Force | Out-Null

Set-ItemProperty `
    -Path "HKLM:\SOFTWARE\CompanyScreensaver" `
    -Name "Installed" `
    -Value "1"

Write-Output "Images deployed successfully."

exit 0




$ErrorActionPreference = "Stop"

# Folder containing deployed images
$folder = "C:\ProgramData\CompanyScreensaver"

# Verify folder exists
if (-not (Test-Path $folder)) {
    Write-Error "Screensaver image folder not found: $folder"
    exit 1
}

# Verify PhotoScreensaver exists
$scrFile = "C:\Windows\System32\PhotoScreensaver.scr"

if (-not (Test-Path $scrFile)) {
    Write-Error "PhotoScreensaver.scr not found."
    exit 1
}

# Configure screensaver executable
Set-ItemProperty `
    -Path "HKCU:\Control Panel\Desktop" `
    -Name "SCRNSAVE.EXE" `
    -Value $scrFile

# Create slideshow registry path
New-Item `
    -Path "HKCU:\Software\Microsoft\Windows Photo Viewer\Slideshow\Screensaver" `
    -Force | Out-Null

# Set image folder
Set-ItemProperty `
    -Path "HKCU:\Software\Microsoft\Windows Photo Viewer\Slideshow\Screensaver" `
    -Name "ImagesRootPath" `
    -Value $folder

# Refresh user desktop settings
rundll32.exe user32.dll, UpdatePerUserSystemParameters

Write-Output "Photo screensaver configured successfully."

exit 0

$ErrorActionPreference = "Stop"
$folder = "C:\ProgramData\CompanyScreensaver"

# Create folder
New-Item -Path $folder -ItemType Directory -Force | Out-Null
Write-Output "PSScriptRoot = $PSScriptRoot"

# Show package contents
Get-ChildItem $PSScriptRoot

# Verify file exists
if (-not (Test-Path "$PSScriptRoot\myscr.scr")) {
    Write-Error "myscr.scr not found."
    exit 1
}

# Copy scr file
Copy-Item "$PSScriptRoot\myscr.scr" "$folder\myscr.scr" -Force

# Registry
New-Item `
    -Path "HKLM:\SOFTWARE\CompanyScreensaver" `
    -Force | Out-Null
Set-ItemProperty `
    -Path "HKLM:\SOFTWARE\CompanyScreensaver" `
    -Name "Installed" `
    -Value "1"

Write-Output "Screensaver deployed successfully."
exit 0

$ErrorActionPreference = "Stop"
$folder = "C:\ProgramData\CompanyScreensaver"

# Remove scr file
if (Test-Path "$folder\myscr.scr") {
    Remove-Item "$folder\myscr.scr" -Force
    Write-Output "myscr.scr removed."
} else {
    Write-Output "myscr.scr not found, skipping."
}

# Remove folder if empty
if (Test-Path $folder) {
    $remaining = Get-ChildItem $folder
    if ($remaining.Count -eq 0) {
        Remove-Item $folder -Force
        Write-Output "Folder removed."
    } else {
        Write-Output "Folder not empty, skipping folder removal."
    }
}

# Remove registry key
if (Test-Path "HKLM:\SOFTWARE\CompanyScreensaver") {
    Remove-Item "HKLM:\SOFTWARE\CompanyScreensaver" -Recurse -Force
    Write-Output "Registry key removed."
} else {
    Write-Output "Registry key not found, skipping."
}

Write-Output "Uninstall completed."
exit 0


$features = @(
    "Microsoft-Windows-Subsystem-Linux",
    "VirtualMachinePlatform"
)

foreach ($feature in $features) {
    Get-WindowsOptionalFeature -Online -FeatureName $feature |
        Select-Object FeatureName, State
}


$ErrorActionPreference = "Stop"

$LogFolder = "$env:ProgramData\Company\WSL"
$LogFile = Join-Path $LogFolder "Enable-WSL2.log"

New-Item -Path $LogFolder -ItemType Directory -Force |
    Out-Null

function Write-Log {
    param([string]$Message)

    $Time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $LogFile -Value "[$Time] $Message"
}

try {
    $Features = @(
        "Microsoft-Windows-Subsystem-Linux",
        "VirtualMachinePlatform"
    )

    $RestartRequired = $false

    foreach ($Feature in $Features) {

        $Current = Get-WindowsOptionalFeature `
            -Online -FeatureName $Feature

        Write-Log "$Feature current state: $($Current.State)"

        if ($Current.State -eq "Enabled") {
            Write-Log "$Feature already enabled"
            continue
        }

        if ($Current.State -eq "EnablePending") {
            $RestartRequired = $true
            continue
        }

        $Result = Enable-WindowsOptionalFeature `
            -Online `
            -FeatureName $Feature `
            -All `
            -NoRestart

        if ($Result.RestartNeeded) {
            $RestartRequired = $true
        }

        $NewState = (Get-WindowsOptionalFeature `
            -Online -FeatureName $Feature).State

        Write-Log "$Feature new state: $NewState"
    }

    if ($RestartRequired) {
        Write-Log "Restart required."
    }
    else {
        Write-Log "No restart required."
    }

    exit 0
}
catch {
    Write-Log "ERROR: $($_.Exception.Message)"
    exit 1
}
