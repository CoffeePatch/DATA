@echo off
setlocal

set "SCRIPT_NAME=append_datetime_suffix"
set "ROOT=%~dp0..\.."
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

echo Appending datetime suffix to filenames while preserving original prefix
"%ET%" -api QuickTimeUTC -d "%%f_%%Y%%m%%d_%%H%%M%%S.%%e" "-FileName<DateTimeOriginal" "-FileName<QuickTime:CreateDate" -ext jpg -ext jpeg -ext mp4 -ext mov -ext heic -ext webp -ext png -overwrite_original_in_place .

exit /b 0
