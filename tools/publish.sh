#!/bin/zsh
# Crée le dépôt GitHub public, pousse le code et active GitHub Pages sur docs/.
set -e
cd "$(dirname "$0")/.."
REPO=merge-cats-defender
rm -rf .git docs
cp -R build/web docs && touch docs/.nojekyll docs/.gdignore
git init -q -b main
git add -A
git commit -q -m "Merge Cats Defender : jeu Godot 4.7 + export Web PWA

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
gh repo create "$REPO" --public --source . --push --description "Jeu merge tower defense avec des chats (Godot 4.7, PWA)"
OWNER=$(gh api user -q .login)
gh api -X POST "repos/$OWNER/$REPO/pages" -f "source[branch]=main" -f "source[path]=/docs" > /dev/null
gh repo edit "$OWNER/$REPO" --homepage "https://$OWNER.github.io/$REPO/"
echo "PUBLIE : https://$OWNER.github.io/$REPO/"
