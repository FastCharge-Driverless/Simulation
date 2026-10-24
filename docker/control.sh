#!/bin/bash
# Pannello di controllo della demo (finestra 4 di demo.sh): un tasto per comando.
DOCKER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SIM="$(dirname "$DOCKER_DIR")"
CTL="docker exec fsc-ros bash $SIM/sim_ctl.sh"

while true; do
    echo
    echo "=========== Controllo demo ==========="
    echo "  r  nuova corsa (restart)"
    echo "  s  stato"
    echo "  p  ferma la corsa"
    echo "  a  avvia una corsa"
    echo "  t  cambia tracciato"
    echo "  q  chiudi tutta la demo"
    echo "======================================"
    read -r -n 1 -p "> " key
    echo
    case "$key" in
        r) $CTL restart ;;
        s) $CTL status ;;
        p) $CTL stop ;;
        a) $CTL start ;;
        t) read -r -p "Tracciato (skidpad, acceleration, autocross_default, autocross_dynamic): " name
           $CTL track "$name" ;;
        # In background: demo.sh stop chiude anche questa finestra, che deve
        # essere già libera (shell senza processi) per chiudersi senza conferme.
        q) nohup "$DOCKER_DIR/demo.sh" stop >/dev/null 2>&1 &
           exit 0 ;;
        *) echo "Tasto non valido" ;;
    esac
done
