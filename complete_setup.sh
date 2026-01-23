#!/bin/bash

# Variablen - BITTE ANPASSEN
DOTFILES_REPO="https://github.com/Michael2061/hyperland.git"
TEMP_DIR="$HOME/temp_dots"

echo "🚀 Starte das finale CachyOS Setup..."

# 1. Hardware-Erkennung
IS_LAPTOP=false
if [ -d /sys/class/power_supply/BAT0 ]; then
    IS_LAPTOP=true
    echo "💻 Laptop erkannt. Zusätzliche Treiber werden installiert..."
fi

# 2. System Update & Pakete
echo "📦 Installiere System-Pakete..."
sudo pacman -Syu --noconfirm

PACKAGES=(
    hyprland hyprpaper hyprlock hypridle waybar kitty rofi-wayland
    sddm qt5-graphicaleffects qt5-quickcontrols2 qt5-svg
    pipewire pipewire-pulse pipewire-alsa wireplumber pavucontrol
    python-pywal wget fastfetch btop playerctl cliphist
    steam lib32-nvidia-utils gamemode mangohud gamescope
    ttf-jetbrains-mono-nerd ttf-font-awesome
    zsh tmux thunar thunar-archive-plugin thunar-volman tumbler
    vlc obs-studio obsidian code foot alacritty
    libreoffice-still libreoffice-still-de thunderbird
    dunst polkit-kde-agent
    swayosd swww pywal-16-colors
)

if [ "$IS_LAPTOP" = true ]; then
    PACKAGES+=(xf86-input-libinput brightnessctl bluez bluez-utils)
fi

sudo pacman -S --noconfirm "${PACKAGES[@]}"

# 3. AUR Pakete
echo "🏗️ Installiere AUR Pakete..."
AUR_HELPER=$(command -v paru || command -v yay)
if [ -z "$AUR_HELPER" ]; then
    echo "❌ Kein AUR-Helper gefunden!"
else
    $AUR_HELPER -S --noconfirm pyprland sddm-sugar-candy-git
fi

# 4. Nutzergruppen & Shell
echo "👤 Konfiguriere Nutzergruppen und Shell..."
sudo usermod -aG video,audio,input $USER

if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)" "" --unattended
fi
sudo chsh -s $(which zsh) $USER

# FIX: Umgebungsvariablen NUR hinzufügen, wenn sie noch nicht drin sind
echo "🔍 Prüfe .zshrc Einträge..."
ZSH_CONF="$HOME/.zshrc"

# Funktion zum sauberen Hinzufügen (verhindert Dopplungen)
add_to_zsh() {
    # Wir prüfen, ob der exakte Text bereits in der Datei steht
    if ! grep -Fxq "$1" "$ZSH_CONF" 2>/dev/null; then
        echo "$1" >> "$ZSH_CONF"
    fi
}

# --- NEU: Hyprland Instanz-Fix ---
add_to_zsh 'if [ -z "$XDG_RUNTIME_DIR" ]; then'
add_to_zsh '    export XDG_RUNTIME_DIR=/run/user/$(id -u)'
add_to_zsh 'fi'
add_to_zsh 'export HYPRLAND_INSTANCE_SIGNATURE=$(ls -t $XDG_RUNTIME_DIR/hypr 2>/dev/null | head -n 1)'
# ---------------------------------

# WICHTIG: > /dev/null 2>&1 unterdrückt das "ok" von hyprctl
add_to_zsh 'export XDG_CURRENT_DESKTOP=Hyprland'
add_to_zsh 'export XDG_SESSION_TYPE=wayland'
add_to_zsh 'export XDG_SESSION_DESKTOP=Hyprland'
add_to_zsh 'fastfetch'

# 5. Dotfiles & Verzeichnisse
echo "📥 Klone Konfigurationsdateien..."
rm -rf $TEMP_DIR
# Falls du deinen SSH Key hinterlegt hast, ändere die URL zu: git@github.com:Michael2061/hyperland.git
git clone $DOTFILES_REPO $TEMP_DIR
mkdir -p ~/.config/{hypr,kitty,mangohud,rofi,waybar} ~/scripts ~/Pictures/Wallpapers

# 6. Wallpaper & SDDM
echo "🎨 Konfiguriere Login-Manager & Design..."
W3="neon-city-futuristic-city-cyber-city-cyberpunk-cityscape-5k-3840x2160-8801.jpg"
wget -O ~/Pictures/Wallpapers/$W3 "https://4kwallpapers.com/images/wallpapers/neon-city-futuristic-city-cyber-city-cyberpunk-cityscape-5k-3840x2160-8801.jpg"

