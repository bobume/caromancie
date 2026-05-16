#!/bin/bash

echo "📦 Statut actuel:"
git status

echo ""
echo "================================"
read -p "Continuer l'envoi ? (y/n) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "❌ Annulé"
  exit 0
fi

read -p "Nom de la mise à jour : " message

if [ -z "$message" ]; then
  message="Mise à jour du site"
fi

echo ""
echo "🚀 Préparation..."
git add -A

if git diff --cached --quiet; then
  echo "ℹ️ Aucun changement à envoyer."
  exit 0
fi

git commit -m "$message"

echo ""
echo "🚀 Envoi vers GitHub..."

if git push; then
  echo "✅ Envoyé ! Le site va se mettre à jour via Cloudflare."
else
  echo "⚠️ Push normal échoué. Tentative avec upstream..."
  BRANCH=$(git rev-parse --abbrev-ref HEAD)

  if git push --set-upstream origin "$BRANCH"; then
    echo "✅ Envoyé avec upstream !"
  else
    echo "❌ Échec de l'envoi. Vérifie l'erreur Git ci-dessus."
    exit 1
  fi
fi