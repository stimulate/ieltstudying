$folder = "C:\ProgramData\CompanyScreensaver"
New-Item -Path $folder -ItemType Directory -Force | Out-Null
Copy-Item ".\images\*.jpg" -Destination $folder -Force

# 设置 NTFS 权限,禁止普通用户修改/删除
$acl = Get-Acl $folder
$acl.SetAccessRuleProtection($true, $false)
$adminRule = New-Object System.Security.AccessControl.FileSystemAccessRule("BUILTIN\Administrators","FullControl","ContainerInherit,ObjectInherit","None","Allow")
$systemRule = New-Object System.Security.AccessControl.FileSystemAccessRule("NT AUTHORITY\SYSTEM","FullControl","ContainerInherit,ObjectInherit","None","Allow")
$usersRule = New-Object System.Security.AccessControl.FileSystemAccessRule("BUILTIN\Users","ReadAndExecute","ContainerInherit,ObjectInherit","None","Allow")
$acl.SetAccessRule($adminRule)
$acl.SetAccessRule($systemRule)
$acl.SetAccessRule($usersRule)
Set-Acl -Path $folder -AclObject $acl

$path = "HKCU:\Software\Microsoft\Windows Photo Viewer\Slideshow\Screensaver"
$expected = "OgAfSFMW3Toy67BMu9ffoKu1rMomAAEAJgDvvhEAAADWnkA/p7..."  # 替换为完整的84字符字符串

if (-not (Test-Path $path)) {
    New-Item -Path $path -Force | Out-Null
}

Set-ItemProperty -Path $path -Name "EncryptedPIDL" -Value $expected -Type String

------

$PythonExe = "$env:LOCALAPPDATA\Programs\Python\Python314\python.exe"
$ExpectedVersion = "3.14.7"

if (Test-Path $PythonExe) {
    $ActualVersion = & $PythonExe -c "import sys; print('.'.join(map(str, sys.version_info[:3])))" 2>$null

    if ($ActualVersion -eq $ExpectedVersion) {
        Write-Output "Python $ActualVersion detected"
        exit 0
    }
}

exit 1
