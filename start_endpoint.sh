#!/bin/bash
# FastCharge Driverless — Avvio del bridge ROS-TCP-Endpoint per Unity

source /opt/ros/humble/setup.bash

# Individua i percorsi dei workspace
SIM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AS_DIR="$(cd "$SIM_DIR/../as_workspace" 2>/dev/null && pwd)"

if [ -f "$AS_DIR/install/setup.bash" ]; then
    source "$AS_DIR/install/setup.bash"
else
    echo "[!] Attenzione: $AS_DIR/install/setup.bash non trovato. Compila as_workspace prima!"
fi

if [ -f "$SIM_DIR/install/setup.bash" ]; then
    source "$SIM_DIR/install/setup.bash"
fi

export ROS_DOMAIN_ID=97
export ROS_LOCALHOST_ONLY=1

echo "=========================================================="
echo " [FSAE] Avvio ROS-TCP-Endpoint per Unity sulla porta 10000..."
echo " Una volta avviato, premi PLAY in Unity!"
echo "=========================================================="

ros2 run ros_tcp_endpoint default_server_endpoint --ros-args -p ROS_IP:=0.0.0.0
