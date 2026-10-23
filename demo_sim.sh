#!/bin/bash
# FastCharge Driverless — Simulazione per demo, con riavvio e stop automatico
#
#   ./demo_sim.sh [TRACCIATO] [LIVELLO] [--loop] [--keep]
#     TRACCIATO  default autocross_default
#     LIVELLO    default 4
#     --loop     a fine corsa riparte da sola (demo in loop)
#     --keep     a fine corsa lo stack resta acceso (per ispezionare topic/RViz)
#
# A fine corsa lo stack si ferma dopo 3 s: la CPU torna a riposo.
# Riavvio/stop da un altro terminale: ./sim_ctl.sh restart|stop|start|status
# L'endpoint per Unity (start_endpoint.sh) va lanciato a parte e resta su.

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

TRACK=autocross_default
LEVEL=4
AUTO_RESTART=false
AUTO_STOP=3.0
POSITIONAL=()
for arg in "$@"; do
    case "$arg" in
        --loop) AUTO_RESTART=true ;;
        --keep) AUTO_STOP=-1.0 ;;
        *) POSITIONAL+=("$arg") ;;
    esac
done
[ -n "${POSITIONAL[0]}" ] && TRACK=${POSITIONAL[0]}
[ -n "${POSITIONAL[1]}" ] && LEVEL=${POSITIONAL[1]}

echo "=========================================================="
echo " [FSAE] Demo: Livello $LEVEL | Tracciato: $TRACK | loop: $AUTO_RESTART"
echo " Riavvio: ./sim_ctl.sh restart    Stop: Ctrl+C"
echo "=========================================================="

ros2 run as_sim run_manager --ros-args \
    -p level:=$LEVEL -p track:=$TRACK \
    -p auto_restart:=$AUTO_RESTART -p auto_stop_after_s:=$AUTO_STOP \
    -p extra_args:="rviz:=false eval:=false"
