#!/bin/zsh
# Réimporte et exporte la version Web (PWA) dans build/web. À lancer hors sandbox.
set -e
cd "$(dirname "$0")/.."
godot --headless --path . --import > /dev/null 2>&1 || true
rm -rf build/web && mkdir -p build/web
godot --headless --path . --export-release "Web" build/web/index.html 2>&1 | grep -E "ERROR|WARNING" || true
ls -la build/web && du -sh build/web
echo "EXPORT OK"
