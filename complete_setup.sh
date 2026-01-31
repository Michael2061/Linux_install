#!/bin/bash

# ==============================================================================
# 🚀 MICHAEL'S ULTIMATE HYPRLAND SETUP (ROSIE EDITION) - COMPLETE & FIXED
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

# 2. System Update & Pakete
echo "📦 Installiere System-Pakete..."
sudo pacman -Syu --noconfirm

PACKAGES=(
    # --- System & Desktop Environment ---
    hyprland hyprpaper hyprlock hypridle waybar
    sddm qt5-graphicaleffects qt5-quickcontrols2 qt5-svg
    dunst polkit-kde-agent
    
    # --- Audio & Sound ---
    pipewire pipewire-pulse pipewire-alsa wireplumber pavucontrol
    
    # --- Terminals & Shell ---
    kitty foot alacritty zsh tmux
    
    # --- Datei-Management ---
    thunar thunar-archive-plugin thunar-volman tumbler
    gvfs gvfs-mtp udiskie
    
    # --- Apps & Office ---
    vlc obs-studio obsidian code
    libreoffice-still libreoffice-still-de thunderbird
    
    # --- Gaming ---
    steam lib32-nvidia-utils gamemode mangohud gamescope
    
    # --- Tools & Utilities ---
    rofi-wayland python-pywal wget curl git fastfetch btop 
    playerctl cliphist imagemagick wlogout
    grim slurp wl-clipboard swayosd swww
    
    # --- Fonts ---
    ttf-jetbrains-mono-nerd ttf-font-awesome
)

sudo pacman -S --needed --noconfirm "${PACKAGES[@]}"

# 3. Dotfiles klonen & Wallpaper-Fix
echo "📥 Klone Dotfiles von GitHub..."
rm -rf "$TEMP_DIR"
git clone "$DOTFILES_REPO" "$TEMP_DIR"

echo "📂 Kopiere Konfigurationen..."
mkdir -p "$HOME/.config"
mkdir -p "$HOME/Pictures/Wallpapers"

# Gesamten .config Ordner kopieren
cp -r "$TEMP_DIR/"* "$HOME/.config/"

# FIX: Kopiere rosie.png aus deinem GitHub 'Wallpaper' Ordner
if [ -d "$TEMP_DIR/Wallpaper" ]; then
    cp "$TEMP_DIR/Wallpaper/rosie.png" "$HOME/Pictures/Wallpapers/rosie.png"
    echo "✅ rosie.png nach Pictures/Wallpapers kopiert."
fi

# 4. Skripte ausführbar machen
chmod +x "$HOME/.config/scripts/"*

# 5. Pfad-Anpassungen (User & Dateiendungen)
echo "🔧 Passe Pfade in den Configs an..."
# Ersetze rosie.jpg durch rosie.png in der Wallpaper Engine
sed -i 's/rosie.jpg/rosie.png/g' "$HOME/.config/scripts/wallpaper_engine.sh"

# User-Platzhalter in Waybar & Hyprlock fixen
WAYBAR_STYLE="$HOME/.config/waybar/style.css"
[ -f "$WAYBAR_STYLE" ] && sed -i "s|__USER__|$USER|g" "$WAYBAR_STYLE"
[ -f "$HOME/.config/hypr/hyprlock.conf" ] && sed -i "s|__USER__|$USER|g" "$HOME/.config/hypr/hyprlock.conf"

# 6. wlogout Stabilitäts-Fix
WLOG_LAYOUT="$HOME/.config/wlogout/layout"
if [ -f "$WLOG_LAYOUT" ]; then
    sed -i 's/hyprctl dispatch exit 0/loginctl terminate-session self/g' "$WLOG_LAYOUT"
    echo "✅ wlogout Fix angewendet."
fi

# 7. Cache-Vorbereitung (Wichtig für SDDM & Hyprlock)
echo "📁 Bereite Cache für Rosie-Theme vor..."
chmod 755 $HOME
mkdir -p $HOME/.cache
chmod 777 $HOME/.cache

# 8. SDDM Setup (Optimiert für dynamische Updates)
echo "🖥️ Richte SDDM (Login) ein..."
sudo systemctl enable sddm

# Profilbild-Ordner Systemweit
sudo mkdir -p /usr/share/sddm/faces
if [ -f "$HOME/Pictures/Wallpapers/rosie.png" ]; then
    sudo cp "$HOME/Pictures/Wallpapers/rosie.png" "/usr/share/sddm/faces/$USER.face.icon"
fi

# --- DEIN NEUER BLOCK HIER ---
# Kopiere die theme.conf.user aus dem Repo in das SDDM Verzeichnis
if [ -f "$TEMP_DIR/sddm/theme.conf.user" ]; then
    sudo cp "$TEMP_DIR/sddm/theme.conf.user" "/usr/share/sddm/themes/sugar-candy/theme.conf.user"
    echo "✅ SDDM theme.conf.user aus Repo installiert."
else
    # Fallback: Falls die Datei im Repo fehlt, erstelle eine Standard-Version
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
fi

# Avatar-Verzeichnis für SDDM registrieren
sudo mkdir -p /etc/sddm.conf.d
echo -e "[Theme]\nCurrent=sugar-candy\nFacesDir=/usr/share/sddm/faces" | sudo tee /etc/sddm.conf.d/theme.conf

# 9. Shell & Terminal (Oh-My-Zsh)
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "🐚 Installiere Oh-My-Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# 10. INITIALER RUN
echo "🖼️ Starte Wallpaper Engine für initiale Farben..."
if [ -f "$HOME/.config/scripts/wallpaper_engine.sh" ]; then
    bash "$HOME/.config/scripts/wallpaper_engine.sh"
fi

echo "🎉 Setup abgeschlossen! Bitte starte dein System neu."