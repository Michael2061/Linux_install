#!/bin/bash

# Variablen - BITTE ANPASSEN
DOTFILES_REPO="https://github.com/Michael2061/hyprland.git"
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
    dunst polkit-kde-agent gvfs gvfs-mtp udiskie
    swayosd swww playerctl wlogout grim slurp wl-clipboard
    imagemagick
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
    $AUR_HELPER -S --noconfirm pyprland sddm-sugar-candy-git grimblast-git
fi

# 4. Nutzergruppen & Shell
echo "👤 Konfiguriere Nutzergruppen und Shell..."
sudo usermod -aG video,audio,input $USER

ZSH_CONF="$HOME/.zshrc"

# Erstelle eine neue .zshrc mit dem Signatur-Finder und Tastatur-Force GANZ OBEN
echo '# --- HYPRLAND FIX START ---
# Fix für die Hyprland-Signatur (Wichtig für hyprctl & Waybar)
export XDG_RUNTIME_DIR="/run/user/$(id -u)"
export HYPRLAND_INSTANCE_SIGNATURE=$(ls -t $XDG_RUNTIME_DIR/hypr 2>/dev/null | head -n 1)

# Erzwinge Deutsch, sobald ein Terminal geöffnet wird
if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
    hyprctl keyword input:kb_layout de > /dev/null 2>&1
fi

export XDG_CURRENT_DESKTOP=Hyprland
export XDG_SESSION_TYPE=wayland
export XDG_SESSION_DESKTOP=Hyprland
# --- HYPRLAND FIX END ---
' > ~/.zshrc.tmp

# Hänge die alte .zshrc an die neue temporäre Datei an (falls sie existiert)
if [ -f "$ZSH_CONF" ]; then
    cat "$ZSH_CONF" >> ~/.zshrc.tmp
fi

# Überschreibe die echte .zshrc mit der korrekten Reihenfolge (Fix oben)
mv ~/.zshrc.tmp "$ZSH_CONF"

# Oh-My-Zsh Installation (nur wenn nicht vorhanden)
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)" "" --unattended
fi
sudo chsh -s $(which zsh) $USER

# Zusätzliche Einträge (wie fastfetch) ans Ende hängen
add_to_zsh() {
    if ! grep -Fxq "$1" "$ZSH_CONF" 2>/dev/null; then
        echo "$1" >> "$ZSH_CONF"
    fi
}

# WICHTIG: > /dev/null 2>&1 unterdrückt das "ok" von hyprctl
add_to_zsh 'export XDG_CURRENT_DESKTOP=Hyprland'
add_to_zsh 'export XDG_SESSION_TYPE=wayland'
add_to_zsh 'export XDG_SESSION_DESKTOP=Hyprland'
add_to_zsh 'fastfetch'

# 5. Dotfiles & Verzeichnisse
echo "📥 Klone Konfigurationsdateien..."
rm -rf $TEMP_DIR
# Falls du deinen SSH Key hinterlegt hast, ändere die URL zu: git@github.com:Michael2061/hyprland.git
git clone $DOTFILES_REPO $TEMP_DIR
mkdir -p ~/.config/{hypr,kitty,mangohud,rofi,waybar} ~/scripts ~/Pictures/Wallpapers

# --- 6. Wallpaper & SDDM Vorbereitung ---
echo "--- 🛠️ Bereite SDDM vor ---"
sudo systemctl enable sddm

# Theme aktivieren
sudo mkdir -p /etc/sddm.conf.d
echo -e "[Theme]\nCurrent=sugar-candy" | sudo tee /etc/sddm.conf.d/theme.conf

# --- NEU: Deine theme.conf.user aus Git kopieren ---
echo "🎨 Konfiguriere SDDM Theme..."
# Sicherstellen, dass der Zielordner existiert
sudo mkdir -p /usr/share/sddm/themes/sugar-candy/Backgrounds

# Kopiere die Datei aus deinem heruntergeladenen Repo
if [ -f "$TEMP_DIR/sddm/theme.conf.user" ]; then
    sudo cp "$TEMP_DIR/sddm/theme.conf.user" /usr/share/sddm/themes/sugar-candy/theme.conf.user
    echo "✅ theme.conf.user wurde installiert."
else
    echo "⚠️ theme.conf.user im Repo nicht gefunden unter $TEMP_DIR/sddm/"
fi


