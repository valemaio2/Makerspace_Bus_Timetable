#!/bin/bash

set -e

USER_NAME="hackspace"
USER_HOME="/home/$USER_NAME"
PROJECT_DIR="$USER_HOME/buses-api"
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
echo "[3/7] Enabling user lingering for $USER_NAME..."
sudo loginctl enable-linger "$USER_NAME"

# ---------------------------------------------------------
# 4. Create project directory
# ---------------------------------------------------------
echo "[4/7] Creating project directory at $PROJECT_DIR..."
mkdir -p "$PROJECT_DIR"

echo "Place your files into $PROJECT_DIR:"
echo " - light_check.py"
echo " - light_config.json"
echo " - update.sh"
echo " - any HTML/template files"
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
ExecStart=/usr/bin/python3 /home/hackspace/buses-api/light_check.py
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
# Reload + enable
# ---------------------------------------------------------
echo
echo "Reloading systemd user units..."
sudo -u "$USER_NAME" systemctl --user daemon-reload

echo "Enabling lightcheck.timer..."
sudo -u "$USER_NAME" systemctl --user enable --now lightcheck.timer

echo
echo "============================================================"
echo " Installation complete!"
echo "============================================================"
echo
echo "Before rebooting, ensure your project files exist in:"
echo "  $PROJECT_DIR"
echo
echo "Then reboot:"
echo "  sudo reboot"
echo
echo "After reboot:"
echo " - Monitor turns off in the dark"
echo " - Monitor turns on in the light"
echo " - Chromium loads correctly"
echo " - Script runs every 5 minutes"
echo
