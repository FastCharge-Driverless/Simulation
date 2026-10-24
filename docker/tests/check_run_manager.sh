#!/bin/bash
# Verifica run_manager nel container: stop a fine corsa, CPU a riposo, N riavvii.
#   docker exec fsc-ros bash <...>/Simulation/docker/tests/check_run_manager.sh [TRACCIATO] [N_RIAVVII]
TRACK=${1:-acceleration}
N=${2:-5}
SIM="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOG=/tmp/demo.log
# Job control: un job in background ha il suo gruppo e riceve SIGINT come da terminale.
set -m
source /opt/ros/humble/setup.bash
export ROS_DOMAIN_ID=97 ROS_LOCALHOST_ONLY=1

count_procs() { ps -eo args | grep -E "install/.*/lib/|ros2 launch as_sim" | grep -vc grep; }
wait_status() {  # $1 = stato, $2 = occorrenza attesa, $3 = timeout s
    for _ in $(seq 1 $(( $3 * 2 ))); do
        [ "$(grep -c "Run status: $1" $LOG)" -ge "$2" ] && return 0
        sleep 0.5
    done
    return 1
}
# CPU totale del container in "% di un core", come docker stats.
cpu() { top -bn2 -d1 | grep '^%Cpu' | tail -1 | awk -v n="$(nproc)" '{printf "%.0f", (100-$8)*n}'; }
sub() { awk "BEGIN{printf \"%.1f\", $1 - $2}"; }

echo "processi stack prima: $(count_procs)"
bash $SIM/demo_sim.sh $TRACK > $LOG 2>&1 &
DEMO=$!

for i in $(seq 1 $((N + 1))); do
    t0=$(date +%s.%N)
    wait_status RUNNING $i 90 || { echo "corsa $i: non parte"; break; }
    t_drive=$(date +%s.%N)
    wait_status FINISHED $i 180 || { echo "corsa $i: non finisce"; break; }
    t_fin=$(date +%s.%N)
    wait_status STOPPED $i 40 || { echo "corsa $i: non si ferma"; break; }
    t_stop=$(date +%s.%N)
    sleep 1
    printf "corsa %d: avvio->guida %ss | fine->stack fermo %ss | CPU a riposo %s%% | processi stack %s\n" \
        $i "$(sub $t_drive $t0)" "$(sub $t_stop $t_fin)" "$(cpu)" "$(count_procs)"
    [ $i -le $N ] && bash $SIM/sim_ctl.sh restart > /dev/null
done

echo "AS_EMERGENCY nel log: $(grep -c 'AS_EMERGENCY' $LOG)"
echo "FAILED nel log: $(grep -c 'Run status: FAILED' $LOG)"
kill -INT -- -$DEMO; wait $DEMO 2>/dev/null
sleep 2
echo "processi stack dopo Ctrl+C: $(count_procs)"
