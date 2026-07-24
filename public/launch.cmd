@echo off
setlocal EnableExtensions
chcp 65001 >nul

set "SOURCE=%~dp0SQLTraining_v1.0.accdb"
set "WORKDIR=%LOCALAPPDATA%\ADS\SQLTraining"
set "TARGET=%WORKDIR%\SQLTraining.accdb"
set "LOGFILE=%TEMP%\SQLTraining_Launch.log"
set "TRUSTKEY=HKCU\Software\Microsoft\Office\16.0\Access\Security\Trusted Locations\Location99"

> "%LOGFILE%" echo [%date% %time%] Launch started

echo.
echo [1/5] 配布元ファイルを確認しています...
if not exist "%SOURCE%" (
    echo ERROR: 次のACCDBが見つかりません。
    echo %SOURCE%
    pause
    exit /b 1
)
echo OK

echo.
echo [2/5] ローカルへコピーしています...
if not exist "%WORKDIR%" mkdir "%WORKDIR%" >>"%LOGFILE%" 2>&1
copy /B /Y "%SOURCE%" "%TARGET%" >>"%LOGFILE%" 2>&1

if not exist "%TARGET%" (
    echo ERROR: コピー後のACCDBが見つかりません。
    echo %TARGET%
    pause
    exit /b 1
)
echo OK
echo %TARGET%

echo.
echo [3/5] 信頼できる場所を登録しています...
reg add "%TRUSTKEY%" /v Path /t REG_SZ /d "%WORKDIR%\" /f >>"%LOGFILE%" 2>&1
set "TRUST_RC=%ERRORLEVEL%"
reg add "%TRUSTKEY%" /v AllowSubFolders /t REG_DWORD /d 0 /f >>"%LOGFILE%" 2>&1
if errorlevel 1 set "TRUST_RC=1"
reg add "%TRUSTKEY%" /v Description /t REG_SZ /d "ADS SQL Training Lab" /f >>"%LOGFILE%" 2>&1
if errorlevel 1 set "TRUST_RC=1"

if "%TRUST_RC%"=="0" (
    echo OK
) else (
    echo WARNING: 登録できませんでしたが、起動処理は継続します。
)

echo.
echo [4/5] Microsoft Accessを検索しています...
set "ACCESS_EXE="

for /f "tokens=2,*" %%A in ('reg query "HKLM\Software\Microsoft\Windows\CurrentVersion\App Paths\MSACCESS.EXE" /ve 2^>nul ^| findstr /i "REG_SZ"') do set "ACCESS_EXE=%%B"

if not defined ACCESS_EXE (
    for /f "tokens=2,*" %%A in ('reg query "HKLM\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\App Paths\MSACCESS.EXE" /ve 2^>nul ^| findstr /i "REG_SZ"') do set "ACCESS_EXE=%%B"
)

if not defined ACCESS_EXE if exist "%ProgramFiles%\Microsoft Office\root\Office16\MSACCESS.EXE" set "ACCESS_EXE=%ProgramFiles%\Microsoft Office\root\Office16\MSACCESS.EXE"
if not defined ACCESS_EXE if exist "%ProgramFiles(x86)%\Microsoft Office\root\Office16\MSACCESS.EXE" set "ACCESS_EXE=%ProgramFiles(x86)%\Microsoft Office\root\Office16\MSACCESS.EXE"
if not defined ACCESS_EXE if exist "%ProgramFiles%\Microsoft Office\Office16\MSACCESS.EXE" set "ACCESS_EXE=%ProgramFiles%\Microsoft Office\Office16\MSACCESS.EXE"
if not defined ACCESS_EXE if exist "%ProgramFiles(x86)%\Microsoft Office\Office16\MSACCESS.EXE" set "ACCESS_EXE=%ProgramFiles(x86)%\Microsoft Office\Office16\MSACCESS.EXE"

if not defined ACCESS_EXE (
    echo ERROR: MSACCESS.EXEを見つけられませんでした。
    echo 手動で次のファイルを開けるか確認してください。
    echo %TARGET%
    echo ログ: %LOGFILE%
    pause
    exit /b 1
)

if not exist "%ACCESS_EXE%" (
    echo ERROR: 検出したAccessのパスが存在しません。
    echo %ACCESS_EXE%
    pause
    exit /b 1
)

echo OK
echo %ACCESS_EXE%
echo ACCESS_EXE=%ACCESS_EXE%>>"%LOGFILE%"

echo.
echo [5/5] SQL Training Labを起動します...
echo Accessを閉じるまで、この画面は開いたままになります。
echo.

"%ACCESS_EXE%" "%TARGET%"
set "RC=%ERRORLEVEL%"

echo.
echo Accessの処理が終了しました。Exit code: %RC%
echo ExitCode=%RC%>>"%LOGFILE%"
echo ログ: %LOGFILE%
pause

endlocal
