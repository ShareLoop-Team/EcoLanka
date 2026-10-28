@echo off
REM Downloads the demo photos listed in photos.txt (Unsplash photo ids) as <name>.jpg
cd /d "%~dp0"
for /f "usebackq tokens=1*" %%A in ("photos.txt") do call :get %%A %%B
exit /b 0
:get
set "NAME=%1"
if exist "%NAME%.jpg" exit /b 0
shift
:try
if "%1"=="" (echo   missing %NAME% & exit /b 0)
curl.exe -sSfL --max-time 60 -o "%NAME%.jpg" "https://unsplash.com/photos/%1/download?force=true&w=800" && (echo   ok %NAME% & exit /b 0)
del "%NAME%.jpg" 2>nul
shift
goto try
