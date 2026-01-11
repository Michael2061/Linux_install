bin/bash

# --- KONFIGURATION ---
# Ersetze dies durch dein tatsächliches GitHub-Repo, sobald du es erstellt hast!
GITHUB_REPO="https://github.com/Michael2061/nvim.git"
CONFIG_DIR="$HOME/.config/nvim"

echo "🚀 Starte Neovim Komplett-Setup auf CachyOS..."

# 1. System Update & Basis-Tools
echo "📦 Installiere System-Abhängigkeiten..."
sudo pacman -Syu --noconfirm
sudo pacman -S --noconfirm git base-devel unzip curl wget fd ripgrep nodejs npm python-pip go ruby ttf-jetbrains-mono-nerd neovim inotify-tools

# 2. Deine Lua-Konfiguration von GitHub klonen
echo "📥 Klone deine Neovim-Konfiguration von GitHub..."
git clone "$GITHUB_REPO" "$CONFIG_DIR"

# 3. Abschluss
echo ""
echo "✅ Setup abgeschlossen!"
echo "-------------------------------------------------------"
echo "Starte jetzt einfach 'nvim'."
echo "Lazy.nvim wird automatisch alle Plugins installieren."
echo "Mason wird danach die LSPs und Debugger (Rust, Python etc.) laden."
echo "-------------------------------------------------------"
