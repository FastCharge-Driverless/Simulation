#!/bin/bash
# Dipendenze Python per far girare la simulazione (as_sim + stack di as_workspace).
# Unica fonte: la usano sia il Dockerfile sia chi installa su Linux nativo.
#
#   bash scripts/install_python_deps.sh
#
# Le dipendenze di sistema (apt) le installa rosdep, vedi docs/LINUX.md.
# as_workspace/requirements.txt è per la Jetson (CUDA, x86): qui torch è la
# versione CPU, che basta al planner in simulazione e gira anche su ARM.
set -e

# Da root (container) nel sistema, altrimenti nella cartella utente.
PIP="pip3 install --no-cache-dir"
[ "$(id -u)" -ne 0 ] && PIP="$PIP --user"

# numpy<2: i binding ROS di Humble sono compilati per numpy 1.x.
$PIP "numpy<2"
$PIP torch --index-url https://download.pytorch.org/whl/cpu
# ortools come nel setup.py di as_path_planning; porta numpy a 1.26.
$PIP "numpy<2" "ortools>=9.14,<9.15" torch_geometric pytest-asyncio
# scipy/sklearn/shapely di apt sono compilati per il numpy di Ubuntu: con 1.26
# danno errori, quindi le versioni pip, anche se apt ne ha già una.
$PIP --ignore-installed "numpy<2" scipy scikit-learn shapely
# pytest: dalla 9 il plugin launch_testing di Humble non si carica.
# numba/icecream: install_requires di as_path_planning, che colcon non installa
# (senza, autocross va in crash all'avvio del planner).
# gpxpy: usato dal random_track_generator di as_path_planning, non dichiarato.
$PIP "pytest==8.3.5" "pytest-asyncio<1" gpxpy "numpy<2" numba icecream
