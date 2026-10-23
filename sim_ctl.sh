#!/bin/bash
# FastCharge Driverless — Comandi per la simulazione avviata con demo_sim.sh
#
#   ./sim_ctl.sh restart   ferma la corsa (se c'è) e ne lancia una nuova
#   ./sim_ctl.sh stop      ferma la corsa
#   ./sim_ctl.sh start     lancia una corsa se non ce n'è una
#   ./sim_ctl.sh status    stato attuale (STARTING, RUNNING, FINISHED, STOPPED, ...)

source /opt/ros/humble/setup.bash

SIM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SIM_DIR/install/setup.bash" ]; then
    source "$SIM_DIR/install/setup.bash"
fi

export ROS_DOMAIN_ID=97
export ROS_LOCALHOST_ONLY=1

case "$1" in
    restart|stop|start)
        ros2 service call "/sim/run/$1" std_srvs/srv/Trigger | grep -E "success|message"
        ;;
    status)
        timeout 5 ros2 topic echo --once /sim/run/status std_msgs/msg/String \
            --qos-durability transient_local --qos-reliability reliable | grep data \
            || echo "Nessun run_manager attivo (demo_sim.sh è avviato?)"
        ;;
    *)
        echo "Uso: $0 restart|stop|start|status"
        exit 1
        ;;
esac
