@echo off
chcp 65001 >nul
setlocal EnableExtensions

rem ============================================================
rem SQL Training Lab Launcher
rem
rem First run:
rem   1. Create the local work folder
rem   2. Register the folder as an Access Trusted Location
rem   3. Copy the ACCDB to the local folder
rem   4. Open the local ACCDB
rem
rem Second and later runs:
rem   - If the local ACCDB already exists, open it immediately.
rem   - Do not write the registry again.
rem   - Do not copy the database again.
rem
rem PowerShell and certutil are not used.
rem ============================================================

set "SOURCE=%~dp0SQLTraining_Master.accdb"
set "WORKDIR=%LOCALAPPDATA%\ADS\SQLTraining"
set "TARGET=%WORKDIR%\SQLTraining.accdb"
set "TRUSTKEY=HKCU\Software\Microsoft\Office\16.0\Access\Security\Trusted Locations\Location99"

if exist "%TARGET%" goto OPEN_DATABASE

echo.
echo SQL Training Lab の初回セットアップを開始します。
echo.

if not exist "%SOURCE%" (
    echo [ERROR] 配布元のデータベースが見つかりません。
    echo.
    echo 対象:
    echo %SOURCE%
    echo.
    echo SQLTraining_Master.accdb とこのBATファイルを
    echo 同じフォルダーに置いてください。
    pause
    exit /b 1
)

if not exist "%WORKDIR%" (
    mkdir "%WORKDIR%" >nul 2>&1
)

if not exist "%WORKDIR%" (
    echo [ERROR] ローカルフォルダーを作成できませんでした。
    echo.
    echo 対象:
    echo %WORKDIR%
    pause
    exit /b 1
)

reg add "%TRUSTKEY%" ^
    /v Path ^
    /t REG_SZ ^
    /d "%WORKDIR%\" ^
    /f >nul 2>&1

if errorlevel 1 goto TRUST_ERROR

reg add "%TRUSTKEY%" ^
    /v AllowSubFolders ^
    /t REG_DWORD ^
    /d 0 ^
    /f >nul 2>&1

if errorlevel 1 goto TRUST_ERROR

reg add "%TRUSTKEY%" ^
    /v Description ^
    /t REG_SZ ^
    /d "ADS SQL Training Lab" ^
    /f >nul 2>&1

if errorlevel 1 goto TRUST_ERROR

echo 信頼できる場所の登録に成功しました。

copy /B /Y "%SOURCE%" "%TARGET%" >nul 2>&1

if errorlevel 1 (
    echo [ERROR] データベースをローカルへコピーできませんでした。
    echo.
    echo コピー元:
    echo %SOURCE%
    echo.
    echo コピー先:
    echo %TARGET%
    pause
    exit /b 1
)

if not exist "%TARGET%" (
    echo [ERROR] コピー後のデータベースを確認できませんでした。
    pause
    exit /b 1
)

echo データベースのコピーに成功しました。
echo.

goto OPEN_DATABASE

:OPEN_DATABASE

set "ACCESS_EXE="

if exist "%ProgramFiles%\Microsoft Office\root\Office16\MSACCESS.EXE" (
    set "ACCESS_EXE=%ProgramFiles%\Microsoft Office\root\Office16\MSACCESS.EXE"
)

if not defined ACCESS_EXE (
    if exist "%ProgramFiles(x86)%\Microsoft Office\root\Office16\MSACCESS.EXE" (
        set "ACCESS_EXE=%ProgramFiles(x86)%\Microsoft Office\root\Office16\MSACCESS.EXE"
    )
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
    echo [ERROR] Microsoft Access の実行ファイルが見つかりません。
    echo.
    echo Microsoft Access がインストールされているか確認してください。
    pause
    exit /b 1
)

if not exist "%TARGET%" (
    echo [ERROR] ローカルのデータベースが見つかりません。
    echo.
    echo 対象:
    echo %TARGET%
    pause
    exit /b 1
)

echo SQL Training Lab を起動します。
echo.
echo Database:
echo %TARGET%
echo.

start "" "%ACCESS_EXE%" "%TARGET%"

endlocal
exit /b 0

:TRUST_ERROR

echo [ERROR] Access の信頼できる場所を登録できませんでした。
echo.
echo 会社のセキュリティポリシーにより、
echo ユーザーによる登録が制限されている可能性があります。
echo.
echo 対象:
echo %WORKDIR%
echo.
echo データベースはまだコピーしていません。
pause

endlocal
exit /b 1
