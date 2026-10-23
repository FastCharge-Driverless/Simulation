#!/bin/bash
# Visualizzatore Unity come app standalone: ~25% di CPU contro ~200% dell'editor in Play.
#   scripts/viewer.sh build   crea l'app in <cartella progetti>/builds (editor chiuso, ~3 min)
#   scripts/viewer.sh run     apre l'app in finestra 1280x720 (avvia prima endpoint e sim)
# Le modifiche alla scena si fanno nell'editor, poi si rifà la build.
#
# Unity: la versione scritta in FSAE_Visualizer/ProjectSettings/ProjectVersion.txt,
# installata con Unity Hub nel percorso standard; altrimenti UNITY=/percorso/Unity.
# Build Linux: serve il modulo "Linux Build Support" in Unity Hub (non provata).
set -e
WS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROJECT="$WS_ROOT/Simulation/FSAE_Visualizer"
OUT="$WS_ROOT/builds"
VERSION=$(sed -n 's/^m_EditorVersion: //p' "$PROJECT/ProjectSettings/ProjectVersion.txt")

case "$(uname)" in
    Darwin)
        UNITY=${UNITY:-/Applications/Unity/Hub/Editor/$VERSION/Unity.app/Contents/MacOS/Unity}
        TARGET=-buildOSXUniversalPlayer
        APP="$OUT/FSAE_Visualizer.app"
        BIN="$APP/Contents/MacOS/FSAE_Visualizer"
        ;;
    Linux)
        UNITY=${UNITY:-$HOME/Unity/Hub/Editor/$VERSION/Editor/Unity}
        TARGET=-buildLinux64Player
        APP="$OUT/FSAE_Visualizer.x86_64"
        BIN="$APP"
        ;;
    *)
        echo "[!] Sistema non supportato: $(uname)"; exit 1 ;;
esac

case "$1" in
    build)
        # -i: Unity Hub passes -projectpath in lowercase.
        if pgrep -if "Unity.*-projectpath.*FSAE_Visualizer" >/dev/null; then
            echo "[!] Chiudi l'editor Unity prima della build."; exit 1
        fi
        [ -x "$UNITY" ] || { echo "[!] Unity $VERSION non trovato in $UNITY (installalo da Unity Hub o usa UNITY=...)"; exit 1; }
        mkdir -p "$OUT"
        "$UNITY" -batchmode -quit -projectPath "$PROJECT" $TARGET "$APP" -logFile "$OUT/build.log" \
            && grep -E "Build Finished" "$OUT/build.log"
        ;;
    run)
        [ -e "$BIN" ] || { echo "[!] Manca $APP: lancia prima '$0 build'."; exit 1; }
        "$BIN" -screen-fullscreen 0 -screen-width 1280 -screen-height 720 -logFile "$OUT/player.log"
        ;;
    *)
        echo "Uso: $0 build|run"; exit 1
        ;;
esac
