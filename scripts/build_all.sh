#!/bin/bash
# Compila as_workspace e Simulation (Linux nativo o dentro il container Docker).
#   bash scripts/build_all.sh [tier1|tier2|sim|all]   (default: all)
# tier1 = quello che serve alla simulazione livelli 0-4
# tier2 = il resto di as_workspace (CV, velodyne, HAL CAN, LLC/odrive), best effort
# sim   = as_sim di Simulation (l'unico as_sim compilato: quello in as_workspace è più vecchio)
set -eo pipefail

# La cartella che contiene as_workspace e Simulation, uno accanto all'altro.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WHAT=${1:-all}
# Con ~8 GB di RAM (Docker Desktop) di più e i build C++ (PCL/OpenCV) vengono uccisi.
export MAKEFLAGS=-j4
COLCON=(colcon build --symlink-install --parallel-workers 2
        --cmake-args -DCMAKE_BUILD_TYPE=Release)

source /opt/ros/humble/setup.bash

build_tier1() {
    cd "$ROOT/as_workspace"
    # Stesso ordine di scripts/build_workspace.sh: questi prima, poi il resto.
    "${COLCON[@]}" --packages-select as_msgs as_qos_profiles as_utils patchworkpp
    source install/setup.bash
    "${COLCON[@]}" --packages-skip as_sim --packages-skip-build-finished \
        --packages-up-to as_slam as_path_planning as_high_level_control \
                         as_execution_manager ros_tcp_endpoint
}

build_tier2() {
    cd "$ROOT/as_workspace"
    source install/setup.bash 2>/dev/null || true
    "${COLCON[@]}" --packages-skip as_sim --packages-skip-build-finished --continue-on-error
}

build_sim() {
    source "$ROOT/as_workspace/install/setup.bash"
    cd "$ROOT/Simulation"
    # --packages-select obbligatorio: common_interfaces sta nella root e
    # altrimenti verrebbe ricompilato, oscurando i messaggi di sistema.
    "${COLCON[@]}" --packages-select as_sim
}

case "$WHAT" in
    tier1) build_tier1 ;;
    tier2) build_tier2 ;;
    sim)   build_sim ;;
    all)   build_tier1; build_sim; build_tier2 ;;
    *)     echo "Uso: $0 [tier1|tier2|sim|all]"; exit 1 ;;
esac
