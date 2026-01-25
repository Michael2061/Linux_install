#!/bin/bash

# ==============================================================================
# 🚀 MICHAEL'S ULTIMATE HYPRLAND SETUP (ROSIE EDITION) - UPDATED
# ==============================================================================

# Variablen
DOTFILES_REPO="https://github.com/Michael2061/hyprland.git"
TEMP_DIR="$HOME/temp_dots"

echo "🚀 Starte das finale CachyOS Setup..."

# 1. Hardware-Erkennung
IS_LAPTOP=false
if [ -d /sys/class/power_supply/BAT0 ]; then
    IS_LAPTOP=true
    echo "💻 Laptop erkannt."
fi

# 2. System Update & Pakete
echo "📦 Installiere System-Pakete..."
sudo pacman -Syu --noconfirm

PACKAGES=(
    hyprland hyprpaper hyprlock hypridle waybar kitty rofi-wayland
    sddm qt5-graphicaleffects qt5-quickcontrols2 qt5-svg
    pipewire pipewire-pulse pipewire-alsa wireplumber pavucontrol
    python-pywal wget fastfetch btop playerctl cliphist
    ttf-jetbrains-mono-nerd ttf-font-awesome
    zsh tmux thunar thunar-archive-plugin thunar-volman tumbler
    vlc obs-studio obsidian code foot
    dunst polkit-kde-agent gvfs gvfs-mtp udiskie
    swayosd swww grim slurp wl-clipboard
    imagemagick curl git
)

sudo pacman -S --needed --noconfirm "${PACKAGES[@]}"

# 3. Dotfiles klonen & verteilen
echo "📥 Klone Dotfiles..."
rm -rf "$TEMP_DIR"
git clone "$DOTFILES_REPO" "$TEMP_DIR"

echo "📂 Verreibe Konfigurationen..."
mkdir -p "$HOME/.config"
cp -r "$TEMP_DIR/.config/"* "$HOME/.config/"
cp -r "$TEMP_DIR/Pictures" "$HOME/"
chmod +x "$HOME/.config/scripts/"*

# 4. Wallpaper-Pfad Fix (Erzwinge rosie.png)
sed -i 's/rosie.jpg/rosie.png/g' "$HOME/.config/scripts/wallpaper_engine.sh"

# 5. Waybar Styles fixen (User-Pfad)
WAYBAR_STYLE="$HOME/.config/waybar/style.css"
sed -i "s|__USER__|$USER|g" "$WAYBAR_STYLE"

# 6. Hyprlock Fix (User-Pfad)
sed -i "s|__USER__|$USER|g" "$HOME/.config/hypr/hyprlock.conf"

# 7. Wlogout Stabilitäts-Fix
WLOG_LAYOUT="$HOME/.config/wlogout/layout"
if [ -f "$WLOG_LAYOUT" ]; then
    sed -i 's/hyprctl dispatch exit 0/loginctl terminate-session self/g' "$WLOG_LAYOUT"
    echo "✅ wlogout Befehle auf Stabilität geprüft."
fi

# 8. SDDM Setup (Optimiert für dynamische Rosie-Wallpaper ohne sudo-Zwang in der Engine)
echo "🖥️ Richte SDDM für dynamische Rosie-Wallpaper ein..."
sudo systemctl enable sddm

# Profilbild-Ordner vorbereiten
sudo mkdir -p /usr/share/sddm/faces
# Falls ein Avatar existiert, kopieren (sonst macht das die wallpaper_engine später)
if [ -f "$HOME/.cache/rosie_avatar.png" ]; then
    sudo cp "$HOME/.cache/rosie_avatar.png" "/usr/share/sddm/faces/$USER.face.icon"
fi

# Berechtigungen setzen, damit SDDM auf das Bild im User-Cache zugreifen kann
chmod 755 $HOME
mkdir -p $HOME/.cache
chmod 777 $HOME/.cache 

# SDDM Theme-Konfiguration (sugar-candy) direkt auf den Cache-Pfad umleiten
SDDM_CONF="/usr/share/sddm/themes/sugar-candy/theme.conf.user"
sudo bash -c "cat > $SDDM_CONF" <<EOF
[General]
background=$HOME/.cache/current_wallpaper.png
mainColor=#e91e63
accentColor=#e91e63
fontColor=#ffffff
selectionColor=#e91e63
showRoundUserIcon=true
FacesDir=/usr/share/sddm/faces
EOF

# Avatar-Verzeichnis global für SDDM bekannt machen
sudo mkdir -p /etc/sddm.conf.d
echo -e "[Theme]\nCurrent=sugar-candy\nFacesDir=/usr/share/sddm/faces" | sudo tee /etc/sddm.conf.d/theme.conf

# 9. Shell & Terminal (ZSH)
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# 10. INITIALER WALLPAPER ENGINE RUN
echo "🖼️ Starte Wallpaper Engine für initiale Farben..."
if [ -f "$HOME/.config/scripts/wallpaper_engine.sh" ]; then
    bash "$HOME/.config/scripts/wallpaper_engine.sh"
fi

echo "🎉 Setup abgeschlossen! Bitte starte dein System neu."