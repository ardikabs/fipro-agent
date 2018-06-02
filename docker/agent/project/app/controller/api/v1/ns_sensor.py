
import docker
import time
from flask import jsonify, request, make_response
from flask_restplus import Namespace, Resource, fields
from app.controller.api import api
from . import config

ns = api.namespace('sensor', description='Sensor related operations')
client = docker.DockerClient(base_url='unix://var/run/docker.sock')


@ns.route('/')
class HoneypotCollection(Resource):
    def get(self):
        try:
            containers = client.containers.list(all=True)
            response = {
                'status': True,
                'sensors': [
                    {
                        'sensor_id': container.id,
                        'sensor_name': container.name,
                        'sensor_status': container.status,
                        'sensor_state': container.attrs['State']
                    } for container in containers
                ],
                'timestamps': time.time()
            }
            return make_response(jsonify(response), 200)
        except docker.errors.APIError:
            response = {'status': False,'message': "There is a problem in sensor server !"}
            return make_response(jsonify(response), 500)

    def post(self):
        data = request.json
        sensor_name = data["sensor_name"]
        sensor_type = data["sensor_type"]
        sensor_image = data["sensor_image"] or "ardikabs/"+sensor_type+":1.0"

        try:
            container = client.containers.run(image=sensor_image, 
                                            name=sensor_name,
                                            restart_policy={"Name": "always"},
                                            ports= config.container_attributes[sensor_type]['ports'],
                                            volumes= config.container_attributes[sensor_type]['volumes'],
                                            detach=True)

            response = {
                'status': True,
                'sensor_name': sensor_name,
                'sensor_id': container.id,
                'message': "Sensor "+ sensor_name +" successfully has been added",
                'timestamps': time.time()
            }

            return make_response(jsonify(response), 200)
        
        except docker.errors.APIError:
            response = {'status': False,'message': "There is a problem in sensor server !"}
            return make_response(jsonify(response), 500)

@ns.route('/<string:sensor_id>/')
class HoneypotItem(Resource):
    def get(self, sensor_id):
        try:
            container= client.containers.get(sensor_id)

            response = {
                'status': True,
                'sensor': {
                    'id': container.id, 
                    'name': container.name, 
                    'status': container.status,
                    'state': container.attrs['State']
                },
                'timestamps': time.time()
            }

            return make_response(jsonify(response), 200)
            
        except docker.errors.NotFound:
            response = {"status":False,"message":"Container not Found"}
            return make_response(jsonify(response), 404)
    
    def put(self, sensor_id):
        data = request.json
        sensor_name = data["sensor_name"]
        print (sensor_name)
        try:
            container = client.containers.get(sensor_id)
            container.rename(name=sensor_name)

            message = "Sensor {0} has been renamed with {1}.".format(container.name, sensor_name)
            container = client.containers.get(sensor_id)
            response = {
                'status': True,
                'sensor': {
                    'id': container.id, 
                    'name': container.name, 
                    'status': container.status,
                    'state': container.attrs['State']
                },
                'message': message,
                'timestamps': time.time()
            }

            return make_response(jsonify(response), 200)
        
        except docker.errors.APIError:
            response = {'status': False,'message': "There is a problem in sensor server !"}
            return make_response(jsonify(response), 500)


    def delete(self, sensor_id):
        try:
            container = client.containers.get(sensor_id)
            container.remove(force=True)

            message = "Sensor {} has been removed".format(container.name)
            response = {
                'status': True,
                'sensor': {
                    'id': container.id, 
                    'name': container.name, 
                    'status': container.status,
                    'state': container.attrs['State']
                },
                'message': message,
                'timestamps': time.time()
            }

            return make_response(jsonify(response), 200)
        
        except docker.errors.APIError:
            response = {'status': False,'message': "There is a problem in sensor server !"}
            return make_response(jsonify(response), 500)


@ns.route('/<string:sensor_id>/<string:operator>/')
class HoneypotOperation(Resource):

    def get(self, sensor_id, operator):
        try:
            container= client.containers.get(sensor_id)
            if operator == 'start':
                container.start()
                message = "Sensor {} have been started".format(container.name)
            elif operator == 'stop':
                container.stop()
                message = "Sensor {} have been stopped".format(container.name)
            elif operator == 'restart':
                container.restart()
                message = "Sensor {} have been restarted".format(container.name)

            else:
                return dict(
                        status=False,
                        message="Operation unknown. Operation: Start | Stop | Restart"
                    )

            container = client.containers.get(sensor_id)
            response = {
                'status': True,
                'sensor': {
                    'id': container.id, 
                    'name': container.name, 
                    'status': container.status,
                    'state': container.attrs['State']
                },
                "message": message,
                'timestamps': time.time()
            }

            return make_response(jsonify(response), 200)
            
        except docker.errors.NotFound:
            response = {"status":False,"message":"Container not Found"}
            return make_response(jsonify(response), 404)
    

