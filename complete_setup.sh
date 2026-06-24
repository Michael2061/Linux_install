#!/bin/bash
set -euo pipefail

# ==============================================================================
# 🚀 MICHAEL'S HYPERLAND DOTS SETUP (ROSIE EDITION)
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$HOME/hyprland-setup-$(date +%Y%m%d_%H%M%S).log"
START_TIME=$(date +%s)

DOTFILES_REPO="https://github.com/Michael2061/Hyperland.git"
TEMP_DIR="$HOME/temp_dots"

# --- Colors & Logging ---
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

info()  { echo -e "${CYAN}[INFO]${NC}  $*"; echo "[$(date '+%H:%M:%S')] [INFO] $*" >> "$LOG_FILE"; }
ok()    { echo -e "${GREEN}[OK]${NC}    $*"; echo "[$(date '+%H:%M:%S')] [OK] $*" >> "$LOG_FILE"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; echo "[$(date '+%H:%M:%S')] [WARN] $*" >> "$LOG_FILE"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; echo "[$(date '+%H:%M:%S')] [ERROR] $*" >> "$LOG_FILE"; }

# --- Cleanup ---
cleanup() { rm -rf "$TEMP_DIR"; }
trap cleanup EXIT

# ==============================================================================
# FUNKTIONEN
# ==============================================================================

check_root() {
    if [ "$(id -u)" -eq 0 ]; then
        error "Dieses Script sollte nicht als root ausgeführt werden."
        exit 1
    fi
    if ! sudo -v &>/dev/null; then
        error "Keine sudo-Rechte. Abbruch."
        exit 1
    fi
    ok "sudo-Rechte vorhanden"
}

check_internet() {
    info "Prüfe Internetverbindung..."
    if ! ping -c 1 -W 3 github.com &>/dev/null; then
        error "Keine Internetverbindung. Abbruch."
        exit 1
    fi
    ok "Internetverbindung vorhanden"
}

check_pacman_lock() {
    if [ -f /var/lib/pacman/db.lck ]; then
        warn "Pacman ist gesperrt (db.lck). Warte 5 Sekunden..."
        sleep 5
        if [ -f /var/lib/pacman/db.lck ]; then
            error "Pacman-Sperre besteht weiterhin. Manuell prüfen: sudo rm /var/lib/pacman/db.lck"
            exit 1
        fi
    fi
}

detect_hardware() {
    info "Erkenne Hardware..."
    IS_LAPTOP=false
    IS_NVIDIA=false

    if [ -d /sys/class/power_supply/BAT0 ]; then
        IS_LAPTOP=true
        ok "Laptop erkannt"
    fi

    if lspci | grep -iI "nvidia" &>/dev/null; then
        IS_NVIDIA=true
        ok "Nvidia Grafikkarte erkannt"
    fi
}

install_system_packages() {
    info "Installiere System-Pakete..."
    check_pacman_lock

    sudo pacman -Syu --noconfirm

    PACKAGES=(
        hyprland hyprpaper hyprlock hypridle waybar kitty rofi-wayland
        sddm qt5-graphicaleffects qt5-quickcontrols2 qt5-svg qt6-wayland qt6ct
        pipewire pipewire-pulse pipewire-alsa wireplumber pavucontrol
        python-pywal wget fastfetch btop playerctl cliphist
        steam gamemode mangohud gamescope
        ttf-jetbrains-mono-nerd ttf-font-awesome
        zsh tmux thunar thunar-archive-plugin thunar-volman tumbler
        vlc mpv obs-studio obsidian code foot alacritty
        kdenlive foliate blanket
        thunderbird
        dunst polkit-kde-agent gvfs gvfs-mtp udiskie
        imagemagick lazygit ffmpeg docker docker-compose
        base-devel git python-pip go nodejs npm
        swayosd swww playerctl wlogout grim slurp wl-clipboard ncspot fzf
        keepassxc ipp-usb cups cups-pdf system-config-printer
    )

    if [ "$IS_NVIDIA" = true ]; then
        PACKAGES+=(nvidia-dkms nvidia-utils egl-wayland lib32-nvidia-utils)
    fi

    if [ "$IS_LAPTOP" = true ]; then
        PACKAGES+=(xf86-input-libinput brightnessctl bluez bluez-utils)
    fi

    sudo pacman -S --needed --noconfirm "${PACKAGES[@]}"
    ok "System-Pakete installiert"
}

