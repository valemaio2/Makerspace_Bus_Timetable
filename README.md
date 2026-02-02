# Makerspace_Bus_Timetable
Automated bus/train timetable for the Makerspace
## Wiring
* 1 photocapacitor
* 1 1μF capacitor

- Leg 1 photoresistor to 3.3V on GPI
- Leg 2 of photoresistor to positive leg of capacitor
- Positive leg of capacitor to GPIO4 (defined in light_config.json)
- Negative leg of capacitor to GPIO GND

## Installation
```
bash <(curl -fsSL https://raw.githubusercontent.com/valemaio2/NextBus-GB-API-Python-parser/refs/heads/master/installer.sh)
bash <(curl -fsSL https://raw.githubusercontent.com/valemaio2/Makerspace_Bus_Timetable/refs/heads/main/install.sh)
```
Reboot

from the GUI:
```
/home/hackspace/enable-light-sensor-services.sh
```
Good luck, you're going to need it.
