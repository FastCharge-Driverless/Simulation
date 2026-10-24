#!/bin/bash
# Verifica nel container: validazione e cambio tracciato, /sim/run/state, emergenza.
#   docker exec fsc-ros bash <...>/Simulation/docker/tests/check_tracks.sh
set -m
SIM="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOG=/tmp/demo.log
source /opt/ros/humble/setup.bash
source "$(dirname "$SIM")/as_workspace/install/setup.bash" 2>/dev/null
source $SIM/install/setup.bash
export ROS_DOMAIN_ID=97 ROS_LOCALHOST_ONLY=1

state() { timeout 5 ros2 topic echo --once /sim/run/state std_msgs/msg/String | sed -n 's/^data: //p'; }
wait_log() {  # $1 = testo, $2 = occorrenze, $3 = timeout s
    for _ in $(seq 1 $(( $3 * 2 ))); do
        [ "$(grep -c "$1" $LOG)" -ge "$2" ] && return 0; sleep 0.5
    done; echo "  [timeout su '$1']"; return 1
}

echo "1) demo_sim.sh con tracciato sbagliato"
bash $SIM/demo_sim.sh skidpadd 4 > $LOG 2>&1; echo "   uscita=$?"; grep -o "Unknown track.*" $LOG | head -1

echo "2) sim.launch.py con tracciato sbagliato"
timeout 20 ros2 launch as_sim sim.launch.py track:=skidpadd level:=0 2>&1 | grep -m1 -o "Unknown track[^.]*"

echo "3) avvio su acceleration, stato pubblicato"
bash $SIM/demo_sim.sh acceleration 4 > $LOG 2>&1 &
DEMO=$!
wait_log "Run status: RUNNING" 1 90
echo "   $(state)"

echo "4) cambio tracciato con nome sbagliato a corsa in corso"
bash $SIM/sim_ctl.sh track skidpadd > /dev/null
echo "   $(state)"
echo "   processi launch: $(pgrep -fc 'ros2 launch as_sim')"

echo "5) emergenza a metà corsa (come da Unity: Empty su /sim/btn/emergency)"
ros2 topic pub --once -w 1 /sim/btn/emergency std_msgs/msg/Empty "{}" > /dev/null
wait_log "Run status: FINISHED" 1 30
grep -E "EM State transitioned to: AS_EMERGENCY" $LOG | tail -1 | grep -o "AS_EMERGENCY"
wait_log "Run status: STOPPED" 1 30 && echo "   stack fermato dopo l'emergenza"

echo "6) cambio tracciato su skidpad (riparte dallo stato fermo)"
bash $SIM/sim_ctl.sh track skidpad > /dev/null
wait_log "Run status: RUNNING" 2 90
echo "   $(state)"
grep "Loaded track" $LOG | tail -1 | grep -o "Loaded track '[^']*'"

kill -INT -- -$DEMO; wait $DEMO 2>/dev/null; sleep 2
echo "processi stack dopo Ctrl+C: $(pgrep -fc 'install/.*/lib/|ros2 launch')"
