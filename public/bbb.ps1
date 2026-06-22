$ErrorActionPreference = "Stop"

$folder = "C:\ProgramData\CompanyScreensaver"

# Create destination folder
New-Item -Path $folder -ItemType Directory -Force | Out-Null

Write-Output "PSScriptRoot = $PSScriptRoot"

# Supported image extensions
$imageExtensions = @("*.jpg","*.jpeg","*.png","*.bmp","*.gif","*.webp")

# Remove existing images in destination folder
foreach ($extension in $imageExtensions) {
    Get-ChildItem -Path $folder -Filter $extension -File -ErrorAction SilentlyContinue |
        Remove-Item -Force
}

# Get all image files from the package
$imageFiles = foreach ($extension in $imageExtensions) {
    Get-ChildItem -Path $PSScriptRoot -Filter $extension -File -ErrorAction SilentlyContinue
}

if (-not $imageFiles) {
    Write-Error "No image files were found in the package."
    exit 1
}

# Copy all images
foreach ($image in $imageFiles) {
    Copy-Item -Path $image.FullName -Destination $folder -Force
    Write-Output "Copied $($image.Name)"
}

Write-Output "Successfully deployed $($imageFiles.Count) image(s)."

exit 0

Package
│
├── Install.ps1
├── image1.jpg
├── image2.jpg
├── image3.png
├── company.webp
└── wallpaper.bmp
