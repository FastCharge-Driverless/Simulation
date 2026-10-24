# Simulazione con Docker (Mac, Linux)

ROS 2 Humble, lo stack di `as_workspace` e la simulazione girano in un container;
il visualizzatore Unity gira sul computer e si collega al container sulla porta 10000.
Va bene su **Mac (anche Apple Silicon)** e su **Linux** con qualsiasi distribuzione.
Se hai Ubuntu 22.04 puoi anche fare tutto senza Docker: [LINUX.md](LINUX.md).

Testato su Mac M5 con Docker Desktop. Su Linux gli stessi comandi, ma non ancora provati.

## Cosa serve

- **Docker**: Docker Desktop (Mac) oppure Docker Engine + plugin `compose` (Linux).
  Almeno 8 GB di RAM assegnati a Docker e ~15 GB di disco.
- **git** con una chiave SSH collegata a GitHub e accesso ai repo privati di
  FastCharge-Driverless (as_sim, stack) e a `extranerd/FSAE_Visualizer`.
- **Git LFS** (`brew install git-lfs` / `sudo apt install git-lfs`, poi `git lfs install`).
- **Unity Hub** con la versione scritta in
  `FSAE_Visualizer/ProjectSettings/ProjectVersion.txt`, più il modulo di build per il
  tuo sistema (Mac Build Support o Linux Build Support). Serve solo per il visualizzatore.

## 1. Clonare i due repo uno accanto all'altro

```bash
mkdir fsc && cd fsc
git clone --recurse-submodules -b dev git@github.com:FastCharge-Driverless/as_workspace.git
git clone --recurse-submodules git@github.com:FastCharge-Driverless/Simulation.git
```

`as_workspace` sul branch `dev`, come indicato dal team.

Se le submodule si fermano con "could not read Username", stanno usando HTTPS: riprova
forzando SSH solo per quel comando, dentro ciascun repo:

```bash
git -c url."git@github.com:".insteadOf="https://github.com/" submodule update --init --recursive
```

## 2. Preparare tutto (una volta)

```bash
Simulation/docker/setup.sh
```

Scarica ROS-TCP-Endpoint (branch `main-ros2`), costruisce l'immagine, avvia il container
`fsc-ros` e compila. La prima volta servono 15-20 minuti. Dopo un `git pull` rilancialo:
ricompila solo quello che è cambiato.

`low_level_control` e `as_hal_can` possono non compilare su alcuni branch di
`as_workspace`: servono solo ai livelli 5 e 6 (CAN), la simulazione funziona lo stesso.

## 3. Il visualizzatore (una volta, e dopo ogni modifica alla scena)

```bash
Simulation/scripts/viewer.sh build
```

Con l'editor Unity chiuso, ~3 minuti. Crea l'app in `fsc/builds/`. Usa l'app e non
l'editor in Play: con la stessa scena l'editor consuma circa 8 volte la CPU.

## 4. Avviare la demo

```bash
Simulation/docker/demo.sh start
```

- **Mac**: apre quattro finestre di Terminale (endpoint, simulazione, visualizzatore,
  pannello di controllo). `Simulation/docker/demo.sh stop` chiude tutto, finestre comprese.
- **Linux**: avvia il container e stampa i quattro comandi da lanciare in quattro terminali.

Opzioni: un altro tracciato (`demo.sh start skidpad`), `--loop` per ripartire da sola
a ogni fine corsa. Dal visualizzatore: Nuova corsa, Stop, EMERGENZA e cambio tracciato.

## Comandi utili

```bash
docker exec -it fsc-ros bash                                    # shell con ROS già pronto
docker exec fsc-ros bash "$PWD/Simulation/scripts/build_all.sh" sim   # ricompila solo as_sim
docker compose -f Simulation/docker/compose.yaml stop          # ferma il container
```

Dentro il container i percorsi sono gli stessi del computer: modifichi il codice con il
tuo editor e ricompili nel container. `build/`, `install/` e `log/` stanno in volumi
Docker, non nei repo.

## Limiti

- Livelli 5 e 6 (bus CAN): non funzionano, Docker Desktop non ha `vcan`.
- torch è la versione CPU (basta al planner in simulazione); niente CUDA.
- Il container gira come root. Su Linux, se nella stessa cartella compili anche senza
  Docker, cancella prima le cartelle `build/ install/ log/` vuote create da Docker.
