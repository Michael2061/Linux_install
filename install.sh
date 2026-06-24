#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$HOME/hyprland-install-$(date +%Y%m%d_%H%M%S).log"
START_TIME=$(date +%s)

# --- Colors & Logging ---
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

info()  { echo -e "${CYAN}[INFO]${NC}  $*"; echo "[$(date '+%H:%M:%S')] [INFO] $*" >> "$LOG_FILE"; }
ok()    { echo -e "${GREEN}[OK]${NC}    $*"; echo "[$(date '+%H:%M:%S')] [OK] $*" >> "$LOG_FILE"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; echo "[$(date '+%H:%M:%S')] [WARN] $*" >> "$LOG_FILE"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; echo "[$(date '+%H:%M:%S')] [ERROR] $*" >> "$LOG_FILE"; }

# --- Flags ---
SKIP_NVIM=false
ONLY_NVIM=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --skip-nvim) SKIP_NVIM=true ;;
        --only-nvim) ONLY_NVIM=true ;;
        *) error "Unbekanntes Flag: $1"; exit 1 ;;
    esac
    shift
done

if [ "$SKIP_NVIM" = true ] && [ "$ONLY_NVIM" = true ]; then
    error "--skip-nvim und --only-nvim können nicht gleichzeitig verwendet werden."
    exit 1
fi

# --- Checks ---
if [ "$(id -u)" -eq 0 ]; then
    error "Dieses Script sollte nicht als root ausgeführt werden."
    exit 1
fi

if ! sudo -v &>/dev/null; then
    error "Keine sudo-Rechte. Abbruch."
    exit 1
fi

info "Prüfe Internetverbindung..."
if ! ping -c 1 -W 3 github.com &>/dev/null; then
    error "Keine Internetverbindung. Abbruch."
    exit 1
fi
ok "Internetverbindung vorhanden"

# --- Script-Auswahl ---
SCRIPTS=()
if [ "$ONLY_NVIM" = false ]; then
    SCRIPTS+=("$SCRIPT_DIR/complete_setup.sh")
fi
if [ "$SKIP_NVIM" = false ]; then
    SCRIPTS+=("$SCRIPT_DIR/setup_nvim.sh")
fi

if [ ${#SCRIPTS[@]} -eq 0 ]; then
    error "Keine Scripts auszuführen (--skip-nvim + kein --only-nvim?)."
    exit 1
fi

echo ""
info "--- Starte Installations-Prozess ---"
echo ""

for script in "${SCRIPTS[@]}"; do
    if [ ! -f "$script" ]; then
        error "$script wurde nicht gefunden!"
        exit 1
    fi

    if [ ! -x "$script" ]; then
        warn "$script war nicht ausführbar. Korrigiere Berechtigungen..."
        chmod +x "$script"
    fi

    info "Führe $(basename "$script") aus..."
    if "$script"; then
        ok "$(basename "$script") erfolgreich abgeschlossen."
    else
        error "Fehler in $(basename "$script"). Abbruch."
        exit 1
    fi

    echo "------------------------------------"
done

DURATION=$(( $(date +%s) - START_TIME ))
echo ""
ok "Alle Setups wurden erfolgreich ausgeführt!"
info "Dauer: $((DURATION / 60)) Min $((DURATION % 60)) Sek"
info "Log: $LOG_FILE"
