from flask import Flask, jsonify
from flask.json import JSONEncoder
from flask_cors import CORS, cross_origin

import bus
import os
import json
import datetime

settings = bus.open_settings('config.json')
data_path = settings['data']

# Get all departures
all_departures = []

stops = settings['stops']
for stop in stops:

    filename = os.path.join(data_path, stop['stop_id']) + ".latest.xml"
    departures = bus.convert_xmlfile_to_array(filename, stop['stop_name'])

    all_departures.extend(departures)


class CustomJSONEncoder(JSONEncoder):

    def default(self, obj):
        try:
            if isinstance(obj, datetime.datetime):
                return obj.isoformat()
            iterable = iter(obj)
        except TypeError:
            pass
        else:
            return list(iterable)
        return JSONEncoder.default(self, obj)

app = Flask(__name__)
app.json_encoder = CustomJSONEncoder
cors = CORS(app)

app.config['CORS_HEADERS'] = 'Content-Type'

@app.route('/api/v1.0/latest', methods=['GET'])
def get_tasks():
    return jsonify({'departures': all_departures})

if __name__ == '__main__':
    app.run(debug=True)