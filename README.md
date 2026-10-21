# Merge Cats Defender

Jeu de défense « merge » fait avec **Godot 4.7** : achète des chats, glisse deux chats de même niveau l'un sur l'autre pour les fusionner (jusqu'au niveau 15), et protège le mur contre 10 vagues de zombies. Il y a 15 niveaux sur 5 décors, avec des renforts : pièges, TNT, chat boxeur et chat gardien.

**Jouer :** la version Web (installable en PWA) est dans `docs/` et publiée par GitHub Pages.

## Développement

```bash
# 1. Régénérer les planches de sprites depuis le kit CraftPix (non inclus)
python3 tools/build_assets.py "<kit>/Png"
python3 tools/make_sounds.py
# 2. Exporter la version Web (PWA) dans build/web
zsh tools/export_web.sh
# 3. Tester l'équilibrage avec le bot (headless)
godot --headless --path . --fixed-fps 30 -- --bot=5
```

## Crédits

- Graphismes : [CraftPix.net, Free Cartoon Cat Defense Game Asset Kit](https://craftpix.net/freebies/free-cartoon-cat-defense-game-asset-kit/) ([licence](https://craftpix.net/file-licenses/))
- Police : Passion One (SIL Open Font License, `fonts/OFL.txt`)
- Code et sons : faits pour ce projet
