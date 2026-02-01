# Makerspace_Bus_Timetable
Automated bus/train timetable for the Makerspace

Install main python program from:
https://github.com/valemaio2/NextBus-GB-API-Python-parser

============================================================
Raspberry Pi OS 13 – Light Sensor Display Controller Install
============================================================

This guide installs the light sensor script, monitor power
control, and systemd user timer on a Raspberry Pi running
Raspberry Pi OS 13 with the full Wayland desktop.

GPIO wiring and pin assignments match the original system.

------------------------------------------------------------
1. Install required packages
------------------------------------------------------------

sudo apt update
sudo apt install -y python3 python3-pip python3-rpi.gpio wlr-randr wlopm

------------------------------------------------------------
2. Enable Desktop Autologin (required for Wayland)
------------------------------------------------------------

sudo raspi-config

Navigate:
System Options → Boot / Auto Login → Desktop Autologin

------------------------------------------------------------
3. Enable user lingering (run user services without terminal)
------------------------------------------------------------

sudo loginctl enable-linger hackspace

(Replace "hackspace" with your username if different.)

------------------------------------------------------------
4. Create project directory
------------------------------------------------------------

mkdir -p /home/hackspace/buses-api
cd /home/hackspace/buses-api

Copy the following files into this directory:
- light_check.py
- light_config.json
- update.sh
- any HTML/template files used by your update pipeline

Make update.sh executable:

chmod +x update.sh

------------------------------------------------------------
5. Create systemd user service for monitor control
------------------------------------------------------------

mkdir -p /home/hackspace/.config/systemd/user
nano /home/hackspace/.config/systemd/user/monitorctl@.service

Paste:

[Unit]
Description=Monitor Power Control (%i)

[Service]
Type=oneshot
Environment=WAYLAND_DISPLAY=wayland-0
Environment=XDG_RUNTIME_DIR=/run/user/1000
ExecStart=/usr/bin/wlopm --%i HDMI-A-1

(If your monitor name differs, change HDMI-A-1.)

------------------------------------------------------------
6. Create the lightcheck service
------------------------------------------------------------

nano /home/hackspace/.config/systemd/user/lightcheck.service

Paste:

[Unit]
Description=Light Sensor Check and Monitor Control
BindsTo=graphical-session.target
After=graphical-session.target

[Service]
Type=oneshot
ExecStart=/usr/bin/python3 /home/hackspace/buses-api/light_check.py

------------------------------------------------------------
7. Create the timer (runs every 5 minutes)
------------------------------------------------------------

nano /home/hackspace/.config/systemd/user/lightcheck.timer

Paste:

[Unit]
Description=Run light_check every 5 minutes

[Timer]
OnBootSec=30
OnUnitActiveSec=5min
Unit=lightcheck.service

[Install]
WantedBy=timers.target

------------------------------------------------------------
8. Reload systemd user units and enable timer
------------------------------------------------------------

systemctl --user daemon-reload
systemctl --user enable --now lightcheck.timer

(Optional: enable monitorctl template so systemd recognizes it)
systemctl --user enable monitorctl@on.service

------------------------------------------------------------
9. Reboot and verify
------------------------------------------------------------

sudo reboot

After reboot:
- Chromium should load normally
- Monitor should turn off in the dark
- Monitor should turn on in the light
- light_check.py should run every 5 minutes
- No blank screen issues

------------------------------------------------------------
10. To check monitor name (optional)
------------------------------------------------------------

wlr-randr

If different from HDMI-A-1, edit:

nano ~/.config/systemd/user/monitorctl@.service

Change:
ExecStart=/usr/bin/wlopm --%i HDMI-A-1

Then reload:
systemctl --user daemon-reload

============================================================
Installation complete.
============================================================
