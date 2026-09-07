Deployment files for Flask OAuth2

Jenkins credential:
- Kind: Secret text
- ID: SQLALCHEMY_DATABASE_URI
- Example value: sqlite:///oauth.db

Server requirements:
- Python 3.9+
- NSSM in PATH
- Jenkins agent with permissions to install/start Windows services

Deployment directory:
C:\Apps\flask-oauth2

Windows service:
Flask OAuth2

WSGI server:
Waitress

Expected Flask application:
app:app

If the Flask object or module has a different name, update app:app in:
install-flask-oauth2-service.bat
