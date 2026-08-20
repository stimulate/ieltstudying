$ErrorActionPreference = "Stop"

$folder = "C:\ProgramData\CompanyScreensaver"
$regPath = "HKCU:\Software\Microsoft\Windows Photo Viewer\Slideshow\Screensaver"

$ExpectedPIDL = "FAAf......"   

# Do not configure until local folder exists
if (-not (Test-Path $folder)) {
    Write-Error "CompanyScreensaver folder does not exist."
    exit 1
}

# Create registry key if missing
New-Item `
    -Path $regPath `
    -Force |
    Out-Null

# Create or overwrite EncryptedPIDL as REG_SZ
New-ItemProperty `
    -Path $regPath `
    -Name "EncryptedPIDL" `
    -PropertyType String `
    -Value $ExpectedPIDL `
    -Force |
    Out-Null

# Verify
$CurrentPIDL = Get-ItemPropertyValue `
    -Path $regPath `
    -Name "EncryptedPIDL"

if ($CurrentPIDL -ne $ExpectedPIDL) {
    Write-Error "EncryptedPIDL verification failed."
    exit 1
}

Write-Output "EncryptedPIDL repaired successfully."
exit 0
