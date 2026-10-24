#!/bin/bash
# Prima installazione con Docker: endpoint Unity, immagine, container, compilazione.
#   Simulation/docker/setup.sh            (rifarlo dopo un git pull ricompila)
# Richiede as_workspace clonato accanto a Simulation. Prima volta: ~15-20 min.
set -e
export WS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
COMPOSE="docker compose -f $WS_ROOT/Simulation/docker/compose.yaml"

[ -d "$WS_ROOT/as_workspace/src" ] || {
    echo "[!] Manca $WS_ROOT/as_workspace: va clonato accanto a Simulation (vedi docs/DOCKER.md)."; exit 1; }
docker info >/dev/null 2>&1 || { echo "[!] Docker non è avviato."; exit 1; }

echo "[*] 1/3 ROS-TCP-Endpoint"
bash "$WS_ROOT/Simulation/scripts/setup_endpoint.sh"
echo "[*] 2/3 Immagine e container (la prima volta scarica ROS e PyTorch)"
$COMPOSE up -d --build
echo "[*] 3/3 Compilazione di as_workspace e Simulation"
docker exec fsc-ros bash "$WS_ROOT/Simulation/scripts/build_all.sh" all \
    || echo "[i] Qualche pacchetto non compila (vedi sopra). Se sono solo low_level_control /
    as_hal_can / as_computer_vision la simulazione (livelli 0-4) funziona lo stesso."
echo "[OK] Pronto. Avvio: $WS_ROOT/Simulation/docker/demo.sh start"
