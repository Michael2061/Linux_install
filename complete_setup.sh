#!/bin/bash

# ==============================================================================
# 🚀 MICHAEL'S ULTIMATE HYPRLAND SETUP (ROSIE EDITION)
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

# 3. Dotfiles klonen
echo "📥 Klone Dotfiles..."
rm -rf "$TEMP_DIR"
git clone "$DOTFILES_REPO" "$TEMP_DIR"

# 4. Verzeichnisse vorbereiten
echo "📂 Erstelle Verzeichnisstruktur..."
mkdir -p "$HOME/.config"
mkdir -p "$HOME/.cache"
mkdir -p "$HOME/Pictures/Wallpapers"
mkdir -p "$HOME/.local/bin"

# 5. Bilder & Cache
echo "🌹 Bereite Rosie-Avatar und Wallpaper-Cache vor..."
ROSIE_URL="https://preview.redd.it/i-deliver-rosie-art-now-back-to-lurking-v0-uv9qfhfimm7d1.jpeg?width=2500&format=pjpg&auto=webp&s=9dcaa0b42ecc849444ec08fee79ed083a0e9c672"

curl -L "$ROSIE_URL" > ~/rosie_temp.jpg
if [ -f ~/rosie_temp.jpg ]; then
    magick ~/rosie_temp.jpg -gravity Center -crop 1:1 +repage -resize 256x256 -strip -quality 85 "$HOME/.cache/rosie_avatar.png"
    cp "$HOME/.cache/rosie_avatar.png" "$HOME/.face.icon"
    echo "✅ Rosie-Avatar im Cache erstellt."
    rm ~/rosie_temp.jpg
fi

if [ -f "$TEMP_DIR/wallpapers/rosie.jpg" ]; then
    cp "$TEMP_DIR/wallpapers/rosie.jpg" "$HOME/Pictures/Wallpapers/rosie.jpg"
    cp "$TEMP_DIR/wallpapers/rosie.jpg" "$HOME/.cache/current_wallpaper.png"
fi

# 6. Konfigurationen kopieren
echo "💾 Kopiere Konfigurationsdateien..."
cp -r "$TEMP_DIR"/* "$HOME/.config/"
rm -rf "$HOME/.config/.git"

# 7. Dynamische Pfad-Fixes (Hyprlock, Waybar & Rofi)
echo "🔧 Passe Pfade an deinen User ($USER) an..."

# Hyprlock Fix
HYPR_CONF="$HOME/.config/hypr/hyprlock.conf"
if [ -f "$HYPR_CONF" ]; then
    sed -i "s|path = .*rosie_avatar.png|path = /home/$USER/.cache/rosie_avatar.png|g" "$HYPR_CONF"
    sed -i "s|path = .*current_wallpaper.png|path = /home/$USER/.cache/current_wallpaper.png|g" "$HYPR_CONF"
    sed -i "s|__USER__|$USER|g" "$HYPR_CONF"
    echo "✅ Hyprlock-Pfade gesetzt."
fi

# >>> WAYBAR USER-PFAD FIX (HIER EINGEBAUT) <<<
WAYBAR_STYLE="$HOME/.config/waybar/style.css"
if [ -f "$WAYBAR_STYLE" ]; then
    sed -i "s|__USER__|$USER|g" "$WAYBAR_STYLE"
    echo "🎨 Waybar-Farben auf User $USER konfiguriert."
fi

# Rofi Rosie-Avatar Fix
ROFI_THEME="$HOME/.config/rofi/rosie.rasi"
if [ -f "$ROFI_THEME" ]; then
    sed -i "s|__USER__|$USER|g" "$ROFI_THEME"
    # Falls das Bild im Theme direkt verlinkt ist:
    sed -i "s|path:.*|path: \"/home/$USER/.cache/rosie_avatar.png\";|g" "$ROFI_THEME"
    echo "🌹 Rofi Rosie-Theme angepasst."
fi

# --- WLOGOUT FIX ---
WLOGOUT_CONF="$HOME/.config/wlogout/layout"
if [ -f "$WLOGOUT_CONF" ]; then
    # Ersetzt swaylock (falls vorhanden) durch hyprlock
    sed -i 's/swaylock/hyprlock/g' "$WLOGOUT_CONF"
    # Sicherstellen, dass der Logout-Befehl für Hyprland passt
    sed -i 's/loginctl terminate-user $USER/hyprctl dispatch exit 0/g' "$WLOGOUT_CONF"
    echo "🚪 wlogout auf hyprlock und Hyprland-Exit angepasst."
fi

# 8. SDDM Setup
echo "🖥️ Richte SDDM ein..."
sudo systemctl enable sddm
sudo mkdir -p /usr/share/sddm/faces
sudo cp "$HOME/.cache/rosie_avatar.png" "/usr/share/sddm/faces/$USER.face.icon"
sudo mkdir -p /etc/sddm.conf.d
echo -e "[Theme]\nCurrent=sugar-candy\nFacesDir=/usr/share/sddm/faces" | sudo tee /etc/sddm.conf.d/theme.conf
echo -e "[Theme]\nFacesDir=/usr/share/sddm/faces" | sudo tee /etc/sddm.conf.d/avatar.conf

# 9. Shell & Terminal (ZSH)
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# 10. INITIALER WALLPAPER ENGINE RUN
echo "🖼️ Initialisiere Wallpaper und Cache via Engine..."
WP_SCRIPT="$HOME/.config/scripts/wallpaper_engine.sh"

if [ -f "$WP_SCRIPT" ]; then
    chmod +x "$WP_SCRIPT"
    bash "$WP_SCRIPT"
    echo "✅ Wallpaper Engine erfolgreich gestartet."
else
    echo "⚠️ wallpaper_engine.sh nicht gefunden unter $WP_SCRIPT!"
fi

# 11. Aufräumen
echo "🧹 Räume Temp-Dateien auf..."
rm -rf "$TEMP_DIR"

echo "✅ SETUP ABGESCHLOSSEN! Rosie ist bereit."
echo "🔄 Bitte starte dein System neu."
