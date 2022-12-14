import os
from flask import Flask
from .models import db
from .oauth2 import config_oauth
from .routes import bp

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

    print( app.config)
    setup_app(app)
    return app


def setup_app(app):
    # Create tables if they do not exist already
    @app.before_first_request
    def create_tables():
        db.create_all()
    db.init_app(app)
    config_oauth(app)
    app.register_blueprint(bp, url_prefix=app.config['APPLICATION_ROOT'])
basedir = os.path.abspath(os.path.dirname(__file__))
app = create_app({
    'SECRET_KEY': 'secret',
    'OAUTH2_REFRESH_TOKEN_GENERATOR': True,
    'SQLALCHEMY_TRACK_MODIFICATIONS': False,
    'SQLALCHEMY_DATABASE_URI':os.environ.get('SQLALCHEMY_DATABASE_URI', 'sqlite:///' + os.path.join(basedir, 'test.db'))
})
##from flask_cors import CORS

#CORS(app)

