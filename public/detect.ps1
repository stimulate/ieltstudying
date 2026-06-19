$folder = "C:\ProgramData\CompanyScreensaver"
$manifestUrl = "https://yourcompany.sharepoint.com/.../manifest.json"

try {
    # 拉取 SharePoint 上的清单
    $manifest = Invoke-RestMethod -Uri $manifestUrl -UseBasicParsing

    foreach ($img in $manifest) {
        $localPath = "$folder\$($img.name)"
        if (-not (Test-Path $localPath)) {
            Write-Output "Missing: $($img.name)"
            exit 1  # 触发 Remediation
        }
    }

    # 检查本地是否有多余的旧图
    $localFiles = Get-ChildItem -Path $folder -Include "*.jpg","*.png","*.jpeg" -Recurse
    if ($localFiles.Count -ne $manifest.Count) {
        Write-Output "File count mismatch"
        exit 1  # 触发 Remediation
    }

    Write-Output "OK"
    exit 0  # 无需修复
} catch {
    Write-Output "Error: $_"
    exit 1
}