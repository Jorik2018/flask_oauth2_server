from website.app import create_app


app = create_app({
    'SECRET_KEY': 'secret',
    'OAUTH2_REFRESH_TOKEN_GENERATOR': True,
    'SQLALCHEMY_TRACK_MODIFICATIONS': False,
    'SQLALCHEMY_DATABASE_URI':'sqlite:///db.sqlite',
    'SQLALCHEMY_DATABASE_URI/':'mysql+mysqlconnector://root:root@localhost/production'
})
