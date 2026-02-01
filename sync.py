import bus
import os
import sys

try:
    config_file = sys.argv[1]
except:
    print("Config file not specified")
    sys.exit(1)

settings = bus.open_settings(config_file)

api_username = settings['api_username']
api_password = settings['api_password']

data_path = settings['data']

stops = settings['stops']

for stop in stops:
    output_filename = os.path.join(data_path, stop['stop_id']) + ".latest.xml"
    bus.download_xml_to_file(stop['stop_id'], api_username, api_password, output_filename)
