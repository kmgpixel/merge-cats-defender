#!/bin/zsh
# Installe uniquement les modèles d'export Web de Godot 4.7.2.
set -e
VER=4.7.2
DEST="$HOME/Library/Application Support/Godot/export_templates/$VER.stable"
TMP=$(mktemp -d)
echo "Téléchargement des modèles $VER (~1 Go)..."
curl -L --fail -o "$TMP/t.tpz" "https://github.com/godotengine/godot/releases/download/$VER-stable/Godot_v$VER-stable_export_templates.tpz"
mkdir -p "$DEST"
unzip -o -j "$TMP/t.tpz" 'templates/web*' 'templates/version.txt' -d "$DEST"
rm -rf "$TMP"
ls -la "$DEST"
echo "OK modèles Web installés"
