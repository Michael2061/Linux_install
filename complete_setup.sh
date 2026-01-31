#!/bin/bash

# ==============================================================================
# 🚀 MICHAEL'S ULTIMATE HYPRLAND SETUP (ROSIE EDITION)
# ==============================================================================

# Variablen
DOTFILES_REPO="https://github.com/Michael2061/hyprland.git"
TEMP_DIR="$HOME/temp_dots"

echo "🚀 Starte das lückenlose CachyOS Setup..."

# 1. Hardware-Erkennung
IS_LAPTOP=false
if [ -d /sys/class/power_supply/BAT0 ]; then
    IS_LAPTOP=true
    echo "💻 Laptop erkannt."
fi

# 2. System Update
echo "📦 Aktualisiere System..."
sudo pacman -Syu --noconfirm

# 3. Paket-Liste (Ohne AUR-Pakete, da pacman diese nicht findet)
PACKAGES=(
    # --- System & DE ---
    hyprland hyprpaper hyprlock hypridle waybar
    sddm qt5-graphicaleffects qt5-quickcontrols2 qt5-svg
    qt5-wayland qt6-wayland dunst polkit-kde-agent
    xdg-desktop-portal-hyprland
    
    # --- Nvidia ---
    nvidia-dkms nvidia-utils egl-wayland lib32-nvidia-utils
    
    # --- Audio & Sound ---
    pipewire pipewire-pulse pipewire-alsa wireplumber pavucontrol
    
    # --- Terminals & Shell ---
    kitty foot alacritty zsh tmux
    
    # --- Apps & Tools ---
    thunar thunar-archive-plugin thunar-volman tumbler
    gvfs gvfs-mtp udiskie vlc obs-studio obsidian code
    libreoffice-still libreoffice-still-de thunderbird
    rofi-wayland python-pywal wget curl git fastfetch btop 
    playerctl cliphist imagemagick wlogout grim slurp wl-clipboard
    nwg-look ttf-jetbrains-mono-nerd ttf-font-awesome
)

# Laptop-spezifische Pakete
[ "$IS_LAPTOP" = true ] && PACKAGES+=(brightnessctl light bluez bluez-utils)

echo "📥 Installiere Hauptpakete..."
sudo pacman -S --needed --noconfirm "${PACKAGES[@]}"

# 4. SDDM THEME AUTOMATIK (Der manuelle Teil ist jetzt hier automatisiert)
echo "🖥️ Installiere SDDM Sugar-Candy Theme automatisch..."
THEME_DIR="/usr/share/sddm/themes/sugar-candy"
if [ ! -d "$THEME_DIR" ]; then
    sudo git clone https://github.com/MarianArlt/sddm-sugar-candy.git "$THEME_DIR"
    echo "✅ Theme erfolgreich nach $THEME_DIR geklont."
fi

# 5. Dotfiles klonen & Configs verteilen
echo "📥 Synchronisiere Dotfiles..."
rm -rf "$TEMP_DIR"
git clone "$DOTFILES_REPO" "$TEMP_DIR"
mkdir -p "$HOME/.config"
mkdir -p "$HOME/Pictures/Wallpapers"
mkdir -p "$HOME/Pictures/Screenshots"
cp -r "$TEMP_DIR/"* "$HOME/.config/"

# 6. SDDM & Rosie-Konfiguration (Vollautomatisch)
echo "🔧 Konfiguriere SDDM-Login..."
sudo mkdir -p /usr/share/sddm/faces

# Deine theme.conf.user aus dem Repo an das Theme übergeben
if [ -f "$TEMP_DIR/sddm/theme.conf.user" ]; then
    sudo cp "$TEMP_DIR/sddm/theme.conf.user" "$THEME_DIR/theme.conf.user"
    echo "✅ theme.conf.user wurde automatisch im System hinterlegt."
fi

# Berechtigungen setzen (Wichtig für das spätere Wallpaper-Skript!)
sudo chown -R $USER:$USER "$THEME_DIR/Backgrounds/"
sudo chown -R $USER:$USER /usr/share/sddm/faces/

# SDDM System-Config erstellen
sudo mkdir -p /etc/sddm.conf.d
echo -e "[Theme]\nCurrent=sugar-candy\nFacesDir=/usr/share/sddm/faces" | sudo tee /etc/sddm.conf.d/theme.conf
sudo systemctl enable sddm

# 7. Nvidia DRM Modesetting (Fix für Boot-Probleme)
if ! grep -q "nvidia-drm.modeset=1" /etc/default/grub; then
    sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="nvidia-drm.modeset=1 /' /etc/default/grub
    sudo grub-mkconfig -o /boot/grub/grub.cfg
fi

# 8. User-Berechtigungen & Pfad-Fixes
chmod +x "$HOME/.config/scripts/"*
chmod 755 $HOME
mkdir -p $HOME/.cache
chmod 777 $HOME/.cache

# Platzhalter in Dateien durch echten Usernamen ersetzen
find "$HOME/.config" -type f -exec sed -i "s|__USER__|$USER|g" {} + 2>/dev/null

# 9. Initialer Run
if [ -f "$HOME/.config/scripts/wallpaper_engine.sh" ]; then
    bash "$HOME/.config/scripts/wallpaper_engine.sh"
fi

echo "🎉 Fertig! Starte das System neu, um dein Rosie-Design zu genießen."