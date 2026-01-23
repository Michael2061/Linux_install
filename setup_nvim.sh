#!/bin/bash

# --- KONFIGURATION ---
GITHUB_REPO="https://github.com/Michael2061/nvim.git"
CONFIG_DIR="$HOME/.config/nvim"

echo "🚀 Starte Neovim Komplett-Setup auf CachyOS..."

# 1. System Update
echo "🔄 Aktualisiere System-Spiegelserver..."
sudo pacman -Syu --noconfirm

# 2. Installation aller Abhängigkeiten (ohne Duplikate)
echo "📦 Installiere System-Abhängigkeiten..."
# Erklärung der Pakete:
# - base-devel, git, unzip, curl: Basis-Werkzeuge
# - neovim: Der Editor selbst
# - fd, ripgrep: Schnelle Suche (Telescope)
# - tree-sitter: Syntax-Parsing
# - nodejs, npm, python-pip, go, ruby: Laufzeiten für LSPs
# - lua-language-server: Hilfe für nvim-Konfiguration
# - nerd-fonts: Symbole für die UI
sudo pacman -S --noconfirm --needed \
    base-devel \
    git \
    unzip \
    curl \
    wget \
    neovim \
    fd \
    ripgrep \
    tree-sitter \
    nodejs \
    npm \
    python-pip \
    go \
    ruby \
    inotify-tools \
    shellcheck \
    lua-language-server \
    vscode-css-languageserver \
    ttf-jetbrains-mono-nerd \
    ttf-nerd-fonts-symbols-common

# 3. Alte Konfiguration sichern (falls vorhanden)
if [ -d "$CONFIG_DIR" ]; then
    echo "📂 Bestehende Konfiguration gefunden. Erstelle Backup unter ${CONFIG_DIR}.backup"
    rm -rf "${CONFIG_DIR}.backup"
    mv "$CONFIG_DIR" "${CONFIG_DIR}.backup"
fi

# 4. Deine Lua-Konfiguration von GitHub klonen
echo "📥 Klone deine Neovim-Konfiguration von GitHub..."
git clone "$GITHUB_REPO" "$CONFIG_DIR"

# 5. Abschluss
echo ""
echo "✅ Setup abgeschlossen!"
echo "-------------------------------------------------------"
echo "1. Starte jetzt einfach 'nvim'."
echo "2. Lazy.nvim installiert automatisch alle Plugins."
echo "3. Nutze :checkhealth, um den Status zu prüfen."
echo "-------------------------------------------------------"
