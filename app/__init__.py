import os
from pathlib import Path

from dotenv import load_dotenv
from flask import Flask

from .models import db
from .oauth2 import config_oauth
from .routes import bp


# Root del proyecto:
# C:\Apps\flask-oauth2
BASE_DIR = Path(__file__).resolve().parent.parent

# Carga:
# C:\Apps\flask-oauth2\.env
load_dotenv(BASE_DIR / ".env")


def create_app(config=None):
    app = Flask(__name__)

    # load default configuration
    app.config.from_object('app.settings')

    # load environment configuration
    if 'app_CONF' in os.environ:
        app.config.from_envvar('app_CONF')

    # load app specified configuration
    if config is not None:
        if isinstance(config, dict):
            app.config.update(config)
        elif config.endswith('.py'):
            app.config.from_pyfile(config)

    setup_app(app)

    return app


def setup_app(app):
    db.init_app(app)
    config_oauth(app)

    app.register_blueprint(
        bp,
        url_prefix=app.config['APPLICATION_ROOT']
    )

    # Create tables if they do not exist already
    with app.app_context():
        db.create_all()


db_uri = os.environ.get('SQLALCHEMY_DATABASE_URI')

if not db_uri:
    raise RuntimeError(
        f'SQLALCHEMY_DATABASE_URI not found in {BASE_DIR / ".env"}'
    )


app = create_app({
    'SECRET_KEY': 'secret',
    'OAUTH2_REFRESH_TOKEN_GENERATOR': True,
    'SQLALCHEMY_TRACK_MODIFICATIONS': False,
    'SQLALCHEMY_DATABASE_URI': db_uri,
})

# from flask_cors import CORS
# CORS(app)