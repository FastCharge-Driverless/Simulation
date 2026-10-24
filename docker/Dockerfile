# syntax=docker/dockerfile:1
# ROS 2 Humble per as_workspace + Simulation (amd64 o arm64, es. Mac Apple Silicon).
# Build context = la cartella che contiene as_workspace e Simulation;
# Dockerfile.dockerignore lascia passare solo i package.xml (rosdep risolve le
# dipendenze senza copiare i sorgenti) e lo script delle dipendenze Python.
FROM ros:humble-ros-base

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential git python3-pip python3-colcon-common-extensions \
        python3-rosdep ros-humble-foxglove-bridge can-utils iproute2 \
    && rm -rf /var/lib/apt/lists/*

# Dipendenze di sistema dichiarate nei package.xml.
# Saltate: sbg_driver/rtcm_msgs (sorgenti in as_workspace, se scaricati),
# torch/ortools/pytest-asyncio (via pip sotto, versione CPU),
# camera_lidar_description (pacchetto annidato in as_computer_vision, rosdep non lo vede).
COPY . /tmp/pkgs
RUN apt-get update && rosdep update --rosdistro humble \
    && rosdep install --from-paths /tmp/pkgs --ignore-src --rosdistro humble -y \
        --skip-keys "sbg_driver rtcm_msgs python3-torch python3-ortools pytest-asyncio camera_lidar_description" \
    && rm -rf /var/lib/apt/lists/* /tmp/pkgs

# Dipendenze Python: lo stesso script che usa chi installa su Linux nativo.
COPY Simulation/scripts/install_python_deps.sh /tmp/install_python_deps.sh
RUN bash /tmp/install_python_deps.sh && rm /tmp/install_python_deps.sh

# WS_ROOT lo imposta compose.yaml: è lo stesso percorso della cartella sul computer.
RUN echo 'source /opt/ros/humble/setup.bash' >> /root/.bashrc \
    && echo '[ -f "$WS_ROOT/as_workspace/install/setup.bash" ] && source "$WS_ROOT/as_workspace/install/setup.bash"' >> /root/.bashrc \
    && echo '[ -f "$WS_ROOT/Simulation/install/setup.bash" ] && source "$WS_ROOT/Simulation/install/setup.bash"' >> /root/.bashrc
