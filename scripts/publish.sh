#!/usr/bin/env bash
set -u

cd "$(dirname "$0")/.."

echo "Preparation des fichiers..."
git add -A

if git diff --cached --quiet; then
  echo "Aucun nouveau changement a committer."
else
  message="Mise a jour du site - $(date '+%Y-%m-%d %H:%M')"
  git commit -m "$message"
fi

echo "Envoi vers GitHub..."

if git push; then
  echo "Envoye vers GitHub. Cloudflare Pages doit ensuite publier le site."
  exit 0
fi

branch="$(git rev-parse --abbrev-ref HEAD)"
if git push --set-upstream origin "$branch"; then
  echo "Envoye vers GitHub. Cloudflare Pages doit ensuite publier le site."
  exit 0
fi

echo "Echec de l'envoi vers GitHub."
exit 1