sudo systemctl enable sddm
sudo mkdir -p /etc/sddm.conf.d && echo -e "[Theme]\nCurrent=sugar-candy" | sudo tee /etc/sddm.conf.d/theme.conf
sudo mkdir -p /usr/share/sddm/themes/sugar-candy/Backgrounds


# 7. Produktiv-Tools
echo "🖥️ Optimiere Produktiv-Tools..."
cat <<EOF > ~/.tmux.conf
set -g mouse on
set -g status-style bg=default,fg=green
EOF
echo '--enable-features=UseOzonePlatform
--ozone-platform=wayland' > ~/.config/code-flags.conf

# 8. Dateien kopieren
echo "📂 Kopiere Konfigurationsdateien und Wallpaper..."

# Zielordner erstellen
mkdir -p ~/Pictures/Wallpapers

# Rosie-Wallpaper aus dem geklonten Repo kopieren
# Hinweis: Laut deiner Struktur liegt es in $TEMP_DIR/Wallpaper/rosie.jpg
if [ -f "$TEMP_DIR/Wallpaper/rosie.jpg" ]; then
    cp "$TEMP_DIR/Wallpaper/rosie.jpg" ~/Pictures/Wallpapers/rosie.jpg
    echo "✅ Rosie-Wallpaper wurde aus dem Repo kopiert."
else
    echo "⚠️ rosie.jpg wurde im Pfad $TEMP_DIR/Wallpaper/ nicht gefunden!"
fi

