#!/bin/bash

# Liste der Scripte, die ausgeführt werden sollen
SCRIPTS=("./complete_setup.sh" "./setup_nvim.sh")

echo "--- Starte Installations-Prozess ---"

for script in "${SCRIPTS[@]}"; do
    # 1. Prüfen, ob die Datei überhaupt existiert
    if [ ! -f "$script" ]; then
        echo "❌ Fehler: $script wurde nicht gefunden!"
        exit 1
    fi

    # 2. Prüfen, ob die Datei ausführbar ist, wenn nicht -> chmod
    if [ ! -x "$script" ]; then
        echo "⚠️  $script war nicht ausführbar. Korrigiere Berechtigungen..."
        chmod +x "$script"
    fi

    # 3. Script ausführen
    echo "🚀 Führe $script aus..."
    if $script; then
        echo "✅ $script erfolgreich abgeschlossen."
    else
        echo "❌ Fehler in $script. Abbruch."
        exit 1
    fi

    echo "------------------------------------"
done

echo "🎉 Alle Setups wurden erfolgreich ausgeführt!"