sudo systemctl enable sddm
sudo mkdir -p /etc/sddm.conf.d && echo -e "[Theme]\nCurrent=sugar-candy" | sudo tee /etc/sddm.conf.d/theme.conf
sudo mkdir -p /usr/share/sddm/themes/sugar-candy/Backgrounds
sudo cp ~/Pictures/Wallpapers/$W3 /usr/share/sddm/themes/sugar-candy/Backgrounds/default_background.jpg

# 7. Produktiv-Tools
echo "🖥️ Optimiere Produktiv-Tools..."
cat <<EOF > ~/.tmux.conf
set -g mouse on
set -g status-style bg=default,fg=green
EOF
echo '--enable-features=UseOzonePlatform
--ozone-platform=wayland' > ~/.config/code-flags.conf

# 8. Dateien kopieren
echo "📂 Kopiere Konfigurationsdateien..."
cp -r $TEMP_DIR/hypr/* ~/.config/hypr/
cp -r $TEMP_DIR/waybar/* ~/.config/waybar/
cp -r $TEMP_DIR/scripts/* ~/scripts/
cp -r $TEMP_DIR/kitty/* ~/.config/kitty/
cp -r $TEMP_DIR/rofi/* ~/.config/rofi/
cp -r $TEMP_DIR/mangohud/* ~/.config/mangohud/

# --- FIXES FÜR WAYBAR & KITTY ---
echo "📏 Korrigiere Waybar Höhe und Kitty Config..."

# Sucht in der Datei 'config' nach der Höhe 34 und macht 52 daraus
if [ -f "$HOME/.config/waybar/config" ]; then
    # Wir stellen sicher, dass sowohl "height": 34 als auch height: 34 gefunden wird
    sed -i 's/height": 34/height": 52/g' "$HOME/.config/waybar/config"
    sed -i 's/height: 34/height: 52/g' "$HOME/.config/waybar/config"
fi

# Entfernt den fehlerhaften Befehl aus der Kitty Config (exec_once ist kein Kitty-Befehl)
if [ -f "$HOME/.config/kitty/kitty.conf" ]; then
    sed -i '/exec_once fastfetch/d' "$HOME/.config/kitty/kitty.conf"
fi
# ------------------------------

chmod +x ~/scripts/*.sh
rm -rf $TEMP_DIR

echo "⚙️  Initialisiere Design..."
bash ~/scripts/wallpaper_engine.sh

# 9. Services aktivieren
echo "🔧 Aktiviere Services..."
sudo systemctl daemon-reload
sudo systemctl enable --now swayosd-libinput-backend.service

# 10. GTK-Einstellungen
echo "🎨 Setze System-Schrift..."
GTK_CONF="[Settings]
gtk-font-name=JetBrainsMono Nerd Font 11
gtk-theme-name=CachyOS-Dark
gtk-icon-theme-name=Papirus-Dark
gtk-cursor-theme-name=CachyOS-Cursor"

mkdir -p ~/.config/gtk-{3,4}.0
echo -e "$GTK_CONF" > ~/.config/gtk-3.0/settings.ini
echo -e "$GTK_CONF" > ~/.config/gtk-4.0/settings.ini
fc-cache -fv

# 11. Rust Installation (KORRIGIERT)
echo "🦀 Installiere Rust..."
if ! command -v rustup &> /dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi

# Lädt die Umgebungsvariablen für die aktuelle Sitzung
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

# Sicherstellen, dass der absolute Pfad genutzt wird
if [ -f "$HOME/.cargo/bin/rustup" ]; then
    "$HOME/.cargo/bin/rustup" default stable
else
    echo "⚠️ Rust konnte nicht konfiguriert werden - bitte manuell prüfen."
fi

# Pfad-Fix für SwayOSD Style (pywal Integration)
echo "🎨 Passe SwayOSD Pfade an..."
if [ -f ~/.config/swayosd/style.css ]; then
    # Ersetzt den Platzhalter __HOME__ durch den echten Pfad des aktuellen Users
    sed -i "s|__HOME__|$HOME|g" ~/.config/swayosd/style.css
    swayosd-client --reload-style
fi

# 12. Finaler System-Tastatur-Fix
echo "⌨️  Setze System-Layout auf DE..."
sudo localectl set-x11-keymap de
sudo localectl set-keymap de-latin1

sudo mkdir -p /etc/X11/xorg.conf.d/
cat <<EOF | sudo tee /etc/X11/xorg.conf.d/00-keyboard.conf
Section "InputClass"
        Identifier "system-keyboard"
        MatchIsKeyboard "on"
        Option "XkbLayout" "de"
        Option "XkbVariant" "nodeadkeys"
EndSection
EOF

echo "✨ SETUP ERFOLGREICH! Bitte jetzt 'reboot' ausführen."
