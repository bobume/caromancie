# Caromancie.be — Nouveau départ
Date : 20 octobre 2026.

## Décision et périmètre
Arnaud a autorisé explicitement de repartir de zéro et de supprimer l'ancien code.
La refonte est préparée sur refonte/astro-tailwind ; main et le domaine de production n'ont pas été modifiés.
L'ancien CMS, les pages, images, scripts PowerShell, fonctions KV et workflows ont été retirés de cette branche.
La sauvegarde conserve ces fichiers et leur historique.

## Sauvegarde vérifiée
- Commit initial : 5954dd1dc6b401404e4fb3a1e4a30d1b8122e69b.
- Branche GitHub : backup/avant-refonte-2026-10-20.
- État initial : 59 fichiers suivis, 58 commits, une branche main, aucune PR ouverte.
- Dernier commit initial : 6 juin 2026, « Mise à jour build-site.ps1 ».
- Copie miroir locale vérifiée avec git fsck --full.
- Bundle local complet vérifié avec git bundle verify.
- SHA-256 du bundle : fb846343f91e47c8f9530e7f1136faff7c98fce5295786db4032b712f6665f5a.

Cette sauvegarde couvre Git. Les réglages Pages, DNS, Access, les secrets et le contenu KV ne sont pas sauvegardés par Git ; aucune de ces ressources externes n'a été modifiée.

## Inventaire historique
| Ensemble ancien | Constat |
| --- | --- |
| public/index.html, presentation.html | Accueil et Boutique HTML/CSS, textes tronqués et démonstration |
| data/site.json | Source CMS divergente du HTML ; ancien chemin hero inexistant |
| admin/, scripts/cms-server.ps1, build-site.ps1 | CMS et générateur locaux PowerShell |
| public/images/, public/js/images.js | 3 originaux, 6 variantes WebP, remplacement responsive par JS |
| public/journal/, functions/api/ | Journal interne, questions, identité et effacements ; dépendance QUESTIONS_KV et Access |
| .github/workflows/ | Déploiement de public par Wrangler au push main ; optimisation dédiée manuelle |
| outils/, installeur/, documentation/ | Guides et outils Mac/Windows du système précédent |

Aucun Astro, Tailwind ou package.json dans l'ancien projet. Aucun PDF dans le dépôt.
Le PDF « Le nombre des anges 101 » n'a pas été examiné.
L'ancien projet reste consultable sur la branche de sauvegarde.

## Socle préparé
- Astro en génération statique et TypeScript strict.
- Tailwind CSS 4 avec @tailwindcss/vite.
- Node fixé dans .nvmrc ; dépendances verrouillées par package-lock.json.
- Accueil original, palette ivoire/vert profond, sections nombres, cartes et approche.
- Mise en page responsive, navigation clavier, lien d'évitement et réduction des animations.
- Mise en page partagée, métadonnées, favicon SVG, 404, sitemap, robots et en-têtes Pages.
- CI GitHub : npm ci, npm run check, npm run build.
- Aucun CMS, stockage serveur, appel IA, paiement ou réservation branché.
- Aucune signification de nombre tirée du livre n'est simulée.

## Plan d'exécution
1. Sauvegarde et inventaire : réalisés.
2. Remise à zéro et socle Astro/Tailwind : préparés sur la branche de refonte.
3. Valider le style et l'offre : expérience gratuite, prestation ou produit payant, tarifs et rôle de Carole.
4. Fournir le PDF ; analyser son contenu, identifier les thèmes et rédiger les premiers contenus originaux en gardant les références de pages dans le travail éditorial privé. Ne pas publier le livre dans le dépôt.
5. Construire la recherche des nombres et leurs pages depuis un corpus relu. Séparer les nombres des anges des calculs classiques ; ajouter ces derniers après choix explicite de la méthode.
6. Ajouter les pages cartomancie, à propos, contact et informations légales avec des données réelles ; intégrer le parcours de conversion retenu.
7. Tester recherche et éventuels calculs, navigation clavier, mobile, liens, images et métadonnées.
8. Déployer une prévisualisation Cloudflare Pages distincte et non indexable ; relire le contenu et le parcours.
9. Après validation, fusionner la PR et basculer la production. Aucun déploiement n'est effectué dans cette préparation.

## Cloudflare Pages
Deux modes possibles ; en choisir un seul :
- Intégration Git native si le projet Pages actuel la permet : npm run build, sortie dist, version Node égale à .nvmrc.
- Sinon conserver le mode Direct Upload de l'ancien workflow : après npm ci et build, exécuter npx wrangler pages deploy dist --project-name=caromancie sur un poste ou une CI authentifiée. Pour une prévisualisation, préciser une branche différente de la branche de production et envoyer X-Robots-Tag: noindex.

Ne pas supposer que le projet existant est relié à Git : l'ancien dépôt déployait par GitHub Actions/Wrangler.
La branche nouvelle contient seulement une CI de vérification, sans déploiement automatique.
Vérifier le type du projet et les paramètres Pages avant la bascule ; adapter la commande à dist au lieu de public.
Astro statique ne nécessite pas d'adaptateur serveur Cloudflare.
Aucune dépendance KV n'est requise pour la nouvelle version.

## Retour arrière
Créer une branche de restauration depuis backup/avant-refonte-2026-10-20 et redéployer son dossier public selon l'ancien workflow.
Ne pas réécrire l'historique de main. Les ressources externes anciennes n'ont pas été supprimées.

## Sources techniques
- Vérification du socle : astro check sans erreur, avertissement ou hint ; build statique réussi.
- Contrôle de sortie : liens internes, ressources et sitemap valides ; anciens fichiers absents ; aucun JavaScript navigateur généré.
- Limite : rendu navigateur et déploiement Cloudflare non vérifiés à cette étape.

## Documentation technique consultée
- https://docs.astro.build/en/guides/styling/
- https://developers.cloudflare.com/pages/framework-guides/deploy-an-astro-site/
- https://developers.cloudflare.com/pages/configuration/build-configuration/

