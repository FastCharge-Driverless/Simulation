#!/bin/bash
# Scarica ROS-TCP-Endpoint (ponte ROS 2 <-> Unity) in as_workspace/src, se manca.
# Il branch predefinito del repo è la versione ROS1, che con Humble non compila:
# serve main-ros2.
set -e
WS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DEST="$WS_ROOT/as_workspace/src/ROS-TCP-Endpoint"

if [ ! -d "$WS_ROOT/as_workspace/src" ]; then
    echo "[!] $WS_ROOT/as_workspace/src non trovato: as_workspace va clonato accanto a Simulation."
    exit 1
fi
if [ -d "$DEST" ]; then
    echo "[OK] ROS-TCP-Endpoint già presente ($(git -C "$DEST" branch --show-current))"
    exit 0
fi
git clone -b main-ros2 https://github.com/Unity-Technologies/ROS-TCP-Endpoint.git "$DEST"
