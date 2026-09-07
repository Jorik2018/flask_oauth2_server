pipeline {
    agent any

    environment {
        APP_DIR = 'C:\\Apps\\flask-oauth2'
        SERVICE_NAME = 'Flask OAuth2'
        PYTHONUNBUFFERED = '1'
        PYTHON_HOME = 'C:\\Tools\\Python312'
        PATH = "${PYTHON_HOME};${PYTHON_HOME}\\Scripts;${env.PATH}"
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
                where python
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
            python -m pip install pipenv

            pipenv install --deploy

            pipenv run python -m pip install waitress python-dotenv
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

                python -c "import os; from pathlib import Path; Path('.env').write_text('AUTHLIB_INSECURE_TRANSPORT=1\\nAPPLICATION_ROOT=/api/oauth\\nSCRIPT_NAME=/api/oauth\\nFLASK_ENV=development\\nDEBUG=True\\nFLASK_APP=app\\nSQLALCHEMY_DATABASE_URI=' + os.environ['DB_URI'] + '\\n', encoding='utf-8')"
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
