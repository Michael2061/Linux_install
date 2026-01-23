#!/bin/bash

# Variablen - BITTE ANPASSEN
DOTFILES_REPO="https://github.com/Michael2061/hyperland.git"
TEMP_DIR="$HOME/temp_dots"

echo "🚀 Starte das optimierte CachyOS Setup (SwayOSD Fix)..."

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
    swayosd # Jetzt offiziell über pacman
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
    # swayosd-git entfernt, da in pacman enthalten
    $AUR_HELPER -S --noconfirm pyprland sddm-sugar-candy-git
fi

# 4. Nutzergruppen & Shell
echo "👤 Konfiguriere Nutzergruppen..."
# Wichtig für SwayOSD Zugriff auf Keyboard/Backlight
sudo usermod -aG input $USER
sudo usermod -aG video $USER

if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)" "" --unattended
fi
sudo chsh -s $(which zsh) $USER

# 5. Dotfiles & Verzeichnisse
echo "📥 Klone Konfigurationsdateien..."
rm -rf $TEMP_DIR
# Tipp: Nutze SSH (git@github.com:...), falls du deinen Key schon hinterlegt hast
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
cp -r $TEMP_DIR/hypr/* ~/.config/hypr/
cp -r $TEMP_DIR/waybar/* ~/.config/waybar/
cp -r $TEMP_DIR/scripts/* ~/scripts/
cp -r $TEMP_DIR/kitty/* ~/.config/kitty/
cp -r $TEMP_DIR/rofi/* ~/.config/rofi/
cp -r $TEMP_DIR/mangohud/* ~/.config/mangohud/

chmod +x ~/scripts/*.sh
rm -rf $TEMP_DIR

# 9. Services aktivieren (Korrektur: sudo systemctl für System-Unit)
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

# 11. Rust Installation
echo "🦀 Installiere Rust..."
if ! command -v rustup &> /dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    export PATH="$HOME/.cargo/bin:$PATH"
fi
$HOME/.cargo/bin/rustup default stable

echo "✨ SETUP ERFOLGREICH! Bitte jetzt 'reboot' ausführen, damit Gruppen-Änderungen greifen."
