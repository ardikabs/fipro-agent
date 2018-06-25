
from flask import current_app, abort
from flask_restplus import Api
from flask import Blueprint

api_v1 = Blueprint('api', __name__, url_prefix='/api/v1')
api = Api(
    api_v1, 
    version='1.0', 
    title='Sensor-Side API',
    description='A Sensor-Side API for Sensor Management with Docker API'
)

@api_v1.before_request
def check_ipaddr():
    if request.remote_addr != current_app.config['SERVER_IP']:
    # if '192.168.1.100' != current_app.config['SERVER_IP']:
        abort(403)

from .v1 import *

