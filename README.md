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
   - **`as_sim/`**: Simulatore dinamico/cinematico del veicolo, generazione tracciati (Skidpad, Acceleration, Autocross), sensori simulati e giudice di gara.
   - **`common_interfaces/`**: Interfacce e messaggi standard ROS 2 Humble.
   - **`FSAE_Visualizer/`**: Progetto Unity 3D per visualizzazione in tempo reale e telemetria.

2. **`as_workspace`** ([FastCharge-Driverless/as_workspace](https://github.com/FastCharge-Driverless/as_workspace)):
   - Contiene l'intero stack di guida autonoma: `as_slam`, `as_path_planning`, `as_high_level_control`, `as_execution_manager`, `as_msgs` e il nodo bridge **`ros_tcp_endpoint`** (necessario per collegare Unity a ROS 2).

---

## ⚙️ Prerequisiti

- **OS / Ambiente ROS 2**: Ubuntu 22.04 LTS nativo oppure Windows 10/11 con **WSL2 (Ubuntu 22.04)**.
- **ROS 2**: ROS 2 **Humble Hawksbill**.
- **Python**: Python 3.10+ con dipendenze del simulatore (`colcon`, `pytest`, `packaging>=24`, `setuptools<80`).
- **Unity**: Unity Editor (consigliata versione LTS 2022.3 o superiore) per `FSAE_Visualizer`.

---

## 🚀 Installazione e Configurazione

### 1. Clonare entrambi i repository (affiancati)

Posizionati nella cartella desiderata (es. `Desktop` o `~/projects`) e clona entrambi i repository con i rispettivi sottomoduli:

```bash
# 1. Clona lo stack autonomo (as_workspace)
git clone --recurse-submodules https://github.com/FastCharge-Driverless/as_workspace.git

# 2. Clona questo workspace di simulazione (Simulation)
git clone --recurse-submodules https://github.com/FastCharge-Driverless/Simulation.git
```

> [!TIP]
> Se hai già clonato senza `--recurse-submodules`, puoi inizializzare i sottomoduli entrando nella cartella ed eseguendo:
> ```bash
> git submodule update --init --recursive
> ```

---

### 2. Compilazione in ROS 2 (WSL / Ubuntu)

Compila prima `as_workspace` e successivamente `Simulation`:

```bash
# --- Compilazione as_workspace ---
cd as_workspace
source /opt/ros/humble/setup.bash
colcon build --symlink-install

# --- Compilazione Simulation ---
cd ../Simulation
source /opt/ros/humble/setup.bash
colcon build --symlink-install --packages-select as_sim
```

---

## 🏎️ Esecuzione della Simulazione

### Sourcing contemporaneo dei due workspace (Overlay)

Per eseguire missioni con lo stack (`level:=1` o superiore), è indispensabile effettuare il source di entrambi i workspace:

```bash
source /opt/ros/humble/setup.bash
source <percorso>/as_workspace/install/setup.bash
source <percorso>/Simulation/install/setup.bash
```

### Livelli di simulazione disponibili (`level:=0..6`)

Il simulatore supporta diversi livelli di integrazione:
- `level:=0`: Solo dinamica veicolo e sensori simulati.
- `level:=1`: Veicolo + SLAM.
- `level:=2`: Veicolo + SLAM + Path Planning.
- `level:=3`: Stack open-loop completo.
- `level:=4` *(Default)*: Closed-loop completo: il controller HLC guida la fisica del veicolo.
- `level:=5`: Include simulazione CAN su interfaccia `vcan0`.
- `level:=6`: Hardware-In-the-Loop (HIL) su bus CAN reale `can0`.

Esempio di avvio simulatore headless / con RViz:
```bash
ros2 launch as_sim sim.launch.py level:=4 track:=skidpad rviz:=true eval:=true
```

---

## 🎮 Visualizzatore 3D in Unity (`FSAE_Visualizer`)

1. Apri **Unity Hub** e aggiungi il progetto dalla cartella `Simulation/FSAE_Visualizer`.
2. Apri la scena principale: `Assets/Scenes/SampleScene.unity`.
3. Premi **Play** nell'editor di Unity.

### 🔌 Come funziona l'integrazione automatica con WSL:
Il componente `RosSessionLauncher` presente nella scena:
- **Rileva automaticamente** i percorsi di `as_workspace` e `Simulation` (grazie al posizionamento affiancato delle cartelle), convertendoli nel formato WSL `/mnt/<disco>/...` senza richiedere alcuna modifica manuale tra sviluppatori diversi.
- Avvia automaticamente all'interno di WSL sia il bridge `ros_tcp_endpoint` che il simulatore `as_sim`.
- Chiude in modo pulito tutti i processi ROS al termine della sessione di Play.

> [!NOTE]
> Se `as_workspace` si trova in una directory personalizzata (es. `/home/username/...` all'interno del filesystem nativo di WSL), puoi inserire direttamente il percorso desiderato nel campo **As Workspace Path** del componente `RosSessionLauncher` nell'Inspector di Unity.
