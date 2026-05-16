# Caromancie — génération d'images pour le bandeau

Ce dépôt contient un script pour générer des variantes optimisées (JPG/WebP) de l'image `public/images/hero_caromancie.png` utilisées par le bandeau.

Prérequis
- Node.js (recommandé >= 16)

Installation

```powershell
cd 'C:/Users/Christophe/Desktop/caromancie'
npm install
```

Générer les images

```powershell
npm run images
```

Ce script produit `public/images/hero-480.jpg|webp`, `hero-800.*`, `hero-1200.*`, `hero-1600.*`.

Déploiement Cloudflare Pages

- Poussez le repo sur GitHub.
- Dans Cloudflare Pages: Build command = `npm run build`, Publish directory = `public`.

Notes
- Le fichier source `public/images/hero_caromancie.png` reste commité. Les images générées sont gitignored.
- Si tu préfères Python, le script `scripts/resize_hero_images.py` existe aussi (nécessite Pillow).
