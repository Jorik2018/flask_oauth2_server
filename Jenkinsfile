pipeline {
    agent any

    options {
        skipDefaultCheckout(true)
    }

    environment {
        APP_DIR = 'C:\\Apps\\flask-oauth2'

        // ID interno del servicio Windows
        SERVICE_ID = 'flask-oauth2'

        // Nombre visible
        SERVICE_NAME = 'Flask OAuth2'

        PYTHON_HOME = 'C:\\Tools\\Python312'
        PATH = "${PYTHON_HOME};${PYTHON_HOME}\\Scripts;${env.PATH}"

        PYTHONUNBUFFERED = '1'

        // Ajustar si tu service_manager.py está en otra ubicación
        SERVICE_MANAGER = 'D:\\wildfly\\bin\\service_manager.py'
        APP_HOST = '0.0.0.0'
    APP_PORT = '5000'
    WSGI_APP = 'app:app'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Python') {
            steps {
                bat '''
                    @echo off

                    echo === Python ===
                    where python
                    python --version
                    python -m pip --version
                '''
            }
        }

        stage('Create Build Virtualenv') {
            steps {
                bat '''
                    @echo off

                    echo === Creating workspace virtualenv ===

                    if not exist ".venv\\Scripts\\python.exe" (
                        python -m venv .venv
                    )

                    .venv\\Scripts\\python.exe -m pip install --upgrade pip
                    if errorlevel 1 exit /b 1

                    .venv\\Scripts\\python.exe -m pip install -r requirements.txt
                    if errorlevel 1 exit /b 1
                '''
            }
        }

        stage('Create .env') {
            steps {
                withCredentials([
                    string(
                        credentialsId: 'SQLALCHEMY_DATABASE_URI',
                        variable: 'DB_URI'
                    )
                ]) {
                    bat '''
                        @echo off

                        .venv\\Scripts\\python.exe -c "import os; from pathlib import Path; Path('.env').write_text('AUTHLIB_INSECURE_TRANSPORT=1\\nAPPLICATION_ROOT=/api/oauth\\nSCRIPT_NAME=/api/oauth\\nFLASK_ENV=development\\nDEBUG=True\\nFLASK_APP=app\\nSQLALCHEMY_DATABASE_URI=' + os.environ['DB_URI'] + '\\n', encoding='utf-8')"

                        if errorlevel 1 exit /b 1
                    '''
                }
            }
        }

        stage('Validate Application') {
            steps {
                bat '''
                    @echo off

                    echo === Validate environment ===

                    .venv\\Scripts\\python.exe --version

                    .venv\\Scripts\\python.exe -c "from importlib.metadata import version; print('Flask OK:', version('flask'))"
                    if errorlevel 1 exit /b 1

                    .venv\\Scripts\\python.exe -c "import authlib; print('Authlib OK:', authlib.__version__)"
                    if errorlevel 1 exit /b 1

                    .venv\\Scripts\\python.exe -c "import sqlalchemy; print('SQLAlchemy OK:', sqlalchemy.__version__)"
                    if errorlevel 1 exit /b 1

                    .venv\\Scripts\\python.exe -c "import mysql.connector; print('MySQL Connector OK')"
                    if errorlevel 1 exit /b 1

                    .venv\\Scripts\\python.exe -c "import waitress; print('Waitress OK')"
                    if errorlevel 1 exit /b 1
                '''
            }
        }

        stage('Tests') {
            steps {
                bat '''
                    @echo off

                    if exist tests (
                        .venv\\Scripts\\python.exe -m pytest
                        if errorlevel 1 exit /b 1
                    ) else (
                        echo No tests directory found. Skipping tests.
                    )
                '''
            }
        }

        stage('Stop Service') {
            steps {
                bat '''
                    @echo off

                    echo === Stopping service ===

                    if not exist "%SERVICE_MANAGER%" (
                        echo ERROR: service_manager.py not found:
                        echo %SERVICE_MANAGER%
                        exit /b 1
                    )

                    python "%SERVICE_MANAGER%" stop "%SERVICE_ID%"

                    if errorlevel 1 exit /b 1
                '''
            }
        }

        stage('Deploy Files') {
            steps {
                bat '''
                    @echo off

                    if not exist "%APP_DIR%" (
                        mkdir "%APP_DIR%"
                    )

                    echo === Copying application ===

                    robocopy "%WORKSPACE%" "%APP_DIR%" /MIR ^
                        /XD ".git" ".venv" ".pytest_cache" "__pycache__" "logs" ^
                        /XF "*.pyc"

                    set ROBOCOPY_EXIT=%ERRORLEVEL%

                    if %ROBOCOPY_EXIT% LEQ 7 (
                        exit /b 0
                    )

                    exit /b %ROBOCOPY_EXIT%
                '''
            }
        }

        stage('Create Runtime Virtualenv') {
            steps {
                bat '''
                    @echo off

                    echo === Preparing runtime virtualenv ===

                    cd /d "%APP_DIR%"

                    if not exist ".venv\\Scripts\\python.exe" (
                        "%PYTHON_HOME%\\python.exe" -m venv .venv
                    )

                    .venv\\Scripts\\python.exe -m pip install --upgrade pip
                    if errorlevel 1 exit /b 1

                    .venv\\Scripts\\python.exe -m pip install -r requirements.txt
                    if errorlevel 1 exit /b 1

                    echo === Runtime Python ===
                    .venv\\Scripts\\python.exe --version

                    echo === Runtime dependencies ===

                    .venv\\Scripts\\python.exe -c "import flask, authlib, sqlalchemy, mysql.connector, waitress; print('Runtime dependencies OK')"

                    if errorlevel 1 exit /b 1
                '''
            }
        }

        stage('Install / Update Service') {
    steps {
        bat '''
            @echo off

            echo === Installing / updating Windows service ===

            python "%SERVICE_MANAGER%" install "%SERVICE_ID%" "%APP_DIR%" ^
                --type flask ^
                --name "%SERVICE_NAME%" ^
                --description "%SERVICE_DESCRIPTION%" ^
                --host "%APP_HOST%" ^
                --port "%APP_PORT%" ^
                --wsgi-app "%WSGI_APP%"

            if errorlevel 1 exit /b 1
        '''
    }
}

stage('Inspect OAuth Tables') {
    steps {
        bat '''
            @echo off

            cd /d "%APP_DIR%"

            .venv\\Scripts\\python.exe -c "from app.models import OAuth2AuthorizationCode; print([(c.name, str(c.type), c.nullable) for c in OAuth2AuthorizationCode.__table__.columns])"
        '''
    }
}

        stage('Start Service') {
            steps {
                bat '''
                    @echo off

                    echo === Starting service ===

                    python "%SERVICE_MANAGER%" start "%SERVICE_ID%"

                    if errorlevel 1 exit /b 1

                    echo.
                    echo === Service status ===

                    python "%SERVICE_MANAGER%" status "%SERVICE_ID%"
                '''
            }
        }
stage('Health Check') {
    steps {
        powershell '''
            $hostName = "127.0.0.1"
            $port = [int]$env:APP_PORT
            $maxAttempts = 5

            for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
                Write-Host "Health check $attempt/$maxAttempts..."
                Write-Host "Checking ${hostName}:${port}"

                $result = Test-NetConnection `
                    -ComputerName $hostName `
                    -Port $port `
                    -WarningAction SilentlyContinue

                if ($result.TcpTestSucceeded) {
                    Write-Host "Flask service is listening on port $port."
                    exit 0
                }

                Write-Host "Port $port is not available yet."

                if ($attempt -lt $maxAttempts) {
                    Start-Sleep -Seconds 5
                }
            }

            throw "Flask OAuth2 is not listening on ${hostName}:${port}"
        '''
    }
}
    }

    post {
        success {
            echo 'Flask OAuth2 deployed successfully.'
        }

        failure {
            echo 'Flask OAuth2 deployment failed.'
        }
    }
}