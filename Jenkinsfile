pipeline {
    agent any

    options {
        // Evita que Jenkins haga checkout automático y luego nosotros otro checkout.
        skipDefaultCheckout(true)
    }

    environment {
        APP_DIR = 'C:\\Apps\\flask-oauth2'
        SERVICE_NAME = 'Flask OAuth2'

        PYTHON_HOME = 'C:\\Tools\\Python312'
        PATH = "${PYTHON_HOME};${PYTHON_HOME}\\Scripts;${env.PATH}"

        PYTHONUNBUFFERED = '1'
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

                    .venv\\Scripts\\python.exe -c "import flask; print('Flask OK:', flask.__version__)"
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

            sc query "%SERVICE_NAME%" >nul 2>&1

            if %ERRORLEVEL% EQU 0 (
                echo Stopping existing service...
                net stop "%SERVICE_NAME%" >nul 2>&1
                echo Service stopped.
            ) else (
                echo Service does not exist yet. First deployment.
            )

            exit /b 0
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

                    cd /d "%APP_DIR%"

                    call install-flask-oauth2-service.bat

                    if errorlevel 1 exit /b 1
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