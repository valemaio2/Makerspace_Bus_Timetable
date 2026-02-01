#!/bin/bash

set -e

USER_HOME="/home/$USER"
PROJECT_DIR="$USER_HOME/NextBus-GB-API-Python-parser"
SYSTEMD_USER_DIR="$USER_HOME/.config/systemd/user"

echo "=============================================="
echo " Light Sensor Display Controller Installation"
echo " Raspberry Pi OS 13 (Wayland, Full Desktop)"
echo "=============================================="
echo

# ---------------------------------------------------------
# 1. Install required packages
# ---------------------------------------------------------
echo "[1/7] Installing required packages..."
sudo apt update
sudo apt install -y python3 python3-pip python3-rpi.gpio wlr-randr wlopm

# ---------------------------------------------------------
# 2. Ensure Desktop Autologin is enabled
# ---------------------------------------------------------
echo
echo "[2/7] IMPORTANT: Ensure Desktop Autologin is enabled."
echo "Run: sudo raspi-config → System Options → Boot / Auto Login → Desktop Autologin"
echo "This script will continue, but the system will not work without autologin."
echo

# ---------------------------------------------------------
# 3. Enable user lingering
# ---------------------------------------------------------
echo "[3/7] Enabling user lingering for $USER..."
sudo loginctl enable-linger "$USER"

# ---------------------------------------------------------
# 4. Create project directory + download light sensor files
# ---------------------------------------------------------
echo "[4/7] Creating project directory at $PROJECT_DIR..."
mkdir -p "$PROJECT_DIR"

echo "[4/7] Downloading light sensor files into $PROJECT_DIR..."

curl -fsSL \
  -o "$PROJECT_DIR/light_check.py" \
  "https://raw.githubusercontent.com/valemaio2/Makerspace_Bus_Timetable/refs/heads/main/light_check.py"

curl -fsSL \
  -o "$PROJECT_DIR/light_config.json" \
  "https://raw.githubusercontent.com/valemaio2/Makerspace_Bus_Timetable/refs/heads/main/light_config.json"

curl -fsSL \
  -o "$PROJECT_DIR/update.sh" \
  "https://raw.githubusercontent.com/valemaio2/Makerspace_Bus_Timetable/refs/heads/main/update.sh"

# Ensure update.sh is executable
chmod +x "$PROJECT_DIR/update.sh"

echo "Downloaded:"
echo " - $PROJECT_DIR/light_check.py"
echo " - $PROJECT_DIR/light_config.json"
echo " - $PROJECT_DIR/update.sh"
echo

# ---------------------------------------------------------
# 5. Create systemd user directory
# ---------------------------------------------------------
echo "[5/7] Creating systemd user directory..."
mkdir -p "$SYSTEMD_USER_DIR"

# ---------------------------------------------------------
# 6. Install monitorctl@.service
# ---------------------------------------------------------
echo "[6/7] Installing monitorctl@.service..."

cat > "$SYSTEMD_USER_DIR/monitorctl@.service" << 'EOF'
[Unit]
Description=Monitor Power Control (%i)

[Service]
Type=oneshot
Environment=WAYLAND_DISPLAY=wayland-0
Environment=XDG_RUNTIME_DIR=/run/user/1000
ExecStart=/usr/bin/wlopm --%i HDMI-A-1
EOF

# ---------------------------------------------------------
# 7. Install lightcheck service + timer
# ---------------------------------------------------------
echo "[7/7] Installing lightcheck.service and lightcheck.timer..."

cat > "$SYSTEMD_USER_DIR/lightcheck.service" << 'EOF'
[Unit]
Description=Light Sensor Check and Monitor Control
BindsTo=graphical-session.target
After=graphical-session.target

[Service]
Type=oneshot
ExecStart=/usr/bin/python3 %h/NextBus-GB-API-Python-parser/light_check.py
EOF

cat > "$SYSTEMD_USER_DIR/lightcheck.timer" << 'EOF'
[Unit]
Description=Run light_check every 5 minutes

[Timer]
OnBootSec=30
OnUnitActiveSec=5min
Unit=lightcheck.service

[Install]
WantedBy=timers.target
EOF

# ---------------------------------------------------------
# Reload + enable (DEFERRED UNTIL USER SESSION EXISTS)
# ---------------------------------------------------------
echo
echo "Systemd user services installed, but cannot be enabled yet."
echo "This is normal on Raspberry Pi OS 13 (Wayland)."
echo

ENABLE_SCRIPT="$USER_HOME/enable-light-sensor-services.sh"

cat > "$ENABLE_SCRIPT" << EOF
#!/bin/bash
echo "Enabling light sensor services..."
systemctl --user daemon-reload
systemctl --user enable --now lightcheck.timer
echo "Services enabled successfully."
echo "Rebooting now..."
sleep 2
sudo reboot
EOF

chmod +x "$ENABLE_SCRIPT"
chown "$USER:$USER" "$ENABLE_SCRIPT"

RED="\e[1;31m"
RESET="\e[0m"

echo "============================================================"
echo " Installation complete!"
echo "============================================================"
echo
echo -e "${RED}IMPORTANT:${RESET}"
echo "After reboot, log in as $USER on the desktop and run:"
echo "  $ENABLE_SCRIPT"
echo
echo "This will enable the systemd user services correctly. The system will reboot again."
echo
echo "After that:"
echo " - Monitor turns off in the dark"
echo " - Monitor turns on in the light"
echo " - Script runs every 5 minutes"

