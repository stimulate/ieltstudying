@echo on
setlocal EnableExtensions

set "SOURCE=%~dp0SQLTraining_v1.0.accdb"
set "WORKDIR=%LOCALAPPDATA%\ADS\SQLTraining"
set "TARGET=%WORKDIR%\SQLTraining.accdb"
set "LOG=%USERPROFILE%\Desktop\SQLTraining_Launch_Debug.log"

> "%LOG%" echo ===== SQL Training Launch Debug =====
>>"%LOG%" echo Date: %date% %time%
>>"%LOG%" echo Script: %~f0
>>"%LOG%" echo Source: %SOURCE%
>>"%LOG%" echo WorkDir: %WORKDIR%
>>"%LOG%" echo Target: %TARGET%
>>"%LOG%" echo.

echo STEP 1: Check source
if not exist "%SOURCE%" (
    echo ERROR: Source file not found.
    >>"%LOG%" echo ERROR: Source file not found.
    pause
    exit /b 1
)

echo STEP 2: Create work directory
if not exist "%WORKDIR%" mkdir "%WORKDIR%" >>"%LOG%" 2>&1
if not exist "%WORKDIR%" (
    echo ERROR: Could not create work directory.
    >>"%LOG%" echo ERROR: Could not create work directory.
    pause
    exit /b 1
)

echo STEP 3: Copy database
copy /B /Y "%SOURCE%" "%TARGET%" >>"%LOG%" 2>&1
set "COPY_RC=%ERRORLEVEL%"
>>"%LOG%" echo Copy exit code: %COPY_RC%

if not "%COPY_RC%"=="0" (
    echo ERROR: Copy failed. Exit code %COPY_RC%
    pause
    exit /b 1
)

if not exist "%TARGET%" (
    echo ERROR: Target file is missing after copy.
    >>"%LOG%" echo ERROR: Target file is missing after copy.
    pause
    exit /b 1
)

echo STEP 4: Find MSACCESS.EXE
set "ACCESS_EXE="

for /f "tokens=2,*" %%A in ('reg query "HKLM\Software\Microsoft\Windows\CurrentVersion\App Paths\MSACCESS.EXE" /ve 2^>nul ^| findstr /i "REG_SZ"') do set "ACCESS_EXE=%%B"

if not defined ACCESS_EXE (
    for /f "tokens=2,*" %%A in ('reg query "HKLM\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\App Paths\MSACCESS.EXE" /ve 2^>nul ^| findstr /i "REG_SZ"') do set "ACCESS_EXE=%%B"
)

if not defined ACCESS_EXE if exist "%ProgramFiles%\Microsoft Office\root\Office16\MSACCESS.EXE" set "ACCESS_EXE=%ProgramFiles%\Microsoft Office\root\Office16\MSACCESS.EXE"
if not defined ACCESS_EXE if exist "%ProgramFiles(x86)%\Microsoft Office\root\Office16\MSACCESS.EXE" set "ACCESS_EXE=%ProgramFiles(x86)%\Microsoft Office\root\Office16\MSACCESS.EXE"
if not defined ACCESS_EXE if exist "%ProgramFiles%\Microsoft Office\Office16\MSACCESS.EXE" set "ACCESS_EXE=%ProgramFiles%\Microsoft Office\Office16\MSACCESS.EXE"
if not defined ACCESS_EXE if exist "%ProgramFiles(x86)%\Microsoft Office\Office16\MSACCESS.EXE" set "ACCESS_EXE=%ProgramFiles(x86)%\Microsoft Office\Office16\MSACCESS.EXE"

>>"%LOG%" echo AccessExe: %ACCESS_EXE%

if not defined ACCESS_EXE (
    echo ERROR: MSACCESS.EXE was not found.
    >>"%LOG%" echo ERROR: MSACCESS.EXE was not found.
    >>"%LOG%" echo Searching common folders:
    where /r "%ProgramFiles%" MSACCESS.EXE >>"%LOG%" 2>&1
    if exist "%ProgramFiles(x86)%" where /r "%ProgramFiles(x86)%" MSACCESS.EXE >>"%LOG%" 2>&1
    echo See log on Desktop:
    echo %LOG%
    pause
    exit /b 1
)

if not exist "%ACCESS_EXE%" (
    echo ERROR: Detected Access path does not exist.
    >>"%LOG%" echo ERROR: Detected Access path does not exist.
    echo %ACCESS_EXE%
    pause
    exit /b 1
)

echo STEP 5: Launch Access
echo Access: %ACCESS_EXE%
echo Database: %TARGET%
>>"%LOG%" echo Launch command: "%ACCESS_EXE%" "%TARGET%"

start "" /wait "%ACCESS_EXE%" "%TARGET%"
set "ACCESS_RC=%ERRORLEVEL%"

>>"%LOG%" echo Access exit code: %ACCESS_RC%
>>"%LOG%" echo Finished: %date% %time%

echo.
echo Access returned exit code: %ACCESS_RC%
echo Log file:
echo %LOG%
pause

endlocal
