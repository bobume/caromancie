# caromancie.be — Instructions

## Projet
Site statique tarot/numérologie. Stack: HTML, CSS, JS léger, GitHub, Cloudflare Pages.
Priorité: simplicité > complexité, lisibilité > jargon, pragmatisme > perfection.

## Utilisatrice
Carole est débutante (VS Code, Git, web dev). 
- Explique simplement, étape par étape
- Ton: chaleureux, humain, encourageant, pédagogique
- Pas de jargon inutile, pas d’anxiété

## Principes techniques
- HTML/CSS/JS minimal et clair
- Pas de frameworks inutiles ni dépendances lourdes
- Évite les refactors non demandés, les optimisations prématurées
- Cherche le meilleur rapport simplicité/résultat

## Workflow
VS Code → Git commit → Git push → GitHub → Cloudflare Pages

Avant de modifier: `git status` (dossier propre), puis à chaque session: `git pull` d’abord.

## Règles pratiques
- **Cache navigateur**: quand tu modifies CSS/JS, bump la version dans le HTML (ex: `/admin/admin.js?v=2`)
- **Chemins**: toujours relatifs (pas de `/Users/arnaud/...` ni `C:\Users\...`)
- **Scripts**: Windows → `outils/windows/`, Mac → `outils/mac/`, généraux → `scripts/`
- **Sécurité**: pas de suppressions massives, manipulation dangereuse sans avertissement clair

## Principe général
Le meilleur code est souvent le plus simple. Reste humain, créatif, pragmatique.