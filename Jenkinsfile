pipeline {
    agent any

    environment {
        APP_DIR = 'C:\\Apps\\flask-oauth2'
        SERVICE_NAME = 'Flask OAuth2'
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
                    python --version
                    python -m pip --version
                '''
            }
        }

        stage('Install Dependencies') {
            steps {
                bat '''
                    @echo off
                    python -m pip install --upgrade pip
                    python -m pip install -r requirements.txt
                    python -m pip install waitress python-dotenv
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
                        (
                            echo AUTHLIB_INSECURE_TRANSPORT=1
                            echo APPLICATION_ROOT=/api/oauth
                            echo SCRIPT_NAME=/api/oauth
                            echo FLASK_ENV=development
                            echo DEBUG=True
                            echo FLASK_APP=app
                            echo SQLALCHEMY_DATABASE_URI=%DB_URI%
                        ) > .env
                    '''
                }
            }
        }

        stage('Validate Application') {
            steps {
                bat '''
                    @echo off
                    python -m flask --version
                    python -c "import flask; print('Flask OK')"
                    python -c "import authlib; print('Authlib OK')"
                    python -c "import waitress; print('Waitress OK')"
                '''
            }
        }

        stage('Tests') {
            steps {
                bat '''
                    @echo off
                    if exist tests (
                        python -m pytest
                    ) else (
                        echo No tests directory found. Skipping tests.
                    )
                '''
            }
        }

        stage('Deploy Files') {
            steps {
                bat '''
                    @echo off

                    if not exist "%APP_DIR%" mkdir "%APP_DIR%"

                    sc query "%SERVICE_NAME%" >nul 2>&1
                    if %ERRORLEVEL% EQU 0 (
                        net stop "%SERVICE_NAME%" >nul 2>&1
                    )

                    robocopy "%WORKSPACE%" "%APP_DIR%" /MIR /XD ".git" ".pytest_cache" "__pycache__" /XF "*.pyc"
                    if %ERRORLEVEL% LEQ 7 exit /b 0
                    exit /b %ERRORLEVEL%
                '''
            }
        }

        stage('Install / Update Service') {
            steps {
                bat '''
                    @echo off
                    cd /d "%APP_DIR%"
                    call install-flask-oauth2-service.bat
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
