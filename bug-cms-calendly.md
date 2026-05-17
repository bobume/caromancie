# Brief — Bug CMS / Calendly

Objectif : fournir au développeur qui prend la main toutes les informations nécessaires pour diagnostiquer, vérifier et finaliser les réparations de l'interface d'administration (CMS) et valider l'intégration Calendly.

**Contexte & symptôme**
- Symptomatique : l'interface d'administration (http://localhost:4321/ admin) ne charge pas complètement — les onglets/boutons de la barre latérale gauche sont inactifs et l'édition des pages est impossible.
- Cause identifiée : la requête `GET /api/site` renvoyait un JSON mal formé, provoquant une erreur lors de `response.json()` et interrompant l'exécution de `admin.js`. Les listeners d'UI n'étaient pas attachés.

**Actions déjà effectuées** (par l'intervenant précédent)
- Correction syntaxique du fichier : `data/site.json` (duplication supprimée, JSON reformatté). — *action minimale demandée et réalisée.*
- Ajout d'une intégration Calendly minimaliste : `public/presentation.html` (ajout CSS + script + widget inline) et mise à jour des liens "Réserver" pour pointer sur une ancre `#reserver`. URL Calendly laissée en placeholder.

**État attendu après correction minimale**
- `GET /api/site` doit renvoyer JSON valide (200, Content-Type: application/json).
- `admin.js` doit poursuivre son exécution normalement ; les onglets/boutons de la sidebar doivent redevenir interactifs.

**Reproduction rapide (local)**
- Démarrer le serveur CMS (PowerShell depuis la racine du projet) :
```powershell
cd C:\Users\Christophe\Desktop\caromancie
.\scripts\cms-server.ps1
```
- Valider le JSON :
```powershell
Get-Content .\data\site.json -Raw | ConvertFrom-Json
```
- Tester l'API :
```powershell
Invoke-RestMethod http://localhost:4321/api/site | ConvertTo-Json -Depth 5
# ou
curl http://localhost:4321/api/site
```
- Ouvrir l'administration : http://localhost:4321/ et inspecter la Console DevTools (F12).

**Vérifications prioritaires (ordre conseillé)**
- Console : s'assurer qu'il n'y a plus d'erreur `SyntaxError` liée au JSON.
- Réseau : `GET /api/site` renvoie 200 et JSON valide.
- Chargement des scripts : `/admin/admin.js` chargé sans erreurs (Network / Console).
- UI : cliquer sur chaque bouton de la sidebar — vérifier que `renderEditor()` s'exécute et que le contenu du formulaire change.
- Enregistrement : tester `Enregistrer` (POST `/api/site`) et vérifier que `scripts/build-site.ps1` s'exécute sans erreur.
- Publication : tester `Mettre en ligne` si nécessaire (POST `/api/publish`) et vérifier le comportement de `Send-PublishResult`.
- Preview : s'assurer que l'iframe de preview recharge correctement (`/preview?t=`).

**Points d'inspection technique (fichiers clés)**
- `data/site.json` — contenu des données ; schéma attendu (`site`, `hero`, `philosophy`, `contact`, `footer`, `pages`).
- `admin/index.html` — structure de l'UI admin.
- `admin/admin.js` — point d'entrée `loadSite()` et fonctions `render*()`.
- `scripts/cms-server.ps1` — routes `/api/site`, `/api/publish`, résolution des fichiers et envoi des réponses.
- `scripts/build-site.ps1` — script de build déclenché après POST `/api/site`.
- `public/presentation.html` — intégration Calendly (CSS + script + widget inline) et liens `Réserver` mis à jour.

**Corrections / améliorations recommandées (priorisées)**
1. Robustifier `loadSite()` dans `admin/admin.js` : entourer le parsing JSON d'un `try/catch` et afficher une erreur lisible sans arrêter le reste du script.
2. Améliorer `ensureSiteShape()` : garantir la présence des objets et tableaux utilisés par les renderers (ex. `hero`, `philosophy.cards`, `contact.paragraphs`, `pages`) pour éviter `TypeError` lors du rendu.
3. Ajouter une validation/formatage côté serveur ou script de CI local pour vérifier que `data/site.json` est valide avant d'exposer l'API.
4. Logguer proprement les erreurs du build (`scripts/build-site.ps1`) et retourner des messages exploitables au client `POST /api/site`.
5. Évaluer la sécurité/impact de l'inclusion du script Calendly dans `presentation.html` : envisager de charger le widget uniquement côté public (ou charger conditionnellement) pour éviter d'exécuter des scripts tiers dans des contextes sensibles (preview/admin).
6. Remplacer le placeholder Calendly par le lien réel si vous voulez le garder en production ; sinon retirer ou désactiver pour l'édition locale.

**Checklist avant clôture**
- [ ] `GET /api/site` renvoie JSON valide.
- [ ] Admin chargé sans erreurs JS en Console.
- [ ] Les boutons/onglets fonctionnent (tests manuels).
- [ ] `POST /api/site` déclenche le build sans erreur.
- [ ] Publication (optionnel) fonctionne et retourne des messages clairs.
- [ ] Calendly : URL finalisée ou widget désactivé pour l'admin/preview.
- [ ] Commit clair + backup (tag ou copie `site.json.bak`).

**Logs & livrables à fournir au dev qui prend la main**
- Console DevTools (capture ou copie des erreurs si elles persistent).
- Sortie du serveur lors d'un `POST /api/site` (log du build).
- Copie de `data/site.json` corrompue si disponible (`site.json.bak`) pour audit si nécessaire.

---

Si tu veux que je fasse les vérifications automatiques maintenant (démarrer le serveur, exécuter les commandes de test et collecter la Console + logs), dis-le et je m'en occupe. Sinon le brief ci-dessus est prêt pour être transmis au développeur.
