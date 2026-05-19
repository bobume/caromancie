# Servage automatique des images WebP responsive

## Vue d'ensemble

Ce site sert automatiquement la bonne version WebP optimisée selon :
- **L'appareil** : mobile (≤ 768px) ou desktop (> 768px)
- **L'image** : version compressée et adaptée en taille

**Aucun effort supplémentaire requis.** Il suffit d'écrire les balises `<img>` normalement — un script JavaScript transforme automatiquement tout en `<picture>` WebP responsive.

---

## Comment ça marche

### 1. Le pipeline

```
┌─────────────────────────────────────────────────────────┐
│ 1. Vous déposez une image source dans public/images/   │
│    Ex: hero.jpg, banniere.png, etc.                    │
└────────────────┬────────────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────────────┐
│ 2. GitHub Actions optimise automatiquement              │
│    - Génère: public/images/mobile/hero.webp (480px)    │
│    - Génère: public/images/desktop/hero.webp (1080px)  │
└────────────────┬────────────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────────────┐
│ 3. Vous utilisez l'image dans le HTML (normal)          │
│    <img src="images/hero.jpg" alt="...">               │
└────────────────┬────────────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────────────┐
│ 4. js/images.js transforme automatiquement au chargement│
│    → <picture> avec sources WebP (mobile/desktop)       │
│    → Fallback PNG si WebP non supporté                  │
└─────────────────────────────────────────────────────────┘
```

### 2. La transformation (exemple)

**Vous écrivez :**
```html
<img src="images/photo.png" alt="Ma photo" loading="lazy">
```

**Le navigateur affiche :**

**Mobile (≤ 768px) :**
```html
<picture>
  <source media="(max-width: 768px)" srcset="images/mobile/photo.webp" type="image/webp">
  <source media="(min-width: 769px)" srcset="images/desktop/photo.webp" type="image/webp">
  <img src="images/photo.png" alt="Ma photo" loading="lazy">
</picture>
```

**Résultat :** le navigateur affiche `images/mobile/photo.webp` (~50% plus petit que la source).

**Desktop (> 768px) :**
Le navigateur affiche `images/desktop/photo.webp`.

---

## Guide d'utilisation pour Carole

### Ajouter une image

1. **Sauvegardez votre image source** dans `public/images/`
   - Format accepté : `.jpg`, `.jpeg`, `.png`, `.gif`, `.tif`, `.bmp`
   - Nom : court et clair (ex: `carte-tarot.jpg`)

2. **Attendez quelques secondes** que le workflow GitHub Actions s'exécute
   - ✓ Les versions WebP sont générées dans `public/images/mobile/` et `public/images/desktop/`

3. **Utilisez l'image dans votre HTML** :
   ```html
   <img src="images/carte-tarot.jpg" alt="Carte de tarot" loading="lazy">
   ```

4. **C'est tout.** Le script `js/images.js` fait le reste.

### Convention de noms

Le stem (nom sans extension) de votre image détermine celui du WebP :

| Votre fichier | Mobile WebP généré | Desktop WebP généré |
|---|---|---|
| `images/photo.jpg` | `images/mobile/photo.webp` | `images/desktop/photo.webp` |
| `images/hero-accueil.png` | `images/mobile/hero-accueil.webp` | `images/desktop/hero-accueil.webp` |

**Pas de transformation du nom.** Le script calcule le chemin WebP à partir du stem.

---

## Cas particuliers

### Background images (CSS)

Si vous avez un `<div>` avec un fond image :

```html
<div class="hero-bg" data-src="images/hero.png"></div>
```

Le script détecte l'attribut `data-src` et injecte le bon WebP selon la taille d'écran.

**Important :** ajoutez `data-src="images/..."` et **ne mettez pas** `background-image` dans le CSS — le script le fera.

### Désactiver le servage WebP

Si une image ne doit **pas** être transformée en WebP (cas rare), ajoutez `data-no-webp` :

```html
<img src="images/logo.png" alt="Logo" data-no-webp>
```

Le script l'ignorera et servira l'image source directement.

---

## Fichiers du système

| Fichier | Rôle |
|---|---|
| `public/js/images.js` | Script client qui transforme `<img>` en `<picture>` WebP |
| `.github/workflows/optimiser-images.yml` | Workflow qui génère les WebP (voir `optimisation_auto_des_images.md`) |
| `scripts/optimiser_images.py` | Script Python qui crée les versions mobile/desktop |

---

## Ajouter le script à une nouvelle page

Si vous créez une nouvelle page HTML (ex: `public/nouvelle-page.html`), chargez le script en bas du `<body>` :

```html
  <footer>
    <!-- votre footer -->
  </footer>

  <script src="js/images.js?v=1"></script>
</body>
</html>
```

Remplacez `js/images.js?v=1` par le chemin correct selon le dossier de votre page :
- `public/index.html` → `<script src="js/images.js?v=1"></script>`
- `public/journal/index.html` → `<script src="../js/images.js?v=1"></script>`

Le `?v=1` force le navigateur à recharger le script en cas de mise à jour (cache-busting).

---

## Troubleshooting

### Les images ne s'affichent pas correctement

**Vérifiez :**
1. Que le fichier source existe dans `public/images/`
2. Que le chemin HTML est correct et relatif (ex: `images/mon-image.png`)
3. Dans la console DevTools, regardez si `js/images.js` s'exécute sans erreur

### Les WebP ne sont pas générés

**Vérifiez :**
1. Que le fichier source est bien committé et pushé sur GitHub
2. Que l'extension est supportée (`.jpg`, `.png`, etc., **pas** `.webp`)
3. Dans l'onglet **Actions** de GitHub, vérifiez que le workflow **Optimiser images** a s'est exécuté

**Solution :** relancez le workflow manuellement :
- Onglet **Actions** → **Optimiser images** → **Run workflow** → **Run workflow**

### Les images sont cassées après un redimensionnement

C'est normal — le script recalcule au chaque `resize`. Les sources WebP sont correctes, mais parfois le navigateur met du temps à recharger. Rafraîchissez la page.

### Une image s'affiche mal sur mobile/desktop

Vérifiez les dimensions dans `scripts/optimiser_images.py` :
- Mobile : max 480px
- Desktop : max 1080px

Si votre image source est plus petite, elle ne sera pas redimensionnée (mais compressée en WebP).

---

## Approche sans JS (alternative non utilisée)

**Note :** Ce site utilise une approche JavaScript côté client (plus simple pour un site statique).

Une approche alternative aurait été d'utiliser `<picture>` directement dans le HTML, mais cela aurait demandé :
- Que Carole écrive du `<picture>` manuellement (complexe)
- Ou que le template du CMS génère du `<picture>` (plus complexe à maintenir)

Le script JavaScript évite ce problème : Carole écrit des `<img>` normales et c'est tout.
