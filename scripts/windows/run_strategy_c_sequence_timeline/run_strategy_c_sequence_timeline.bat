@echo off
setlocal

set "SCRIPT_NAME=strategy_c_sequence_timeline"
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
if "%~1"=="" goto usage
if "%~2"=="" goto usage
if "%~3"=="" goto usage

set "START_NUM=%~1"
set "BASE_DT=%~2"
set "STEP_SEC=%~3"

set "ET=%EXIFTOOL_PATH%"
if "%ET%"=="" set "ET=C:\Users\hello\Documents\Tools\exiftool-13.44_64\exiftool.exe"

if not exist "%ET%" (
  echo ERROR: ExifTool not found at "%ET%"
  echo Set EXIFTOOL_PATH environment variable and retry.
  exit /b 2
)

echo Strategy C started
echo Start sequence number: %START_NUM%
echo Base datetime: %BASE_DT%
echo Step seconds: %STEP_SEC%

echo Optional pre-pass: extension normalization
"%ET%" -ext jpg  -if "$FileType eq 'PNG'"  "-FileName=%%f.png" .
"%ET%" -ext png  -if "$FileType eq 'JPEG'" "-FileName=%%f.jpg" .
"%ET%" -ext heic -if "$FileType eq 'JPEG'" "-FileName=%%f.jpg" .
"%ET%" -ext webp -if "$FileType eq 'JPEG'" "-FileName=%%f.jpg" .
"%ET%" -ext jpg  -if "$FileType eq 'WEBP'" "-FileName=%%f.webp" .

echo Applying synthetic timeline from Media_XXXXXX sequence
"%ET%" -api QuickTimeUTC "-AllDates=%BASE_DT%" "-FileModifyDate=%BASE_DT%" "-AllDates+<${filename;$_=/(\d+)/ ? (($1-%START_NUM%)*%STEP_SEC%) : 0}" "-FileModifyDate+<${filename;$_=/(\d+)/ ? (($1-%START_NUM%)*%STEP_SEC%) : 0}" -ext jpg -ext jpeg -ext mp4 -ext mov -ext heic -ext webp -ext png -overwrite_original_in_place .

echo Strategy C completed
exit /b 0

:usage
echo Usage:
echo   %~nx0 START_NUM "YYYY:MM:DD HH:MM:SS" STEP_SECONDS
echo Example:
echo   %~nx0 49682 "2025:08:07 14:34:00" 300
exit /b 1