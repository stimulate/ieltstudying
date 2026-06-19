$folder = "C:\ProgramData\CompanyScreensaver"
$manifestUrl = "https://yourcompany.sharepoint.com/.../manifest.json"

try {
    # 确保文件夹存在
    New-Item -Path $folder -ItemType Directory -Force | Out-Null

    # 拉取清单
    $manifest = Invoke-RestMethod -Uri $manifestUrl -UseBasicParsing

    # 清空旧图
    Get-ChildItem -Path $folder -Include "*.jpg","*.png","*.jpeg" -Recurse | Remove-Item -Force

    # 下载新图
    foreach ($img in $manifest) {
        Invoke-WebRequest -Uri $img.url -OutFile "$folder\$($img.name)" -UseBasicParsing
        Write-Output "Downloaded: $($img.name)"
    }

    exit 0
} catch {
    Write-Output "Error: $_"
    exit 1
}