# 一次性设置 - 在用户登录时运行 (Intune > Scripts > 不勾选 "以系统权限运行"，使用用户上下文)

$path = "HKCU:\Software\Microsoft\Windows Photo Viewer\Slideshow\Screensaver"
$expected = [byte[]]@(0x.., 0x.., ...)  # 替换为你导出的 EncryptedPIDL 字节

if (-not (Test-Path $path)) {
    New-Item -Path $path -Force | Out-Null
}

Set-ItemProperty -Path $path -Name "EncryptedPIDL" -Value $expected -Type Binary

# 设置屏保程序与超时（如果GPO未覆盖）
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "SCRNSAVE.EXE" -Value "C:\Windows\System32\PhotoScreensaver.scr" -Type String
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "ScreenSaveActive" -Value "1" -Type String
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "ScreenSaveTimeOut" -Value "600" -Type String
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "ScreenSaverIsSecure" -Value "1" -Type String

exit 0

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


$bytes = (Get-ItemProperty "HKCU:\Software\Microsoft\Windows Photo Viewer\Slideshow\Screensaver" -Name EncryptedPIDL).EncryptedPIDL

$item = Get-Item "HKCU:\Software\Microsoft\Windows Photo Viewer\Slideshow\Screensaver"
$item.GetValueKind("EncryptedPIDL")
[System.IO.File]::WriteAllText("C:\temp\pidl.txt", $value)

$value = (Get-ItemProperty "HKCU:\Software\Microsoft\Windows Photo Viewer\Slideshow\Screensaver" -Name EncryptedPIDL).EncryptedPIDL

# 把每个字符的 ASCII 码打印出来看看是什么
$value.ToCharArray() | ForEach-Object { [int]$_ } | Select-Object -First 50

# 检查是否有 NUL
$value.Contains([char]0)

$value = (Get-ItemProperty "HKCU:\Software\Microsoft\Windows Photo Viewer\Slideshow\Screensaver" -Name EncryptedPIDL).EncryptedPIDL

# 看前100个字符的原始内容（用十六进制查看）
$bytes = [System.Text.Encoding]::Unicode.GetBytes($value)
$bytes[0..100] | ForEach-Object { "{0:X2}" -f $_ }

$value = (Get-ItemProperty "HKCU:\Software\Microsoft\Windows Photo Viewer\Slideshow\Screensaver" -Name EncryptedPIDL).EncryptedPIDL

"长度: $($value.Length)"
"类型: $($value.GetType().FullName)"
"前50字符: $($value.Substring(0, [Math]::Min(50,$value.Length)))"
"是否含有逗号: $($value.Contains(','))"
"是否含有空格: $($value.Contains(' '))"
