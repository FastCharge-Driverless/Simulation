#!/bin/bash
# Avvia o ferma tutta la demo con Docker.
#   Simulation/docker/demo.sh start [TRACCIATO] [--loop]   (default autocross_default)
#   Simulation/docker/demo.sh stop
# Su Mac apre le finestre in Terminale: 1 endpoint Unity, 2 simulazione,
# 3 visualizzatore, 4 pannello di controllo. Su Linux stampa i comandi da lanciare.
export WS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
COMPOSE="docker compose -f $WS_ROOT/Simulation/docker/compose.yaml"
SIM=$WS_ROOT/Simulation
MAC=false; [ "$(uname)" = Darwin ] && MAC=true

# Apre una finestra di Terminale con un titolo e ci lancia un comando.
open_window() {
    osascript >/dev/null <<EOF
tell application "Terminal"
    activate
    set w to do script "printf '\\\\e]0;$1\\\\a'; clear; $2"
end tell
EOF
}

# Chiude le finestre della demo (titoli impostati da open_window). Al contrario,
# perché chiudendone una le altre cambiano indice.
close_windows() {
    $MAC || return 0
    osascript >/dev/null 2>&1 <<EOF
tell application "Terminal"
    repeat with i from (count of windows) to 1 by -1
        set n to name of window i
        if n contains "1 Endpoint Unity" or n contains "2 Simulazione" or n contains "3 Visualizzatore" or n contains "4 Controllo" then
            close window i saving no
        end if
    end repeat
end tell
EOF
}

wait_for() {  # $1 = descrizione, $2 = comando di controllo, $3 = timeout s
    for _ in $(seq 1 "$3"); do
        eval "$2" >/dev/null 2>&1 && return 0
        sleep 1
    done
    echo "[!] Timeout: $1"; return 1
}

start() {
    TRACK=autocross_default
    LOOP=""
    for arg in "$@"; do
        case "$arg" in
            --loop) LOOP="--loop" ;;
            *) TRACK=$arg ;;
        esac
    done
    if ! docker info >/dev/null 2>&1; then
        echo "[*] Avvio Docker Desktop..."
        open -a Docker
        wait_for "Docker Desktop" "docker info" 90 || exit 1
    fi
    echo "[*] Container..."
    $COMPOSE up -d >/dev/null 2>&1 || { echo "[!] Container non avviato"; exit 1; }

    if docker exec fsc-ros pgrep -f "run_manager|default_server_endpoint" >/dev/null; then
        echo "[!] La demo è già avviata. Prima: $0 stop"; exit 1
    fi
    # Finestre rimaste da una demo precedente.
    close_windows

    ENDPOINT="docker exec -it fsc-ros bash $SIM/start_endpoint.sh"
    DEMO="docker exec -it fsc-ros bash $SIM/demo_sim.sh $TRACK 4 $LOOP"
    VIEWER="$SIM/scripts/viewer.sh run"
    CONTROL="$SIM/docker/control.sh"
    if ! $MAC; then
        echo "[OK] Container avviato. Lancia in quattro terminali, in quest'ordine:"
        echo "  1) $ENDPOINT"
        echo "  2) $DEMO"
        echo "  3) $VIEWER"
        echo "  4) $CONTROL"
        echo "Per chiudere tutto: $0 stop"
        return
    fi

    echo "[*] 1/4 Endpoint Unity"
    open_window "1 Endpoint Unity" "$ENDPOINT"
    wait_for "endpoint sulla porta 10000" "docker exec fsc-ros bash -c 'ss -ltn | grep -q :10000'" 30 || exit 1

    echo "[*] 2/4 Simulazione ($TRACK $LOOP)"
    open_window "2 Simulazione" "$DEMO"

    echo "[*] 3/4 Visualizzatore"
    open_window "3 Visualizzatore" "$VIEWER"

    echo "[*] 4/4 Pannello di controllo"
    open_window "4 Controllo" "$CONTROL"
    echo "[OK] Demo avviata. Per chiudere tutto: $0 stop"
}

stop() {
    echo "[*] Chiudo il visualizzatore..."
    pkill -f "FSAE_Visualizer.app/Contents/MacOS" 2>/dev/null
    pkill -f "$SIM/docker/control.sh" 2>/dev/null
    if docker exec fsc-ros true 2>/dev/null; then
        echo "[*] Fermo simulazione ed endpoint (chiusura ordinata)..."
        docker exec fsc-ros bash -c '
            pkill -INT -f "as_sim/lib/as_sim/run_manager"
            pkill -INT -f default_server_endpoint
            for _ in $(seq 1 20); do pgrep -f "install/.*/lib/|ros2 launch" >/dev/null || break; sleep 1; done
            pkill -f "install/.*/lib/" ; true'
        echo "[*] Fermo il container..."
        $COMPOSE stop >/dev/null 2>&1
    fi
    sleep 1
    close_windows
    echo "[OK] Tutto fermo, finestre della demo chiuse."
}

case "$1" in
    start) shift; start "$@" ;;
    stop) stop ;;
    *) echo "Uso: $0 start [TRACCIATO] [--loop] | stop"; exit 1 ;;
esac
