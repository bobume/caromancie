# Caromancie.be

Nouveau départ : Astro statique, Tailwind CSS 4, TypeScript, Cloudflare Pages.

## Démarrer (Mac / Windows)

Installer la version Node indiquée dans `.nvmrc`, puis dans le terminal de VS Code :

```sh
npm ci
npm run dev
```

Ouvrir l'adresse affichée par Astro, habituellement http://localhost:4321.

```sh
npm run check
npm run build
npm run preview
```

## Éditer

- Accueil : `src/pages/index.astro`.
- Structure et métadonnées : `src/layouts/Base.astro`.
- Couleurs et styles : `src/styles/global.css`.
- Fichiers publics : `public/` (tout est publié tel quel).
- Architecture, périmètre et déploiement : `documentation/refonte-astro-2026-10-20.md`.

Le PDF de référence n'est pas intégré. Les textes actuels sont une introduction originale ; aucune interprétation n'est attribuée au livre.

## Cloudflare Pages

Le build produit `dist/`. Aucun adaptateur serveur, KV ou appel IA n'est nécessaire à ce socle. Les paramètres de production ne sont pas modifiés par cette branche. Voir le document de refonte pour la bascule.

Sauvegarde de l'ancien projet : branche `backup/avant-refonte-2026-10-20`, commit `5954dd1dc6b401404e4fb3a1e4a30d1b8122e69b`.