# Hier sind die wichtigen alten Befehle, die bleiben müssen:
cp -r $TEMP_DIR/hypr/* ~/.config/hypr/
cp -r $TEMP_DIR/waybar/* ~/.config/waybar/
cp -r $TEMP_DIR/scripts/* ~/scripts/
cp -r $TEMP_DIR/kitty/* ~/.config/kitty/
cp -r $TEMP_DIR/rofi/* ~/.config/rofi/
cp -r $TEMP_DIR/mangohud/* ~/.config/mangohud/

# --- FIXES FÜR WAYBAR & KITTY (Diese müssen bleiben!) ---
echo "📏 Korrigiere Waybar Höhe und Kitty Config..."

if [ -f "$HOME/.config/waybar/config" ]; then
    # Wir machen die Bar ein Stück höher, damit Icons nicht abgeschnitten werden
    sed -i 's/height": 34/height": 55/g' "$HOME/.config/waybar/config"
    sed -i 's/height: 34/height: 55/g' "$HOME/.config/waybar/config"
fi

if [ -f "$HOME/.config/kitty/kitty.conf" ]; then
    sed -i '/exec_once fastfetch/d' "$HOME/.config/kitty/kitty.conf"
fi

# --- NEU: Fix für Hyprlock Pfade ---
if [ -f "$HOME/.config/hypr/hyprlock.conf" ]; then
    echo "🔒 Optimiere Hyprlock Konfiguration..."
    sed -i "s|__USER__|$USER|g" ~/.config/hypr/hyprlock.conf
    sed -i "s|__HOME__|$HOME|g" ~/.config/hypr/hyprlock.conf
fi

# SDDM Hintergrund setzen (Erst hier, da das Bild nun sicher da ist!)
sudo cp ~/Pictures/Wallpapers/rosie.jpg /usr/share/sddm/themes/sugar-candy/Backgrounds/default_background.jpg

# Skripte ausführbar machen
chmod +x ~/scripts/*.sh

echo "⚙️ Initialisiere Design..."
cd $HOME
bash ~/scripts/wallpaper_engine.sh

# 9. Services aktivieren
echo "🔧 Aktiviere Services..."
sudo systemctl daemon-reload
sudo systemctl enable --now swayosd-libinput-backend.service

# --- JETZT ERST AUFRÄUMEN ---
echo "🧹 Aufräumen..."
rm -rf "$TEMP_DIR"

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

# 12. Finaler System-Tastatur-Fix (Hardware & System)
echo "⌨️ Setze System-Tastatur auf Deutsch..."

# 1. Setzt das Layout für die grafische Oberfläche (Hyprland/Rofi)
sudo localectl set-x11-keymap de

# 2. Setzt das Layout für die Hardware-Konsole (TTY)
sudo localectl set-keymap de-latin1

# 3. Schreibt die Einstellung direkt in die Hardware-Konfig von Arch/CachyOS
# Falls die Datei existiert, wird KEYMAP=us durch de-latin1 ersetzt
sudo sed -i 's/KEYMAP=us/KEYMAP=de-latin1/g' /etc/vconsole.conf 2>/dev/null

# 4. Erstellt die X11 Konfigurationsdatei als Rückfallebene
sudo mkdir -p /etc/X11/xorg.conf.d/
cat <<EOF | sudo tee /etc/X11/xorg.conf.d/00-keyboard.conf
Section "InputClass"
        Identifier "system-keyboard"
        MatchIsKeyboard "on"
        Option "XkbLayout" "de"
        Option "XkbVariant" "nodeadkeys"
EndSection
EOF

# 13. Autostart in Hyprland eintragen (statt Systemd-Service)
echo "--- 🛠️ Konfiguriere Autostart in Hyprland ---"

# Deaktiviere den alten Service, falls er noch aktiv ist
systemctl --user disable wallpaper-engine.service 2>/dev/null
rm -f "$HOME/.config/systemd/user/wallpaper-engine.service"

# Stelle sicher, dass das Skript in der hyprland.conf eingetragen ist
HYPR_CONF="$HOME/.config/hypr/hyprland.conf"
if [ -f "$HYPR_CONF" ]; then
    # Entferne alte Einträge, falls vorhanden, um Dopplungen zu vermeiden
    sed -i '/wallpaper_engine.sh/d' "$HYPR_CONF"
    # Füge den neuen, korrekten Pfad am Ende der Autostart-Sektion ein
    echo "exec-once = ~/scripts/wallpaper_engine.sh &" >> "$HYPR_CONF"
    echo "✅ Autostart in hyprland.conf eingetragen."
else
    echo "⚠️ hyprland.conf nicht gefunden. Bitte manuell prüfen!"
fi

# 14. Profilbild-Vorbereitung (Rosie Edition)
echo "👤 Lade Rosie Profilbild herunter und bereite es vor..."

# Sicherstellen, dass imagemagick installiert ist für den Zuschnitt
if ! command -v magick &> /dev/null; then
    sudo pacman -S imagemagick --noconfirm
fi

# Der Rosie-Download & Zuschnitt
ROSIE_URL="https://preview.redd.it/i-deliver-rosie-art-now-back-to-lurking-v0-uv9qfhfimm7d1.jpeg?width=2500&format=pjpg&auto=webp&s=9dcaa0b42ecc849444ec08fee79ed083a0e9c672"

wget -O ~/rosie_large.jpg "$ROSIE_URL" && \
magick convert ~/rosie_large.jpg -gravity Center -crop 1:1 +repage -resize 512x512 "$HOME/.face.icon" && \
rm ~/rosie_large.jpg

if [ -f "$HOME/.face.icon" ]; then
    # Erstellt das Verzeichnis für SDDM Faces, falls es fehlt
    sudo mkdir -p /usr/share/sddm/faces
    # Kopiert das Bild als systemweiten Avatar für deinen User
    sudo cp "$HOME/.face.icon" "/usr/share/sddm/faces/$USER.face.icon"

    # SDDM mitteilen, wo die Avatare liegen
    sudo mkdir -p /etc/sddm.conf.d
    echo -e "[Theme]\nFacesDir=/usr/share/sddm/faces" | sudo tee /etc/sddm.conf.d/avatar.conf
    echo "✅ Rosie wurde erfolgreich als Profilbild eingerichtet!"
else
    echo "⚠️ Fehler beim Erstellen des Profilbildes."
fi

# --- 15. AUTOMATISCHE SUDO-RECHTE FÜR SDDM-SYNC ---
echo "🔓 Konfiguriere Sudo-Rechte für Wallpaper-Sync..."
SUDOERS_FILE="/etc/sudoers.d/sddm-sync"
# Diese Regel erlaubt das Kopieren des Bildes und das Schreiben der Farben ohne Passwort
SUDOERS_RULE="$USER ALL=(ALL) NOPASSWD: /usr/bin/cp * /usr/share/sddm/themes/sugar-candy/Backgrounds/current_bg.jpg, /usr/bin/tee /usr/share/sddm/themes/sugar-candy/theme.conf.user"

echo "$SUDOERS_RULE" | sudo tee "$SUDOERS_FILE" > /dev/null
sudo chmod 440 "$SUDOERS_FILE"
echo "✅ Sudo-Rechte erfolgreich konfiguriert."

echo "✨ SETUP ERFOLGREICH! Bitte jetzt 'reboot' ausführen."
