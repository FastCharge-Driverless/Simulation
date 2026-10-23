# Simulazione su Linux nativo (Ubuntu 22.04)

Tutto gira direttamente sul computer: ROS 2 Humble, lo stack di `as_workspace`, la
simulazione e il visualizzatore Unity. Con un altro sistema o senza voler installare
ROS: [DOCKER.md](DOCKER.md).

I comandi di questa pagina sono stati eseguiti così come sono scritti, da utente normale
con `sudo`, in un container `ros:humble-ros-base` pulito (ARM64): dalle dipendenze alla
simulazione headless e ai test, circa 13 minuti la prima volta, quasi tutti di download.
Il visualizzatore su Linux non è stato provato.

## Cosa serve

- **Ubuntu 22.04** con **ROS 2 Humble** installato
  ([guida ufficiale](https://docs.ros.org/en/humble/Installation/Ubuntu-Install-Debs.html),
  basta `ros-humble-ros-base`).
- **git** con una chiave SSH collegata a GitHub e accesso ai repo privati di
  FastCharge-Driverless (as_sim, stack) e a `extranerd/FSAE_Visualizer`.
- **Unity Hub** con la versione in `FSAE_Visualizer/ProjectSettings/ProjectVersion.txt`
  e il modulo "Linux Build Support". Serve solo per il visualizzatore.

## 1. Pacchetti di sistema

```bash
sudo apt update
sudo apt install -y git git-lfs python3-pip python3-colcon-common-extensions python3-rosdep ros-humble-foxglove-bridge
git lfs install
[ -f /etc/ros/rosdep/sources.list.d/20-default.list ] || sudo rosdep init
rosdep update --rosdistro humble
```

## 2. Clonare i due repo uno accanto all'altro

```bash
mkdir -p ~/fsc && cd ~/fsc
git clone --recurse-submodules -b dev git@github.com:FastCharge-Driverless/as_workspace.git
git clone --recurse-submodules git@github.com:FastCharge-Driverless/Simulation.git
```

Se le submodule si fermano con "could not read Username", stanno usando HTTPS: riprova
forzando SSH solo per quel comando, dentro ciascun repo:

```bash
git -c url."git@github.com:".insteadOf="https://github.com/" submodule update --init --recursive
```

Tutti i comandi successivi partono da `~/fsc`.

## 3. Dipendenze

```bash
cd ~/fsc
rosdep install --from-paths as_workspace/src --ignore-src --rosdistro humble -y --skip-keys "python3-torch python3-ortools pytest-asyncio camera_lidar_description"
bash Simulation/scripts/install_python_deps.sh
bash Simulation/scripts/setup_endpoint.sh
```

- rosdep solo su `as_workspace/src`: il suo `as_sim` dichiara le stesse dipendenze di
  quello in `Simulation`, e passarli entrambi dà "Multiple packages found".
- `install_python_deps.sh` installa le dipendenze Python con le versioni giuste
  (torch CPU, `numpy<2`, `ortools<9.15`, `numba`, `icecream`, `gpxpy`, `pytest==8.3.5`)
  nella tua cartella utente. `as_workspace/requirements.txt` è per la Jetson (CUDA).
- `setup_endpoint.sh` scarica ROS-TCP-Endpoint sul branch `main-ros2`: quello
  predefinito è per ROS1 e con Humble non compila.

## 4. Compilare

```bash
cd ~/fsc
bash Simulation/scripts/build_all.sh
```

Compila `as_workspace` (senza il suo `as_sim`, più vecchio) e poi `as_sim` di
Simulation. `low_level_control` e `as_hal_can` possono non compilare su alcuni branch:
servono solo ai livelli 5 e 6 (CAN), la simulazione funziona lo stesso.
Dopo un `git pull` rilancialo: ricompila solo quello che è cambiato.

## 5. Avviare la simulazione

In due terminali, da `~/fsc/Simulation`:

```bash
./start_endpoint.sh          # terminale 1: ponte per il visualizzatore, resta su tra le corse
./demo_sim.sh                # terminale 2: autocross, livello 4 (oppure ./demo_sim.sh skidpad)
```

A fine corsa lo stack si ferma da solo dopo 3 s. Da un terzo terminale:
`./sim_ctl.sh restart`, `./sim_ctl.sh track skidpad`, `./sim_ctl.sh status`.
`./launch_sim.sh` (avvio classico, senza stop automatico) funziona come prima.

## 6. Il visualizzatore

```bash
cd ~/fsc
Simulation/scripts/viewer.sh build    # una volta, con l'editor Unity chiuso (~3 min)
Simulation/scripts/viewer.sh run      # con endpoint e simulazione già avviati
```

Usa l'app e non l'editor in Play: con la stessa scena l'editor consuma circa 8 volte
la CPU. Se Unity non è nel percorso standard di Unity Hub:
`UNITY=/percorso/Editor/Unity Simulation/scripts/viewer.sh build`.

## Test

```bash
cd ~/fsc/Simulation/as_sim
source /opt/ros/humble/setup.bash && source ../../as_workspace/install/setup.bash && source ../install/setup.bash
python3 -m pytest test/ -q
```
