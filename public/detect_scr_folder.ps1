$folder = "C:\ProgramData\CompanyScreensaver"
$regPath = "HKCU:\Software\Microsoft\Windows Photo Viewer\Slideshow\Screensaver"

$ExpectedPIDL = "FAAf......"   

# 1. Check local folder
if (-not (Test-Path $folder)) {
    Write-Output "CompanyScreensaver folder does not exist."
    exit 1
}

# 2. Check registry key
if (-not (Test-Path $regPath)) {
    Write-Output "Screensaver registry key does not exist."
    exit 1
}

# 3. Read EncryptedPIDL
try {
    $CurrentPIDL = Get-ItemPropertyValue `
        -Path $regPath `
        -Name "EncryptedPIDL" `
        -ErrorAction Stop
}
catch {
    Write-Output "EncryptedPIDL does not exist."
    exit 1
}

# 4. Compare
if ($CurrentPIDL -ne $ExpectedPIDL) {
    Write-Output "EncryptedPIDL is incorrect."
    exit 1
}

Write-Output "EncryptedPIDL is correct."
exit 0
