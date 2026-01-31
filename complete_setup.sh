#!/bin/bash

# ==============================================================================
# 🚀 MICHAEL'S ULTIMATE HYPRLAND SETUP (ROSIE EDITION)
# ==============================================================================

DOTFILES_REPO="https://github.com/Michael2061/hyprland.git"
TEMP_DIR="$HOME/temp_dots"

echo "🚀 Starte das Setup basierend auf Commit 98a5fda..."

# 1. Hardware-Erkennung (Aus deinem Commit)
IS_LAPTOP=false
if [ -d /sys/class/power_supply/BAT0 ]; then
    IS_LAPTOP=true
    echo "💻 Laptop erkannt."
fi

# NEU: Grafikkarten-Check (Damit Nvidia-Treiber nicht auf AMD-PCs landen)
IS_NVIDIA=false
if lspci | grep -iI "nvidia" > /dev/null; then
    IS_NVIDIA=true
    echo "🎮 Nvidia Grafikkarte erkannt."
fi

# 2. System Update & Pakete (Exakt deine Liste aus dem Commit)
echo "📦 Installiere System-Pakete..."
sudo pacman -Syu --noconfirm

PACKAGES=(
    hyprland hyprpaper hyprlock hypridle waybar kitty rofi-wayland
    sddm qt5-graphicaleffects qt5-quickcontrols2 qt5-svg
    pipewire pipewire-pulse pipewire-alsa wireplumber pavucontrol
    python-pywal wget fastfetch btop playerctl cliphist
    steam gamemode mangohud gamescope
    ttf-jetbrains-mono-nerd ttf-font-awesome
    zsh tmux thunar thunar-archive-plugin thunar-volman tumbler
    vlc obs-studio obsidian code foot alacritty
    libreoffice-still libreoffice-still-de thunderbird
    dunst polkit-kde-agent gvfs gvfs-mtp udiskie
    swayosd swww playerctl wlogout grim slurp wl-clipboard
)

# Nvidia-spezifische Treiber (Nur bei Nvidia-Hardware)
if [ "$IS_NVIDIA" = true ]; then
    PACKAGES+=(nvidia-dkms nvidia-utils egl-wayland lib32-nvidia-utils)
fi

# Laptop-spezifisch (Aus deinem Commit)
if [ "$IS_LAPTOP" = true ]; then
    PACKAGES+=(xf86-input-libinput brightnessctl bluez bluez-utils)
fi

sudo pacman -S --needed --noconfirm "${PACKAGES[@]}"

# 3. AUR Pakete (Deine stabile Logik inkl. pyprland)
echo "🏗️ Installiere AUR Pakete..."
AUR_HELPER=$(command -v paru || command -v yay)
if [ -z "$AUR_HELPER" ]; then
    echo "💡 Kein AUR-Helper gefunden. Installiere yay..."
    sudo pacman -S --needed --noconfirm base-devel git
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay && makepkg -si --noconfirm
    cd -
    AUR_HELPER="yay"
fi

# Hier sind pyprland, sddm-sugar-candy-git und grimblast-git drin
$AUR_HELPER -S --needed --noconfirm pyprland sddm-sugar-candy-git grimblast-git

# 4. Dotfiles & Config (Vollautomatisch)
echo "📥 Klone Dotfiles..."
rm -rf "$TEMP_DIR"
git clone "$DOTFILES_REPO" "$TEMP_DIR"
mkdir -p "$HOME/.config"
cp -r "$TEMP_DIR/"* "$HOME/.config/"

# 5. SDDM & Rosie-Integration (Der Teil für die Grafik-Engine)
THEME_DIR="/usr/share/sddm/themes/sugar-candy"
sudo mkdir -p /usr/share/sddm/faces

# Kopiere theme.conf.user aus dem Repo
if [ -f "$TEMP_DIR/sddm/theme.conf.user" ]; then
    sudo cp "$TEMP_DIR/sddm/theme.conf.user" "$THEME_DIR/theme.conf.user"
fi

# WICHTIG: Rechte für wallpaper_engine.sh (Kein sudo nötig beim Wallpaper-Wechsel)
sudo chown -R $USER:$USER "$THEME_DIR/Backgrounds/"
sudo chown -R $USER:$USER /usr/share/sddm/faces/

# 6. Nvidia DRM Fix (Nur wenn Nvidia aktiv)
if [ "$IS_NVIDIA" = true ]; then
    if ! grep -q "nvidia-drm.modeset=1" /etc/default/grub; then
        sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="nvidia-drm.modeset=1 /' /etc/default/grub
        sudo grub-mkconfig -o /boot/grub/grub.cfg
    fi
fi

# 7. Pfade & Abschluß
find "$HOME/.config" -type f -exec sed -i "s|__USER__|$USER|g" {} + 2>/dev/null
chmod +x "$HOME/.config/scripts/"*
sudo systemctl enable sddm

# Rosie-Engine initial starten
if [ -f "$HOME/.config/scripts/wallpaper_engine.sh" ]; then
    bash "$HOME/.config/scripts/wallpaper_engine.sh"
fi

echo "🎉 Setup abgeschlossen!"