install_aur_packages() {
    info "Installiere AUR-Pakete..."

    AUR_HELPER=$(command -v paru || command -v yay) || true

    if [ -z "$AUR_HELPER" ]; then
        warn "Kein AUR-Helper gefunden. Installiere yay..."
        sudo pacman -S --needed --noconfirm base-devel git
        git clone https://aur.archlinux.org/yay.git /tmp/yay
        (cd /tmp/yay && makepkg -si --noconfirm) || { error "Fehler bei yay Installation"; exit 1; }
        AUR_HELPER="yay"
        ok "yay installiert"
    fi

    $AUR_HELPER -S --needed --noconfirm pyprland sddm-sugar-candy-git grimblast-git onlyoffice-bin lazydocker localsend-bin appflowy-bin zen-browser-bin excalidraw-bin brother-udev-rule-type-cups
    ok "AUR-Pakete installiert"
}

deploy_dotfiles() {
    info "Klone Dotfiles von GitHub..."
    rm -rf "$TEMP_DIR"
    git clone "$DOTFILES_REPO" "$TEMP_DIR"

    info "Ersetze Platzhalter (__USER__, __HOME__)..."
    find "$TEMP_DIR" -type f -exec sed -i "s|__USER__|$USER|g" {} + 2>/dev/null
    find "$TEMP_DIR" -type f -exec sed -i "s|__HOME__|$HOME|g" {} + 2>/dev/null

    info "Kopiere Konfigurationen nach ~/.config/..."
    mkdir -p "$HOME/.config"
    shopt -s nullglob
    for item in "$TEMP_DIR"/*/; do
        base=$(basename "$item")
        case "$base" in
            Linux_install|"Linux Install"|__pycache__) ;;
            *) cp -r "$item" "$HOME/.config/" ;;
        esac
    done
    shopt -u nullglob
    rm -f "$HOME/.config/.git" 2>/dev/null

    # Wallpaper nach ~/Pictures/wallpaper/ kopieren
    if [ -f "$TEMP_DIR/wallpaper/rosie.png" ]; then
        mkdir -p "$HOME/Pictures/wallpaper"
        cp "$TEMP_DIR/wallpaper/rosie.png" "$HOME/Pictures/wallpaper/rosie.png"
        ok "Wallpaper nach ~/Pictures/wallpaper/ kopiert"
    fi

    ok "Dotfiles erfolgreich deployed"
}

setup_sddm() {
    info "Richte SDDM und Rosie-Theme ein..."

    THEME_DIR="/usr/share/sddm/themes/sugar-candy"
    sudo mkdir -p /usr/share/sddm/faces

    if [ -f "$TEMP_DIR/sddm/theme.conf.user" ]; then
        sudo cp "$TEMP_DIR/sddm/theme.conf.user" "$THEME_DIR/theme.conf.user"
        ok "SDDM-Theme konfiguriert"
    fi

    sudo mkdir -p "$THEME_DIR/Backgrounds"
    sudo chown -R "$USER:" "$THEME_DIR/Backgrounds/"
    sudo chown -R "$USER:" /usr/share/sddm/faces/
}

setup_nvidia() {
    if [ "$IS_NVIDIA" = false ]; then
        return
    fi

    info "Konfiguriere Nvidia DRM (modeset)..."
    if ! grep -q "nvidia-drm.modeset=1" /etc/default/grub; then
        sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="nvidia-drm.modeset=1 /' /etc/default/grub
        sudo grub-mkconfig -o /boot/grub/grub.cfg
        ok "Nvidia DRM Fix angewendet (Neustart erforderlich)"
    else
        ok "Nvidia DRM ist bereits konfiguriert"
    fi
}

finish_setup() {
    info "Schließe Setup ab..."

    chmod +x "$HOME/.config/hypr/scripts/wallpaper_engine.sh"
    sudo systemctl enable sddm
    ok "SDDM aktiviert"

    if [ -f "$HOME/.config/hypr/scripts/wallpaper_engine.sh" ]; then
        info "Starte Rosie-Wallpaper-Engine..."
        bash "$HOME/.config/hypr/scripts/wallpaper_engine.sh"
        ok "Wallpaper-Engine gestartet"
    fi

    DURATION=$(( $(date +%s) - START_TIME ))
    echo ""
    ok "Setup abgeschlossen!"
    info "Dauer: $((DURATION / 60)) Min $((DURATION % 60)) Sek"
    info "Log: $LOG_FILE"
}

# ==============================================================================
# MAIN
# ==============================================================================

echo ""
info "🚀  Starte Hyperland Komplett-Setup (Rosie Edition)"
echo ""

check_root
check_internet
check_pacman_lock
detect_hardware
install_system_packages
install_aur_packages
deploy_dotfiles
setup_sddm
setup_nvidia
finish_setup
