@echo off
setlocal

rem ==================================================
rem SQL Training Lab launcher
rem 1. Copy ACCDB to local folder
rem 2. Register local folder as Access Trusted Location
rem 3. Start Microsoft Access explicitly
rem ==================================================

set "SOURCE=%~dp0SQLTraining_v1.0.accdb"
set "WORKDIR=%LOCALAPPDATA%\ADS\SQLTraining"
set "TARGET=%WORKDIR%\SQLTraining.accdb"

rem Office / Microsoft 365 uses version 16.0
rem If Location99 is already used, change it to another unused number.
set "TRUSTKEY=HKCU\Software\Microsoft\Office\16.0\Access\Security\Trusted Locations\Location99"

echo.
echo SQL Training Labを準備しています...
echo.

rem ----- Check source file -----
if not exist "%SOURCE%" (
    echo ERROR:
    echo 次のファイルが見つかりません。
    echo %SOURCE%
    echo.
    echo ACCDBとCMDを同じフォルダーに置いてください。
    pause
    exit /b 1
)

rem ----- Create local working folder -----
if not exist "%WORKDIR%" (
    mkdir "%WORKDIR%"
)

if not exist "%WORKDIR%" (
    echo ERROR:
    echo ローカルフォルダーを作成できませんでした。
    echo %WORKDIR%
    pause
    exit /b 1
)

rem ----- Copy database to local folder -----
copy /B /Y "%SOURCE%" "%TARGET%" >nul

if errorlevel 1 (
    echo ERROR:
    echo データベースをローカルへコピーできませんでした。
    pause
    exit /b 1
)

if not exist "%TARGET%" (
    echo ERROR:
    echo コピー後のデータベースが見つかりません。
    pause
    exit /b 1
)

echo データベースのコピー：成功
echo %TARGET%
echo.

rem ----- Add Access Trusted Location -----
reg add "%TRUSTKEY%" ^
    /v Path ^
    /t REG_SZ ^
    /d "%WORKDIR%\" ^
    /f >nul 2>&1

if errorlevel 1 goto TrustError

reg add "%TRUSTKEY%" ^
    /v AllowSubFolders ^
    /t REG_DWORD ^
    /d 0 ^
    /f >nul 2>&1

if errorlevel 1 goto TrustError

reg add "%TRUSTKEY%" ^
    /v Description ^
    /t REG_SZ ^
    /d "ADS SQL Training Lab" ^
    /f >nul 2>&1

if errorlevel 1 goto TrustError

echo 信頼できる場所の登録：成功
echo %WORKDIR%
echo.

rem ----- Find Microsoft Access -----
set "ACCESS_EXE="

if exist "%ProgramFiles%\Microsoft Office\root\Office16\MSACCESS.EXE" (
    set "ACCESS_EXE=%ProgramFiles%\Microsoft Office\root\Office16\MSACCESS.EXE"
)

if exist "%ProgramFiles(x86)%\Microsoft Office\root\Office16\MSACCESS.EXE" (
    set "ACCESS_EXE=%ProgramFiles(x86)%\Microsoft Office\root\Office16\MSACCESS.EXE"
)

if not defined ACCESS_EXE (
    if exist "%ProgramFiles%\Microsoft Office\Office16\MSACCESS.EXE" (
        set "ACCESS_EXE=%ProgramFiles%\Microsoft Office\Office16\MSACCESS.EXE"
    )
)

if not defined ACCESS_EXE (
    if exist "%ProgramFiles(x86)%\Microsoft Office\Office16\MSACCESS.EXE" (
        set "ACCESS_EXE=%ProgramFiles(x86)%\Microsoft Office\Office16\MSACCESS.EXE"
    )
)

if not defined ACCESS_EXE (
    echo ERROR:
    echo Microsoft Accessの実行ファイルが見つかりません。
    echo IT管理者にAccessのインストール状況を確認してください。
    pause
    exit /b 1
)

echo Microsoft Accessを起動します。
echo.

start "" "%ACCESS_EXE%" "%TARGET%"

endlocal
exit /b 0

:TrustError
echo ERROR:
echo 信頼できる場所を登録できませんでした。
echo 会社のOfficeポリシーで設定が制限されている可能性があります。
echo.
echo 対象フォルダー:
echo %WORKDIR%
pause
exit /b 1
