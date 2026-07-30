@echo off
setlocal EnableExtensions DisableDelayedExpansion

set "LOG=%USERPROFILE%\Desktop\SQLTraining_Diagnostic.txt"
set "TESTKEY=HKCU\Software\ADS\SQLTrainingDiagnostic"
set "WORKDIR=%LOCALAPPDATA%\ADS\SQLTraining"
set "TRUSTROOT=HKCU\Software\Microsoft\Office\16.0\Access\Security\Trusted Locations"
set "TESTJS=%TEMP%\SQLTraining_CScript_Test_%RANDOM%_%RANDOM%.js"

> "%LOG%" echo SQL Training Environment Diagnostic
>>"%LOG%" echo Date: %DATE% %TIME%
>>"%LOG%" echo Computer: %COMPUTERNAME%
>>"%LOG%" echo User: %USERNAME%
>>"%LOG%" echo.

echo [1/7] Checking Microsoft Access process...
>>"%LOG%" echo ==== 1. MSACCESS process ====
tasklist /FI "IMAGENAME eq MSACCESS.EXE" >>"%LOG%" 2>&1
>>"%LOG%" echo.

echo [2/7] Checking local SQL Training folder...
>>"%LOG%" echo ==== 2. Local work folder ====
if exist "%WORKDIR%" (
    dir /a "%WORKDIR%" >>"%LOG%" 2>&1
) else (
    >>"%LOG%" echo NOT FOUND: %WORKDIR%
)
>>"%LOG%" echo.

echo [3/7] Reading Access Trusted Locations...
>>"%LOG%" echo ==== 3. Access Trusted Locations ====
reg query "%TRUSTROOT%" /s >>"%LOG%" 2>&1
>>"%LOG%" echo ExitCode=%ERRORLEVEL%
>>"%LOG%" echo.

echo [4/7] Testing normal HKCU registry write...
>>"%LOG%" echo ==== 4. Temporary HKCU registry write ====
reg delete "%TESTKEY%" /f >>"%LOG%" 2>&1
reg add "%TESTKEY%" /v TestValue /t REG_SZ /d OK /f >>"%LOG%" 2>&1
set "REGADD_RC=%ERRORLEVEL%"
>>"%LOG%" echo RegAddExitCode=%REGADD_RC%
reg query "%TESTKEY%" /v TestValue >>"%LOG%" 2>&1
set "REGQUERY_RC=%ERRORLEVEL%"
>>"%LOG%" echo RegQueryExitCode=%REGQUERY_RC%
reg delete "%TESTKEY%" /f >>"%LOG%" 2>&1
>>"%LOG%" echo.

echo [5/7] Testing cscript.exe...
>>"%LOG%" echo ==== 5. cscript test ====
where cscript.exe >>"%LOG%" 2>&1
> "%TESTJS%" echo WScript.Echo("CSCRIPT_OK");
cscript.exe //nologo "%TESTJS%" >>"%LOG%" 2>&1
set "CSCRIPT_RC=%ERRORLEVEL%"
>>"%LOG%" echo CScriptExitCode=%CSCRIPT_RC%
del /q "%TESTJS%" >nul 2>&1
>>"%LOG%" echo.

echo [6/7] Finding Microsoft Access...
>>"%LOG%" echo ==== 6. MSACCESS.EXE lookup ====
reg query "HKLM\Software\Microsoft\Windows\CurrentVersion\App Paths\MSACCESS.EXE" /ve >>"%LOG%" 2>&1
reg query "HKLM\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\App Paths\MSACCESS.EXE" /ve >>"%LOG%" 2>&1
if exist "%ProgramFiles%\Microsoft Office\root\Office16\MSACCESS.EXE" >>"%LOG%" echo FOUND: %ProgramFiles%\Microsoft Office\root\Office16\MSACCESS.EXE
if exist "%ProgramFiles(x86)%\Microsoft Office\root\Office16\MSACCESS.EXE" >>"%LOG%" echo FOUND: %ProgramFiles(x86)%\Microsoft Office\root\Office16\MSACCESS.EXE
>>"%LOG%" echo.

echo [7/7] Reading recent AppLocker and Code Integrity events...
>>"%LOG%" echo ==== 7A. AppLocker MSI and Script ====
wevtutil qe "Microsoft-Windows-AppLocker/MSI and Script" /c:10 /rd:true /f:text >>"%LOG%" 2>&1
>>"%LOG%" echo.
>>"%LOG%" echo ==== 7B. AppLocker EXE and DLL ====
wevtutil qe "Microsoft-Windows-AppLocker/EXE and DLL" /c:10 /rd:true /f:text >>"%LOG%" 2>&1
>>"%LOG%" echo.
>>"%LOG%" echo ==== 7C. CodeIntegrity Operational ====
wevtutil qe "Microsoft-Windows-CodeIntegrity/Operational" /c:10 /rd:true /f:text >>"%LOG%" 2>&1
>>"%LOG%" echo.

echo.
echo Diagnostic completed.
echo Log:
echo %LOG%
echo.
echo Key results:
echo Registry write exit code: %REGADD_RC%
echo cscript exit code: %CSCRIPT_RC%
echo.
pause

endlocal
exit /b 0
