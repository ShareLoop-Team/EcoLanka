@echo off
REM Shareloop API - first-time setup + start (Windows). Needs PHP 8.2+ on PATH.
cd /d "%~dp0"
REM PHP installed with winget may not be on PATH until you sign in again
where php >nul 2>nul || for /d %%P in ("%LOCALAPPDATA%\Microsoft\WinGet\Packages\PHP.PHP.*") do set "PATH=%%~fP;%PATH%"
where php >nul 2>nul || (echo PHP was not found on PATH. Install PHP 8.2+ ^(e.g. from https://windows.php.net or XAMPP^). & pause & exit /b 1)
php -m | findstr /i pdo_sqlite >nul || (echo PHP extension pdo_sqlite is not enabled. In php.ini set extension_dir="ext" and enable: pdo_sqlite, sqlite3, mbstring, openssl, fileinfo, curl. & pause & exit /b 1)
REM vendor.tgz = prebuilt PHP dependencies (unpacked once, so Composer is optional)
if exist vendor.tgz if not exist vendor\.unpacked (
  echo Unpacking PHP dependencies...
  tar -xzf vendor.tgz && type nul > vendor\.unpacked
)
if not exist vendor\autoload.php (
  where composer >nul 2>nul || (echo vendor\ is missing and Composer was not found. Install Composer from https://getcomposer.org & pause & exit /b 1)
  call composer install || (pause & exit /b 1)
)
if not exist .env copy .env.example .env >nul
findstr /r /c:"^APP_KEY=base64" .env >nul || php artisan key:generate
if not exist database\database.sqlite (
  type nul > database\database.sqlite
  php artisan migrate --force --seed
  php artisan db:seed --class=DemoSeeder --force
) else (
  php artisan migrate --force
)
echo.
echo Shareloop API running on http://localhost:8000/api  (Ctrl+C to stop)
echo Test sign-in: +94 77 000 0001 or +94 77 000 0002, code 123456
php artisan serve --host=0.0.0.0 --port=8000
