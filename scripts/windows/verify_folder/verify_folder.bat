@echo off
setlocal

set "SCRIPT_NAME=verify_folder"
set "ROOT=%~dp0..\..\.."
set "LOGDIR=%ROOT%\logs"
if not exist "%LOGDIR%" mkdir "%LOGDIR%"

for /f %%I in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set "TS=%%I"
set "LOGFILE=%LOGDIR%\%TS%_%SCRIPT_NAME%.log"

call :main >> "%LOGFILE%" 2>&1
set "EXITCODE=%ERRORLEVEL%"

echo.
echo [%SCRIPT_NAME%] Exit code: %EXITCODE%
echo [%SCRIPT_NAME%] Log: %LOGFILE%
exit /b %EXITCODE%

:main
set "ET=%EXIFTOOL_PATH%"
if "%ET%"=="" set "ET=C:\Users\hello\Documents\Tools\exiftool-13.44_64\exiftool.exe"

if not exist "%ET%" (
  echo ERROR: ExifTool not found at "%ET%"
  echo Set EXIFTOOL_PATH environment variable and retry.
  exit /b 2
)

echo Running folder-level verification
"%ET%" -filename -DateTimeOriginal -QuickTime:CreateDate -FileModifyDate -T -ext jpg -ext jpeg -ext png -ext heic -ext webp -ext mp4 -ext mov .

echo Running missing tag scan: images
"%ET%" -if "not $DateTimeOriginal" -filename -ext jpg -ext jpeg -ext png -ext heic -ext webp .

echo Running missing tag scan: videos
"%ET%" -if "not $QuickTime:CreateDate" -filename -ext mp4 -ext mov .

exit /b 0