@echo off
setlocal

set "SCRIPT_NAME=strategy_a_filename_priority"
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

echo Strategy A started

echo Step 1/3: extension normalization
"%ET%" -ext jpg  -if "$FileType eq 'PNG'"  "-FileName=%%f.png" .
"%ET%" -ext png  -if "$FileType eq 'JPEG'" "-FileName=%%f.jpg" .
"%ET%" -ext heic -if "$FileType eq 'JPEG'" "-FileName=%%f.jpg" .
"%ET%" -ext webp -if "$FileType eq 'JPEG'" "-FileName=%%f.jpg" .
"%ET%" -ext jpg  -if "$FileType eq 'WEBP'" "-FileName=%%f.webp" .

echo Step 2/3: baseline from FileModifyDate
"%ET%" -api QuickTimeUTC "-AllDates<FileModifyDate" "-FileModifyDate<FileModifyDate" -ext jpg -ext jpeg -ext mp4 -ext mov -ext heic -ext webp -ext png -overwrite_original_in_place .

echo Step 3/3: override from filename for year-prefixed names only
"%ET%" -api QuickTimeUTC -if "$filename =~ /^(19|20)\d{2}/" "-AllDates<Filename" "-FileModifyDate<Filename" -ext jpg -ext jpeg -ext mp4 -ext mov -ext heic -ext webp -ext png -overwrite_original_in_place .

echo Strategy A completed
exit /b 0