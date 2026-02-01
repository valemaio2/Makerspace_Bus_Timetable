import datetime
import requests
import random
import string
import json

import xml.etree.ElementTree as ET
from xml.dom import minidom

nextbuses_url = "https://nextbus.mxdata.co.uk/nextbuses/1.0/1"


def open_settings(filename):
    with open(filename) as f:
        settings = json.load(f)

    return settings


def convert_xmlfile_to_array(filename, stop_name):

    stop_monitoring_request = minidom.parse(filename)

    departures = []
    for stop in stop_monitoring_request.getElementsByTagName('MonitoredStopVisit'):

        vehicle_journey = stop.getElementsByTagName('MonitoredVehicleJourney')[0]

        departure = {}

        departure['date'] = datetime.datetime.now()
        departure['bus_stop'] = stop_name
        departure['line_name'] = vehicle_journey.getElementsByTagName('PublishedLineName')[0].firstChild.nodeValue
        departure['direction'] = vehicle_journey.getElementsByTagName('DirectionName')[0].firstChild.nodeValue

        times = vehicle_journey.getElementsByTagName('MonitoredCall')[0]
        departure['scheduled_departure'] = datetime.datetime.fromisoformat(times.getElementsByTagName('AimedDepartureTime')[0].firstChild.nodeValue)
	    #datetime.datetime.strptime(
            #times.getElementsByTagName('AimedDepartureTime')[0].firstChild.nodeValue, "%Y-%m-%dT%H:%M:%S.%fZ")
        try:
            departure['expected_departure'] = datetime.datetime.formisoformat(times.getElementsByTagName('ExpectedDepartureTime')[0].firstChild.nodeValue) #datetime.datetime.strptime(
                #times.getElementsByTagName('ExpectedDepartureTime')[0].firstChild.nodeValue, "%Y-%m-%dT%H:%M:%S.%fZ")
        except:
            departure['expected_departure'] = departure['scheduled_departure']

        departures.append(departure)

    return departures


def download_xml_to_file(stop_id, api_username, api_password, output_filename):

    request_timestamp = datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%S")
    message_ref = ''.join(random.choice(string.ascii_uppercase + string.digits) for _ in range(10))

    stop_monitoring_request = ET.Element('Siri', {
        'version': '1.0',
        'xmlns': "http://www.siri.org.uk/"
    })

    sr = ET.SubElement(stop_monitoring_request, 'ServiceRequest')
    ET.SubElement(sr, 'RequestTimestamp').text = request_timestamp
    ET.SubElement(sr, 'RequestorRef').text = api_username
    smr = ET.SubElement(sr, 'StopMonitoringRequest', {'version': "1.0"})
    ET.SubElement(smr, 'RequestTimestamp').text = request_timestamp
    ET.SubElement(smr, 'MessageIdentifier').text = message_ref
    ET.SubElement(smr, 'MonitoringRef').text = stop_id

    request_post_body = ET.tostring(stop_monitoring_request).decode()

    filename = output_filename + ".request.xml"
    with open(filename, 'w') as f:
        f.write(request_post_body)
        f.close()

    headers = {'Content-Type': 'application/xml'}
    resp = requests.post(nextbuses_url, data=request_post_body, headers=headers,
                         auth=requests.auth.HTTPBasicAuth(api_username, api_password))

    with open(output_filename, 'w') as f:
        f.write(resp.text)
        f.close()
