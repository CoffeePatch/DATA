@echo off
setlocal

set "SCRIPT_NAME=verify_file"
set "ROOT=%~dp0..\..\.."
set "LOGDIR=%ROOT%\logs"
if not exist "%LOGDIR%" mkdir "%LOGDIR%"

for /f %%I in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set "TS=%%I"
set "LOGFILE=%LOGDIR%\%TS%_%SCRIPT_NAME%.log"

call :main %* >> "%LOGFILE%" 2>&1
set "EXITCODE=%ERRORLEVEL%"

echo.
echo [%SCRIPT_NAME%] Exit code: %EXITCODE%
echo [%SCRIPT_NAME%] Log: %LOGFILE%
exit /b %EXITCODE%

:main
if "%~1"=="" (
  echo Usage: %~nx0 "filename.ext"
  exit /b 1
)

set "TARGET=%~1"
set "ET=%EXIFTOOL_PATH%"
if "%ET%"=="" set "ET=C:\Users\hello\Documents\Tools\exiftool-13.44_64\exiftool.exe"

if not exist "%ET%" (
  echo ERROR: ExifTool not found at "%ET%"
  echo Set EXIFTOOL_PATH environment variable and retry.
  exit /b 2
)

if not exist "%TARGET%" (
  echo ERROR: File not found: %TARGET%
  exit /b 3
)

echo Running single-file verification for: %TARGET%
"%ET%" -filename -DateTimeOriginal -QuickTime:CreateDate -FileModifyDate "%TARGET%"

exit /b 0