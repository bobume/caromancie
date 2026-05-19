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

Avant de modifier: verifier `git status` pour voir les changements locaux.
Faire `git pull` avant une session importante, avant un push, ou si le repo a probablement change ailleurs.
Ne jamais ecraser des changements locaux sans accord explicite.

## Travail a deux
Arnaud travaille sur Mac, Carole travaille sur Windows 10.

Sous Windows, preferer Git Bash. Eviter PowerShell quand ce n'est pas necessaire.

Avant de commencer:
- lancer le script de verification de synchro
- faire `git pull` si le script indique que GitHub contient des changements plus recents

Pendant le travail:
- eviter de modifier les memes fichiers en meme temps
- si la derniere modification GitHub est tres recente, considerer que l'autre personne travaille peut-etre encore

Scripts utiles:
- Mac: `outils/mac/verifier-synchro.sh`
- Windows: `outils/windows/verifier-synchro.bat`

## Règles pratiques
- **Cache navigateur**: quand tu modifies CSS/JS, bump la version dans le HTML (ex: `/admin/admin.js?v=2`)
- **Chemins**: toujours relatifs (pas de `/Users/arnaud/...` ni `C:\Users\...`)
- **Scripts**: Windows → `outils/windows/`, Mac → `outils/mac/`, généraux → `scripts/`
- **Windows / CMS**: ne pas utiliser Node.js pour verifier le CMS sous Windows, sauf demande explicite
- **Sécurité**: pas de suppressions massives, manipulation dangereuse sans avertissement clair

## Images & WebP
Les images sont servies automatiquement en WebP optimisé (mobile et desktop) grâce à un script JavaScript dans `public/js/images.js`.

**Pour ajouter une image :**
1. Dépose ton fichier source dans `public/images/` (`.jpg`, `.png`, `.gif`, etc.)
2. GitHub Actions génère automatiquement les versions WebP (mobile ≤ 480px, desktop ≤ 1080px)
3. Utilise l'image normalement dans le HTML : `<img src="images/ma-photo.jpg" alt="...">`

**Aucune action supplémentaire requise.** Le script détecte automatiquement et sert la bonne version WebP.

Pour les détails : voir `documentation/images_webp_responsive.md`

## Journal projet
Entrées dans `public/journal/data/YYYY-MM.md` (une par mois).
Quand on dit "lis le journal" : lire le fichier du mois courant, résumer en 2-3 phrases ce qui a été fait et ce qui est en attente, signaler les points "À vérifier" sans réponse.

## Principe général
Le meilleur code est souvent le plus simple. Reste humain, créatif, pragmatique.
