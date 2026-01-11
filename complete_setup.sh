#!/bin/bash

# Variablen - BITTE ANPASSEN
DOTFILES_REPO="https://github.com/Michael2061/hyperland.git" # Ersetze dies durch deinen echten Link
TEMP_DIR="$HOME/temp_dots"
rustpath="$HOME/.cargo/env"

echo "🚀 Starte das ULTIMATIVE All-in-One Setup..."

# 1. System Update & Pakete (Hyprland, SDDM, Sound, Apps, OSD)
echo "📦 Installiere System-Pakete..."
sudo pacman -Syu --noconfirm
# Hinweis: swayosd-git ist meist im AUR, falls pacman es nicht findet, wird es ignoriert
sudo pacman -S --noconfirm \
    hyprland hyprpaper hyprlock hypridle waybar kitty rofi-wayland \
    sddm qt5-graphicaleffects qt5-quickcontrols2 qt5-svg \
    pipewire pipewire-pulse pipewire-alsa wireplumber pavucontrol \
    python-pywal wget fastfetch btop playerctl cliphist \
    steam lib32-nvidia-utils gamemode mangohud gamescope \
    ttf-jetbrains-mono-nerd ttf-font-awesome \
    zsh tmux thunar thunar-archive-plugin thunar-volman tumbler \
    vlc obs-studio obsidian code \
    foot alacritty libreoffice-still libreoffice-still-de thunderbird \


# 2. AUR Pakete (Pyprland, SDDM Theme & SwayOSD)
echo "🏗️ Installiere AUR Pakete..."
if command -v paru &> /dev/null; then
    paru -S --noconfirm pyprland sddm-sugar-candy-git swayosd-git
elif command -v yay &> /dev/null; then
    yay -S --noconfirm pyprland sddm-sugar-candy-git swayosd-git
fi

# 3. Shell-Konfiguration (Zsh)
echo "🐚 Konfiguriere Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)" "" --unattended
fi
# Setzt Zsh als Standard-Shell für den aktuellen User
sudo chsh -s $(which zsh) $USER

# 4. Dotfiles & Verzeichnisse vorbereiten
echo "📥 Klone Konfigurationsdateien..."
rm -rf $TEMP_DIR
git clone $DOTFILES_REPO $TEMP_DIR
mkdir -p ~/.config/{hypr,kitty,mangohud,rofi,waybar} ~/scripts ~/Pictures/Wallpapers

# 5. Wallpaper & SDDM (Login Screen)
echo "🎨 Konfiguriere Login-Manager..."
W3="neon-city-futuristic-city-cyber-city-cyberpunk-cityscape-5k-3840x2160-8801.jpg"
wget -O ~/Pictures/Wallpapers/$W3 "https://4kwallpapers.com/images/wallpapers/neon-city-futuristic-city-cyber-city-cyberpunk-cityscape-5k-3840x2160-8801.jpg"

sudo systemctl enable sddm
sudo mkdir -p /etc/sddm.conf.d && echo -e "[Theme]\nCurrent=sugar-candy" | sudo tee /etc/sddm.conf.d/theme.conf
sudo mkdir -p /usr/share/sddm/themes/sugar-candy/Backgrounds
sudo cp ~/Pictures/Wallpapers/$W3 /usr/share/sddm/themes/sugar-candy/Backgrounds/default_background.jpg

# 6. Produktiv-Tools (Tmux & VS Code Fixes)
echo "🖥️ Optimiere Produktiv-Tools..."
cat <<EOF > ~/.tmux.conf
set -g mouse on
set -g status-style bg=default,fg=green
EOF
# VS Code Wayland Flags für flüssige 180Hz
mkdir -p ~/.config
echo '--enable-features=UseOzonePlatform
--ozone-platform=wayland' > ~/.config/code-flags.conf

# 7. Dateien kopieren & Rechte
echo "🚚 Kopiere Dotfiles..."
# Kopiert deine Konfigurationen an die richtigen Orte
cp -r $TEMP_DIR/hypr/* ~/.config/hypr/
cp -r $TEMP_DIR/waybar/* ~/.config/waybar/
cp -r $TEMP_DIR/scripts/* ~/scripts/
cp -r $TEMP_DIR/kitty/* ~/.config/kitty/
cp -r $TEMP_DIR/rofi/* ~/.config/rofi/
cp -r $TEMP_DIR/mangohud/* ~/.config/mangohud/

chmod +x ~/scripts/*.sh
rm -rf $TEMP_DIR

# 8. Services aktivieren
# Wichtig: --user Services werden ohne sudo aktiviert!
systemctl --user enable --now swayosd-libinput-backend.service

# 9. Systemweite GTK-Einstellungen (Schrift & Design)
echo "🎨 Setze JetBrains Mono als System-Schrift..."
mkdir -p ~/.config/gtk-3.0
mkdir -p ~/.config/gtk-4.0

# GTK 3.0 & 4.0 Einstellungen für einheitliche Fonts
GTK_CONF="[Settings]
gtk-font-name=JetBrainsMono Nerd Font 11
gtk-theme-name=CachyOS-Dark
gtk-icon-theme-name=Papirus-Dark
gtk-cursor-theme-name=CachyOS-Cursor"

echo "$GTK_CONF" > ~/.config/gtk-3.0/settings.ini
echo "$GTK_CONF" > ~/.config/gtk-4.0/settings.ini

# Font-Cache aktualisieren
fc-cache -fv

# 10. Rust install
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
rustup default stable


echo "✨ SETUP ERFOLGREICH! Sound, OSD und alle Apps sind bereit."
echo "Bitte führe jetzt einen 'reboot' aus."
