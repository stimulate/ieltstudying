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
