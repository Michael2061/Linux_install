#!/bin/bash
set -euo pipefail

# --- KONFIGURATION ---
GITHUB_REPO="https://github.com/Michael2061/nvim.git"
CONFIG_DIR="$HOME/.config/nvim"
LOG_FILE="$HOME/nvim-setup-$(date +%Y%m%d_%H%M%S).log"
START_TIME=$(date +%s)

# --- Colors & Logging ---
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

info()  { echo -e "${CYAN}[INFO]${NC}  $*"; echo "[$(date '+%H:%M:%S')] [INFO] $*" >> "$LOG_FILE"; }
ok()    { echo -e "${GREEN}[OK]${NC}    $*"; echo "[$(date '+%H:%M:%S')] [OK] $*" >> "$LOG_FILE"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; echo "[$(date '+%H:%M:%S')] [WARN] $*" >> "$LOG_FILE"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; echo "[$(date '+%H:%M:%S')] [ERROR] $*" >> "$LOG_FILE"; }

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

# Pacman Lock prüfen
if [ -f /var/lib/pacman/db.lck ]; then
    warn "Pacman ist gesperrt (db.lck). Warte 5 Sekunden..."
    sleep 5
    if [ -f /var/lib/pacman/db.lck ]; then
        error "Pacman-Sperre besteht weiterhin. Manuell prüfen: sudo rm /var/lib/pacman/db.lck"
        exit 1
    fi
fi

# 1. System Update
info "Aktualisiere Paketquellen..."
sudo pacman -Syu --noconfirm

# 2. Installation aller Abhängigkeiten
info "Installiere System-Abhängigkeiten..."
sudo pacman -S --noconfirm --needed \
    base-devel git unzip curl wget \
    neovim fd ripgrep tree-sitter \
    nodejs npm python-pip go ruby \
    inotify-tools shellcheck \
    lua-language-server vscode-css-languageserver \
    ttf-jetbrains-mono-nerd ttf-nerd-fonts-symbols-common
ok "Abhängigkeiten installiert"

# 3. Alte Konfiguration sichern
if [ -d "$CONFIG_DIR" ]; then
    BACKUP_DIR="${CONFIG_DIR}.backup.$(date +%Y%m%d_%H%M%S)"
    info "Backup vorhandener Konfiguration unter ${BACKUP_DIR}"
    cp -r "$CONFIG_DIR" "$BACKUP_DIR"
    rm -rf "$CONFIG_DIR"
fi

# 4. Neovim Config von GitHub klonen
info "Klone Neovim-Konfiguration von GitHub..."
if ! git clone "$GITHUB_REPO" "$CONFIG_DIR"; then
    error "Fehler beim Klonen von $GITHUB_REPO"
    if [ -n "${BACKUP_DIR:-}" ] && [ -d "$BACKUP_DIR" ]; then
        info "Stelle Backup wieder her..."
        mv "$BACKUP_DIR" "$CONFIG_DIR"
    fi
    exit 1
fi
ok "Neovim-Konfiguration geklont"

# 5. Abschluss
DURATION=$(( $(date +%s) - START_TIME ))
echo ""
ok "Setup abgeschlossen in $((DURATION / 60)) Min $((DURATION % 60)) Sek"
info "Log: $LOG_FILE"
echo ""
echo "-------------------------------------------------------"
echo "1. Starte jetzt einfach 'nvim'."
echo "2. Lazy.nvim installiert automatisch alle Plugins."
echo "3. Nutze :checkhealth, um den Status zu prüfen."
echo "-------------------------------------------------------"
