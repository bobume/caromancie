# Mini-CMS local Caromancie

Cette interface sert à modifier le contenu du site sans aller directement dans le code HTML.

## Lancer l'atelier - CMS local

1. Double-clique sur `lancer-cms.bat`.
2. Une fenêtre noire s'ouvre. Garde-la ouverte.
3. Va dans ton navigateur à cette adresse :

```text
http://localhost:4321
```

## Modifier le site

- À gauche, choisis une section : Bandeau, Approche, Contact ou Réglages.
- Au centre, modifie les textes.
- À droite, regarde l'aperçu.
- Clique sur `Enregistrer`.
- Clique sur `Mettre en ligne` quand tu veux envoyer les modifications enregistrées vers GitHub.

Quand tu enregistres, deux choses sont mises à jour :

- `data/site.json` : le contenu facile à modifier.
- `public/index.html` : la page publique prête pour Cloudflare Pages.

## Arrêter l'atelier

Retourne dans la fenêtre noire et appuie sur `Ctrl + C`.

## Important

Le mini-CMS est local. Il sert à préparer les fichiers sur ton ordinateur.
Le bouton `Mettre en ligne` lance ensuite le workflow habituel pour toi :

```text
Git commit -> Git push -> GitHub -> Cloudflare Pages
```

Après le clic, Cloudflare Pages peut prendre un petit moment avant d'afficher la nouvelle version du site.
