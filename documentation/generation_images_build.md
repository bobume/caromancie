# Generation d'images pour le bandeau

## Resume

Les images derivees du bandeau peuvent etre generees localement si besoin, mais le projet ne depend plus de Node.js.

Le CMS et le site fonctionnent avec :
- les fichiers HTML/CSS/JavaScript du repo,
- les scripts PowerShell existants,
- le JavaScript execute par le navigateur.

## Methode recommandee

Utiliser les scripts deja presents dans `scripts/` :
- `scripts/resize_hero_images.py` pour generer des variantes JPG/WebP avec Python + Pillow,
- `scripts/make_hero_horizontal.ps1` pour creer rapidement des versions horizontales avec ImageMagick.

## Generation avec Python

Si Python et Pillow sont disponibles :

```powershell
cd 'C:/Users/Christophe/Desktop/caromancie'
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install Pillow
python scripts/resize_hero_images.py
```

Les fichiers generes se trouvent dans `public/images`.

## Generation horizontale avec ImageMagick

Si ImageMagick est installe et que la commande `magick` est disponible :

```powershell
cd 'C:/Users/Christophe/Desktop/caromancie'
.\scripts\make_hero_horizontal.ps1
```

Les fichiers sortants sont notamment :
- `public/images/hero-1600.jpg`,
- `public/images/hero-1200.jpg`.

## Build du site

Pour regenerer les pages publiques :

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build-site.ps1
```

## Configuration Cloudflare Pages

- Publish directory : `public`
- Build command : laisser vide, sauf besoin specifique.

Aucun `npm install`, `npm run build` ou script Node n'est requis.

## Bonnes pratiques

- Garder `public/images/hero_caromancie.png` comme image source.
- Ne pas ajouter Node.js pour un besoin simple.
- Si une image ne s'affiche pas, verifier d'abord le chemin dans `data/site.json` et la presence du fichier dans `public/images`.

## Fichiers utiles

- Script Python : [scripts/resize_hero_images.py](../scripts/resize_hero_images.py#L1)
- Script PowerShell ImageMagick : [scripts/make_hero_horizontal.ps1](../scripts/make_hero_horizontal.ps1#L1)
- Build du site : [scripts/build-site.ps1](../scripts/build-site.ps1#L1)
- Page principale : [public/index.html](../public/index.html#L1)
