@echo off
setlocal

set "SERVICE_NAME=Flask OAuth2"
set "APP_DIR=C:\Apps\flask-oauth2"
set "HOST=0.0.0.0"
set "PORT=5001"

echo.
echo ============================================
echo Installing / updating "%SERVICE_NAME%"
echo ============================================
echo.

where python >nul 2>&1
if errorlevel 1 (
    echo ERROR: python was not found in PATH.
    exit /b 1
)

where nssm >nul 2>&1
if errorlevel 1 (
    echo ERROR: nssm was not found in PATH.
    exit /b 1
)

if not exist "%APP_DIR%" (
    echo ERROR: Application directory does not exist:
    echo %APP_DIR%
    exit /b 1
)

if not exist "%APP_DIR%\.env" (
    echo ERROR: .env was not found:
    echo %APP_DIR%\.env
    exit /b 1
)

if not exist "%APP_DIR%\logs" (
    mkdir "%APP_DIR%\logs"
)

for /f "delims=" %%P in ('where python') do (
    set "PYTHON_EXE=%%P"
    goto :python_found
)

:python_found

echo Python:
echo %PYTHON_EXE%
echo.

sc query "%SERVICE_NAME%" >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo Existing service found. Stopping it...
    nssm stop "%SERVICE_NAME%" >nul 2>&1
) else (
    echo Installing new service...
    nssm install "%SERVICE_NAME%" "%PYTHON_EXE%" "-m waitress --listen=%HOST%:%PORT% app:app"
)

nssm set "%SERVICE_NAME%" Application "%PYTHON_EXE%"
nssm set "%SERVICE_NAME%" AppParameters "-m waitress --listen=%HOST%:%PORT% app:app"
nssm set "%SERVICE_NAME%" AppDirectory "%APP_DIR%"

nssm set "%SERVICE_NAME%" AppEnvironmentExtra ^
FLASK_APP=app ^
AUTHLIB_INSECURE_TRANSPORT=1 ^
APPLICATION_ROOT=/api/oauth ^
SCRIPT_NAME=/api/oauth

nssm set "%SERVICE_NAME%" Start SERVICE_AUTO_START

nssm set "%SERVICE_NAME%" AppExit Default Restart
nssm set "%SERVICE_NAME%" AppRestartDelay 5000

nssm set "%SERVICE_NAME%" AppStdout "%APP_DIR%\logs\flask-oauth2.log"
nssm set "%SERVICE_NAME%" AppStderr "%APP_DIR%\logs\flask-oauth2-error.log"

nssm set "%SERVICE_NAME%" AppRotateFiles 1
nssm set "%SERVICE_NAME%" AppRotateOnline 1
nssm set "%SERVICE_NAME%" AppRotateBytes 10485760

echo.
echo Starting service...
nssm start "%SERVICE_NAME%"

if errorlevel 1 (
    echo ERROR: Service could not be started.
    echo Check:
    echo   %APP_DIR%\logs\flask-oauth2-error.log
    exit /b 1
)

echo.
echo ============================================
echo Service installed and started successfully.
echo Service: %SERVICE_NAME%
echo URL: http://127.0.0.1:%PORT%/api/oauth
echo ============================================
echo.

exit /b 0
