# FastCharge Driverless — Simulation Workspace

Repository principale per l'ambiente di simulazione e visualizzazione del team **FastCharge Driverless**.

Questo workspace raccoglie il simulatore veicolo/tracciati ROS 2 (`as_sim`), le interfacce ROS 2 (`common_interfaces`) e il visualizzatore 3D in Unity (`FSAE_Visualizer`) gestiti come **Git Submodules**.

---

## 🏗️ Architettura: I due Workspace Complementari

Per eseguire la simulazione con lo stack autonomo (livelli ≥ 1) o per utilizzare il visualizzatore Unity, **sono necessari entrambi i workspace affiancati**:

```text
cartella_progetti/ (es. Desktop/)
├── as_workspace/        <-- Repository dello stack autonomo (SLAM, Planning, Control, ros_tcp_endpoint)
└── Simulation/          <-- Questo repository (as_sim, common_interfaces, FSAE_Visualizer)
    ├── as_sim/
    ├── common_interfaces/
    └── FSAE_Visualizer/ (Progetto Unity)
```

1. **`Simulation`** (questo repository):
   - **`as_sim/`**: Simulatore dinamico/cinematico del veicolo, generazione tracciati (Skidpad, Acceleration, Autocross), sensori simulati e harness di valutazione metrica.
   - **`common_interfaces/`**: Interfacce e messaggi standard ROS 2 Humble.
   - **`FSAE_Visualizer/`**: Progetto Unity 3D per visualizzazione in tempo reale e telemetria.

2. **`as_workspace`** ([FastCharge-Driverless/as_workspace](https://github.com/FastCharge-Driverless/as_workspace)):
   - Contiene l'intero stack di guida autonoma sul branch **`dev`**: `as_slam`, `as_path_planning`, `as_high_level_control`, `as_execution_manager`, `as_msgs` e il nodo bridge **`ros_tcp_endpoint`** (necessario per collegare Unity a ROS 2).

---

## ⚙️ Prerequisiti di Sistema

- **OS**: Windows 10/11 con **WSL2 (Ubuntu 22.04 LTS)** *oppure* Ubuntu 22.04 LTS nativo.
- **ROS 2**: **Humble Hawksbill**.
- **Unity**: **Unity 6 (versione raccomandata: `6000.6.5f1`)** installabile da Unity Hub.
- **Git & Git LFS**: installati sia su Windows che in WSL.
- **Python**: Python 3.10+ in WSL con:
  ```bash
  pip install "packaging>=24" "setuptools<80"
  ```
  *(richiesto per evitare conflitti con colcon-core)*.

---

## 🚀 Guida Passo-Passo: Dalla Clonazione all'Esecuzione

### Passo 1: Clonare entrambi i repository (affiancati)

Posizionati nella cartella in cui tieni i tuoi progetti (es. `Desktop` o `~/projects`) ed esegui:

```bash
# 1. Clona lo stack autonomo (as_workspace)
git clone --recurse-submodules -b dev https://github.com/FastCharge-Driverless/as_workspace.git

# 2. Clona questo workspace di simulazione (Simulation)
git clone --recurse-submodules https://github.com/FastCharge-Driverless/Simulation.git
```

> [!IMPORTANT]
> **Aggiunta del bridge Unity (`ros_tcp_endpoint`) in `as_workspace`**:  
> Unity comunica con ROS 2 tramite il pacchetto `ros_tcp_endpoint`. Se non è già presente in `as_workspace/src`, clonalo manualmente:
> ```bash
> cd as_workspace/src
> git clone https://github.com/Unity-Technologies/ROS-TCP-Endpoint.git
> cd ../..
> ```

---

### Passo 2: Compilazione in ROS 2 (WSL / Ubuntu)

Compila prima lo stack di controllo e successivamente il simulatore:

```bash
# --- 1. Compila as_workspace ---
cd as_workspace
source /opt/ros/humble/setup.bash
colcon build --symlink-install

# --- 2. Compila Simulation ---
cd ../Simulation
source /opt/ros/humble/setup.bash
colcon build --symlink-install --packages-select as_sim
```

---

## 🏎️ Come Eseguire la Simulazione

### Metodo A: Avvio Diretto con Visualizzatore Unity (Consigliato)

1. Apri **Unity Hub** e apri il progetto presente in `Simulation/FSAE_Visualizer` (usando **Unity 6**).
2. Nella finestra *Project*, apri la scena:  
   `Assets/Scenes/SampleScene.unity`.
3. Premi **Play** ▶️.

**Cosa succede automaticamente?**
- Il componente `RosSessionLauncher` sulla scena:
  - Rileva in automatico i percorsi di `as_workspace` e `Simulation` sulla macchina dell'utente senza bisogno di configurazioni.
  - Avvia in WSL il bridge `ros_tcp_endpoint` sulla porta `10000`.
  - Lancia il simulatore (`ros2 launch as_sim sim.launch.py level:=4 track:=skidpad`).
  - Carica la mappa statica dei coni corrispondente al tracciato da `Assets/StreamingAssets/slam_maps/`.
  - Quando fermi il Play in Unity, chiude tutti i processi ROS in WSL.

---

### Metodo B: Avvio Manuale da Terminale (con o senza RViz)

Se preferisci avviare la simulazione direttamente da terminale WSL:

```bash
# 1. Sourcing di entrambi i workspace (Overlay)
source /opt/ros/humble/setup.bash
source ~/Desktop/as_workspace/install/setup.bash
source ~/Desktop/Simulation/install/setup.bash

# 2. Imposta l'isolamento della rete ROS
export ROS_DOMAIN_ID=97
export ROS_LOCALHOST_ONLY=1

# 3. Avvia la simulazione (es. Livello 4 - Closed Loop autonomo su Skidpad con RViz)
ros2 launch as_sim sim.launch.py level:=4 track:=skidpad rviz:=true eval:=true
```

#### Livelli di simulazione disponibili (`level:=0..6`):
- `level:=0`: Solo fisica veicolo e sensori (auto-drive lineare).
- `level:=1`: Veicolo + SLAM.
- `level:=2`: Veicolo + SLAM + Path Planning.
- `level:=3`: Stack open-loop completo.
- `level:=4` *(Default)*: Closed-loop completo: il controller HLC guida sterzo, acceleratore e freno del veicolo sulla traiettoria pianificata.
- `level:=5`: Include simulazione bus CAN su interfaccia `vcan0` (richiede `bash as_sim/scripts/setup_vcan.sh` una tantum).
- `level:=6`: Hardware-In-the-Loop (HIL) su interfaccia `can0` fisica.

---

## 🔄 Gestione e Aggiornamento dei Submodule

Per sincronizzare i sottomoduli con gli ultimi commit remoti:

```bash
git submodule update --init --recursive
```

Per aggiornare ciascun sottomodulo al branch più recente:
```bash
git submodule update --remote
```
