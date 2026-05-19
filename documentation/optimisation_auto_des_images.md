# Optimisation automatique des images

Ce projet utilise un workflow GitHub Actions pour générer automatiquement des versions WebP des images placées dans `public/images/`.

Le workflow concerné est :

- `.github/workflows/optimiser-images.yml`

Le script Python appelé par le workflow est :

- `scripts/optimiser_images.py`

## Fonctionnement

Le workflow se lance dans deux cas :

- automatiquement lors d'un `push` qui touche `public/images/**`, `scripts/optimiser_images.py`, `requirements.txt` ou le workflow lui-même ;
- manuellement depuis GitHub Actions avec le bouton **Run workflow**.

Lors d'un déclenchement manuel, le script parcourt toutes les images sources dans `public/images/`.

Lors d'un `push`, le workflow utilise `dorny/paths-filter` pour ne transmettre au script que les images sources modifiées.

Les dossiers de sortie sont exclus :

- `public/images/mobile/`
- `public/images/desktop/`

Cela évite que les fichiers générés relancent inutilement le workflow.

## Images générées

Pour chaque image source compatible, le script génère deux fichiers WebP :

- une version mobile dans `public/images/mobile/`, largeur maximale `480px` ;
- une version desktop dans `public/images/desktop/`, largeur maximale `1080px`.

Les extensions sources supportées sont :

- `.jpg`
- `.jpeg`
- `.png`
- `.gif`
- `.tif`
- `.tiff`
- `.bmp`

Les fichiers `.webp` déjà présents sont ignorés, ainsi que les fichiers déjà situés dans les dossiers `mobile/` et `desktop/`.

## Commit automatique

Après génération, le workflow ajoute les fichiers de `public/images`, crée un commit si des fichiers ont changé, puis pousse ce commit sur la branche courante.

Le workflow doit donc avoir la permission d'écrire dans le dépôt :

```yaml
permissions:
  contents: write
```

Côté GitHub, le dépôt doit aussi autoriser les workflows à écrire :

`Settings` -> `Actions` -> `General` -> `Workflow permissions` -> **Read and write permissions**.

## Debugging

### Erreur `Process completed with exit code 128`

Le code `128` venait du step Git final, pas du script Python.

Le script `scripts/optimiser_images.py` ne lance aucune commande Git. En revanche, le workflow termine par :

```bash
git commit -m "Auto-optimize images: generate WebP versions" && git push
```

Si `git push` n'a pas le droit d'écrire dans le dépôt, GitHub Actions échoue avec un exit code `128`.

Solutions appliquées :

- ajout de `permissions: contents: write` dans `.github/workflows/optimiser-images.yml` ;
- activation côté GitHub de **Read and write permissions** pour `GITHUB_TOKEN`.

Si cette erreur revient malgré ces réglages, regarder la ligne `fatal:` juste au-dessus de l'erreur dans les logs GitHub Actions. La cause probable sera alors une protection de branche qui empêche `github-actions[bot]` de pousser directement sur `main`.

### Images générées mais workflow relancé en boucle

Les fichiers WebP générés sont écrits dans :

- `public/images/mobile/`
- `public/images/desktop/`

Comme le workflow surveille `public/images/**`, il pouvait se relancer après avoir poussé ses propres fichiers générés.

Solution appliquée : exclusion des dossiers de sortie dans le déclencheur `push` :

```yaml
paths:
  - 'public/images/**'
  - '!public/images/mobile/**'
  - '!public/images/desktop/**'
```

### Plusieurs images modifiées dans un push

`dorny/paths-filter` était configuré avec :

```yaml
list-files: 'csv'
```

Le script Python attendait initialement une liste séparée par des retours ligne. Avec plusieurs fichiers, il pouvait donc recevoir une chaîne CSV comme :

```text
public/images/a.png,public/images/b.jpg
```

et l'interpréter comme un seul chemin invalide.

Solution appliquée : le script accepte maintenant une liste CSV ou une liste séparée par retours ligne.

## Test manuel

Pour tester depuis GitHub :

1. Aller dans l'onglet **Actions**.
2. Sélectionner **Optimiser images**.
3. Cliquer sur **Run workflow**.
4. Vérifier que les fichiers WebP sont générés dans `public/images/mobile/` et `public/images/desktop/`.
5. Vérifier que le commit automatique apparaît dans l'historique Git.

Pour tester localement, installer les dépendances puis lancer :

```bash
python scripts/optimiser_images.py
```

Ou sur une liste ciblée :

```bash
python scripts/optimiser_images.py --files "public/images/exemple.png"
```
