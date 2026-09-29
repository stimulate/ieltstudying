$ErrorActionPreference = "Stop"

# Rancher Desktop MSI
$MsiName = "Rancher.Desktop.Setup.x.x.x.msi"
$MsiPath = Join-Path $PSScriptRoot $MsiName

# Check MSI
if (-not (Test-Path $MsiPath)) {
    Write-Error "Rancher Desktop MSI not found: $MsiPath"
    exit 1
}

# Check WSL
try {
    $WslVersion = & wsl.exe --version 2>&1
}
catch {
    Write-Error "WSL is not available."
    exit 1
}

if (-not $WslVersion) {
    Write-Error "WSL is not available."
    exit 1
}

Write-Output "WSL detected."

# Make sure an old privileged service does not already exist
$PrivilegedService = Get-Service `
    -Name "RancherDesktopPrivilegedService" `
    -ErrorAction SilentlyContinue

if ($null -ne $PrivilegedService) {
    Write-Error "Rancher Desktop Privileged Service already exists. Remove the previous machine-wide installation first."
    exit 1
}

# Install Rancher Desktop for current user
$Arguments = "/i `"$MsiPath`" ALLUSERS=2 MSIINSTALLPERUSER=1 /qn /norestart"

$Process = Start-Process `
    -FilePath "msiexec.exe" `
    -ArgumentList $Arguments `
    -Wait `
    -PassThru

Write-Output "MSI Exit Code: $($Process.ExitCode)"

if ($Process.ExitCode -eq 3010) {
    exit 3010
}

if ($Process.ExitCode -ne 0) {
    Write-Error "Rancher Desktop installation failed."
    exit $Process.ExitCode
}

exit 0

$ErrorActionPreference = "Stop"

$UninstallPaths = @(
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKCU:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

$Rancher = Get-ItemProperty `
    -Path $UninstallPaths `
    -ErrorAction SilentlyContinue |
    Where-Object {
        $_.DisplayName -like "Rancher Desktop*"
    } |
    Select-Object -First 1

if ($null -eq $Rancher) {
    Write-Output "Rancher Desktop is not installed."
    exit 0
}

$ProductCode = $Rancher.PSChildName

if ($ProductCode -match "^\{.*\}$") {

    $Process = Start-Process `
        -FilePath "msiexec.exe" `
        -ArgumentList "/x $ProductCode /qn /norestart" `
        -Wait `
        -PassThru

    if ($Process.ExitCode -eq 3010) {
        exit 3010
    }

    exit $Process.ExitCode
}

Write-Error "Unable to determine Rancher Desktop MSI ProductCode."
exit 1


$UninstallPaths = @(
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKCU:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

$Rancher = Get-ItemProperty `
    -Path $UninstallPaths `
    -ErrorAction SilentlyContinue |
    Where-Object {
        $_.DisplayName -like "Rancher Desktop*"
    } |
    Select-Object -First 1

if ($null -ne $Rancher) {

    # Make sure privileged service is NOT installed
    $Service = Get-Service `
        -Name "RancherDesktopPrivilegedService" `
        -ErrorAction SilentlyContinue

    if ($null -eq $Service) {
        Write-Output "Rancher Desktop per-user installation detected."
        exit 0
    }
}

exit 1
