# Guide CMS — pour Carole

Bonjour Carole — ce petit guide explique comment utiliser l'interface d'administration pour modifier le contenu du site, sans toucher au code.

**Important :** ne modifie pas les fichiers du dossier `admin/` ni le code du CMS — un collaborateur est en train de le modifier.

## 1) Avant de commencer
- Assure‑toi d'avoir les identifiants d'accès au CMS (nom d'utilisateur / mot de passe).
- Si tu n'as pas l'URL d'administration, demande‑la au collaborateur.
- Pour toute modification incertaine : crée un brouillon plutôt que de publier directement.

## 2) Accéder à l'interface d'administration
- Version en ligne (préférée) : ouvre l'URL d'administration fournie (par exemple `https://caromancie.be/admin/`).
- Version locale (uniquement si on t'a donné l'autorisation) : demande avant d'exécuter `lancer-cms.bat` ou `cms-server.ps1`.

## 3) Connexion
- Entre ton identifiant et ton mot de passe sur la page de connexion.
- Si tu n'as pas d'accès ou as oublié ton mot de passe, contacte le collaborateur responsable.

## 4) Créer ou éditer une page / un article
- Clique sur "Nouveau" ou "Ajouter" dans l'interface.
- Remplis les champs principaux :
  - **Titre** : court et explicite.
  - **URL / slug** : sans espaces, en minuscules, avec des traits d'union (ex. `introduction-tarot`).
  - **Extrait / chapeau** : 1–2 phrases.
  - **Contenu** : paragraphes courts, utilisez `H2` pour les sous-titres.
  - **Image principale** : téléverse une image optimisée (voir section Images).
- Enregistre souvent (bouton "Enregistrer" / "Save draft").
- Utilise "Aperçu" pour vérifier la mise en page avant de publier.

## 5) Images — bonnes pratiques
- Nom du fichier : minuscules, pas d'espaces, traits-d'union (ex. `hero-intro.jpg`).
- Texte alternatif (`alt`) : une courte description utile pour les personnes malvoyantes.
- Taille recommandée : image hero ≈ 1600 px de large; vignettes ≈ 800 px ou moins.
- Compresse les images avant téléversement pour garder le site rapide.
- Si tu n'es pas sûre comment compresser/redimensionner, je peux t'aider.

## 6) Sauvegarder, prévisualiser, publier
- **Enregistrer** : crée un brouillon.
- **Aperçu** : permet de voir le rendu sans publier.
- **Publier** : déclenche le déploiement (ex. Cloudflare Pages). Attends quelques minutes, puis vérifie la page publique.
- Si quelque chose ne va pas après publication : arrête, note le problème et préviens le collaborateur.

## 7) Checklist avant publication
- Titre et texte relus (orthographe).
- `alt` renseignés pour toutes les images.
- Liens testés et fonctionnels.
- Paragraphes courts et lisibles.
- Images optimisées.
- Catégories / tags renseignés si applicable.

## 8) Modifier des fichiers dans le dépôt (rare)
- Privilégie toujours le CMS. Si une modification de fichier est nécessaire, suis ce petit workflow Git :

```bash
# créer une branche locale
git checkout -b edit-<objet>
# après modifications dans VS Code
git add .
git commit -m "Petite correction: <description>"
git push -u origin edit-<objet>
```

- Explique brièvement ce que tu as fait dans la description de la Pull Request.

## 9) Si le CMS semble cassé ou si tu rencontres un bug
- Ne tente pas de corriger le code toi‑même.
- Fais une capture d'écran et note les étapes pour reproduire le bug.
- Préviens le collaborateur (joins la capture et la description).

## 10) Besoin d'aide ?
- Je peux : relire ton texte, vérifier l'aperçu, optimiser des images, ou t'accompagner pas à pas.
- Dis‑moi ce que tu veux que je fasse (par ex. "Relis mon article X", "Aide image pour Y").

---

### Rappels rapides
- Ne modifie ni `admin/` ni le code du CMS sans accord.
- Fais des petites modifications, teste, puis publie.
- Si tu n'es pas sûre : crée un brouillon et demande une relecture.

Merci Carole — tu fais de belles choses, vas‑y doucement et n'hésite pas à demander de l'aide !
