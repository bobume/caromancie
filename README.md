# Caromancie

Site statique simple pour caromancie.be, avec un petit CMS local.

## Principe

Le projet reste volontairement leger :
- HTML,
- CSS,
- JavaScript execute par le navigateur,
- scripts PowerShell pour le CMS local et le build,
- pas de Node.js requis.

## Lancer le CMS local

Sous Windows, utiliser le raccourci :

```powershell
.\lancer-cms.bat
```

Ou directement :

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\cms-server.ps1
```

Puis ouvrir :

```text
http://localhost:4321/admin/index.html
```

## Generer le site public

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build-site.ps1
```

Le site genere se trouve dans `public/`.

## Images

Le fichier source principal est `public/images/hero_caromancie.png`.

Pour generer des variantes optimisees, utiliser les scripts existants :
- `scripts/resize_hero_images.py` si Python + Pillow est disponible,
- `scripts/make_hero_horizontal.ps1` si ImageMagick est installe.

## Deploiement Cloudflare Pages

- Pousser le repo sur GitHub.
- Dans Cloudflare Pages, utiliser `public` comme dossier de publication.
- Aucun build Node/npm n'est necessaire pour ce projet.
