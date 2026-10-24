#!/bin/bash
# FastCharge Driverless — Avvio Simulatore e Stack Autonomo

source /opt/ros/humble/setup.bash

SIM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AS_DIR="$(cd "$SIM_DIR/../as_workspace" 2>/dev/null && pwd)"

if [ -f "$AS_DIR/install/setup.bash" ]; then
    source "$AS_DIR/install/setup.bash"
else
    echo "[!] Errore: $AS_DIR/install/setup.bash non trovato. Compila as_workspace prima!"
    exit 1
fi

if [ -f "$SIM_DIR/install/setup.bash" ]; then
    source "$SIM_DIR/install/setup.bash"
else
    echo "[!] Errore: $SIM_DIR/install/setup.bash non trovato. Compila Simulation prima!"
    exit 1
fi

export ROS_DOMAIN_ID=97
export ROS_LOCALHOST_ONLY=1

LEVEL=${1:-4}
TRACK=${2:-skidpad}

echo "=========================================================="
echo " [FSAE] Avvio as_sim: Livello $LEVEL | Tracciato: $TRACK"
echo "=========================================================="

ros2 launch as_sim sim.launch.py level:=$LEVEL track:=$TRACK rviz:=false eval:=false
