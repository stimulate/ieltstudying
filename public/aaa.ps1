$tenantId     = "your-tenant-id"
$clientId     = "your-client-id"
$clientSecret = "your-client-secret"

# 获取 token
$tokenBody = @{
    grant_type    = "client_credentials"
    scope         = "https://graph.microsoft.com/.default"
    client_id     = $clientId
    client_secret = $clientSecret
}
$token = (Invoke-RestMethod `
    -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" `
    -Method Post `
    -Body $tokenBody).access_token

$headers = @{ Authorization = "Bearer $token" }

# 获取 Site ID（把 yourcompany 和 yoursite 换成实际值）
Invoke-RestMethod `
    -Uri "https://graph.microsoft.com/v1.0/sites/yourcompany.sharepoint.com:/sites/yoursite" `
    -Headers $headers | Select-Object id, displayName

$folder       = "C:\ProgramData\CompanyScreensaver"
$logFile      = "C:\Windows\Temp\screensaver_remediate.log"
$tenantId     = "your-tenant-id"
$clientId     = "your-client-id"
$clientSecret = "your-client-secret"
$siteId       = "your-site-id"
$folderPath   = "Shared Documents/Screensaver"  # SharePoint 里的文件夹路径

function Write-Log($msg) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $msg" | Out-File $logFile -Append
    Write-Output "$timestamp - $msg"
}

Write-Log "=== Remediation Started ==="

try {
    # 获取 token
    $tokenBody = @{
        grant_type    = "client_credentials"
        scope         = "https://graph.microsoft.com/.default"
        client_id     = $clientId
        client_secret = $clientSecret
    }
    $token = (Invoke-RestMethod `
        -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" `
        -Method Post `
        -Body $tokenBody).access_token
    $headers = @{ Authorization = "Bearer $token" }
    Write-Log "Token acquired"

    # 获取文件夹内所有文件
    $uri   = "https://graph.microsoft.com/v1.0/sites/$siteId/drive/root:/$folderPath`:/children"
    $files = (Invoke-RestMethod -Uri $uri -Headers $headers).value |
             Where-Object { $_.file -ne $null } |
             Sort-Object name
    Write-Log "Files found: $($files.Count)"

    # 清空旧图
    New-Item -Path $folder -ItemType Directory -Force | Out-Null
    Get-ChildItem -Path $folder -Include "*.jpg","*.png","*.jpeg" -Recurse | Remove-Item -Force
    Write-Log "Old images cleared"

    # 下载新图
    foreach ($file in $files) {
        $downloadUrl = $file."@microsoft.graph.downloadUrl"
        $destPath    = "$folder\$($file.name)"
        Invoke-WebRequest -Uri $downloadUrl -OutFile $destPath -UseBasicParsing
        Write-Log "Downloaded: $($file.name)"
    }

    Write-Log "=== Remediation Completed ==="
    exit 0
} catch {
    Write-Log "=== FATAL ERROR: $_ ==="
    exit 1
}

$folderPath = "Shared Documents/02. 运用"

Invoke-RestMethod `
    -Uri "https://graph.microsoft.com/v1.0/sites/$siteId/drive/root:/$folderPath" `
    -Headers $headers | Select-Object id, name, webUrl
