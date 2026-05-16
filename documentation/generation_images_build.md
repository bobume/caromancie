# Génération d'images pour le bandeau — option B (génération pendant le build)

## Résumé

Option B : les images dérivées du bandeau sont générées automatiquement durant le build (local ou sur Cloudflare Pages). C'est un très bon compromis simplicité/coût pour un site avec peu d'images.

## Pourquoi choisir B

- Simplicité : pas d'infrastructure CI supplémentaire à maintenir.
- Maintenance minimale : les dérivés sont recréés à chaque build depuis la source.
- Idéal si tu as une ou quelques images et que les changements sont rares.

## Prérequis

- Méthode recommandée : Node.js (>=16). Le dépôt contient `scripts/resize-hero.js` utilisant `sharp`.
- Alternative : Python + Pillow (script `scripts/resize_hero_images.py`) si tu préfères Python.

## Génération locale (Node.js — recommandé)

1. Ouvrir PowerShell et se placer dans le repo :

```powershell
cd 'C:/Users/Christophe/Desktop/caromancie'
```

2. Installer les dépendances Node :

```powershell
npm install
```

3. Générer les images :

```powershell
npm run images
```

Les fichiers générés se trouvent dans `public/images` : `hero-480.jpg`, `hero-480.webp`, `hero-800.jpg`, etc.

4. Vérifier la présence des fichiers (exemples PowerShell) :

```powershell
dir public\images\hero-*.jpg
dir public\images\hero-*.webp
```

5. Tester le site localement (option rapide) :

```powershell
python -m http.server 8000
# ouvrir http://localhost:8000/public/ dans le navigateur
```

## Génération locale (Python — alternative)

Si tu préfères Python :

```powershell
cd 'C:/Users/Christophe/Desktop/caromancie'
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install Pillow
python scripts/resize_hero_images.py
```

## Configuration Cloudflare Pages (option B)

- Dans Cloudflare Pages, lie ton repo.
- Build command : `npm run build`  
- Publish directory : `public`

Remarque : le script `build` dans `package.json` lance la génération d'images. Si tu as un autre build step (ex : bundler), insère la génération d'images dans la chaîne de build.

## Bonnes pratiques

- Garde `public/images/hero_caromancie.png` commité — c'est la source. Les images dérivées sont ignorées par `.gitignore`.
- Si tu veux pré-générer et committer les images (pour performance ou audit), on pourra ajouter un workflow CI ultérieurement.

## Dépannage rapide

- `npm install` échoue → vérifie la version de Node (préférer LTS) et consulte les logs d'installation de `sharp`. Sur Windows, il peut être nécessaire d'installer les outils de build si aucun binaire précompilé n'est disponible.
- `npm run images` ne crée rien → vérifie que `public/images/hero_caromancie.png` existe et que le script `scripts/resize-hero.js` est présent.

## Fichiers utiles

- Script Node (recommandé) : [scripts/resize-hero.js](../scripts/resize-hero.js#L1)
- Script Python (option) : [scripts/resize_hero_images.py](../scripts/resize_hero_images.py#L1)
- Page principale modifiée : [public/index.html](../public/index.html#L1)
- `.gitignore` : [/.gitignore](../.gitignore#L1)

## Génération rapide d'une version horizontale (ImageMagick)

Un script PowerShell `scripts/make_hero_horizontal.ps1` a été ajouté pour créer rapidement une version horizontale optimisée (1600×600 et 1200×450). Il nécessite ImageMagick (commande `magick`) disponible dans le PATH.

Exécution (PowerShell) :

```powershell
cd 'C:/Users/Christophe/Desktop/caromancie'
.\scripts\make_hero_horizontal.ps1
```

Les fichiers sortants seront `public/images/hero-1600.jpg` et `public/images/hero-1200.jpg`.

---

Si tu veux, je peux maintenant :

- t'aider à installer Node sur ta machine et lancer `npm install`, ou
- configurer directement Cloudflare Pages pour toi.
