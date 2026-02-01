import RPi.GPIO as GPIO
import time
import json
import subprocess
import os

# Load config
with open("%h/NextBus-GB-API-Python-parser/light_config.json") as f:
    cfg = json.load(f)

PIN = cfg["pin"]
THRESHOLD = cfg["threshold"]
DURATION = cfg["duration_seconds"]

LOGFILE = "%h/NextBus-GB-API-Python-parser/light.log"

# LOGGING ENABLED - use only one!
#def log(msg):
#    with open(LOGFILE, "a") as f:
#        f.write(time.strftime("%Y-%m-%d %H:%M:%S ") + msg + "\n")

# LOGGING DISABLED - use only one!
def log(msg):
    pass

GPIO.setmode(GPIO.BCM)

def read_light(pin):
    reading = 0
    GPIO.setup(pin, GPIO.OUT)
    GPIO.output(pin, GPIO.LOW)
    time.sleep(1)
    GPIO.setup(pin, GPIO.IN)
    while GPIO.input(pin) == GPIO.LOW:
        reading += 1
    return reading

start = time.time()
bright_detected = False

# Sample light for DURATION seconds
while time.time() - start < DURATION:
    value = read_light(PIN)
    log(f"Light reading: {value}")

    if value < THRESHOLD:
        bright_detected = True
        break

    time.sleep(1)

GPIO.cleanup()

if bright_detected:
    log("Brightness detected → turning monitor ON")
    subprocess.run(
        ["systemctl", "--user", "start", "monitorctl@on"],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL
    )

    log("Running update.sh")
    subprocess.run(
        ["%h/NextBus-GB-API-Python-parser/update.sh"],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL
    )

else:
    log("Too dark → turning monitor OFF and skipping update")
    subprocess.run(
        ["systemctl", "--user", "start", "monitorctl@off"],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL
