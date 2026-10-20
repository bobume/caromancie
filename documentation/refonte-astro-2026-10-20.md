# Inventaire et plan de refonte — Caromancie.be

Date : 20 octobre 2026. Statut : proposition avant toute suppression ou implémentation.
Demande : refonte complète avec Astro, Tailwind et Cloudflare Pages, budget minimal.

## 1. État de référence et sauvegarde

- Dépôt public : https://github.com/bobume/caromancie
- Branche initiale : main ; commit : 5954dd1dc6b401404e4fb3a1e4a30d1b8122e69b.
- Dernier commit : 6 juin 2026, « Mise à jour build-site.ps1 ».
- 59 fichiers suivis, 58 commits ; une seule branche initiale main et aucune PR ouverte au moment de l'inventaire.
- Branche de sauvegarde créée à ce commit : backup/avant-refonte-2026-10-20.
- Branche de préparation : refonte/astro-tailwind, issue du même commit.
- Miroir Git local contrôlé par git fsck --full, sans erreur.
- Bundle local complet créé et vérifié par git bundle verify.
- SHA-256 du bundle : fb846343f91e47c8f9530e7f1136faff7c98fce5295786db4032b712f6665f5a.
- main n'a pas été modifiée. Aucun fichier existant supprimé ou remplacé.

La branche de sauvegarde préserve les fichiers suivis et leur historique. Elle ne sauvegarde pas les données QUESTIONS_KV, les réglages Cloudflare Access, les secrets GitHub, le DNS, les réglages Pages, ni les fichiers non poussés des ordinateurs de Carole et Arnaud. Ces éléments externes restent à relever/exporter avant bascule. L'accès au tableau de bord Cloudflare n'a pas été vérifié.

## 2. Inventaire

| Ensemble | État constaté | Traitement proposé |
| --- | --- | --- |
| public/index.html | Accueil HTML avec CSS intégré, approche, contact | Remplacer par pages et composants Astro après validation |
| public/presentation.html | Page intitulée Boutique, textes de démonstration | Définir une vraie offre avant publication |
| data/site.json | Source du CMS, navigation, accueil et pages | Extraire et relire les contenus utiles ; migrer vers JSON/Markdown structurés |
| admin/ | Interface locale HTML/CSS/JS | Remplacer le parcours d'édition par un workflow documenté et accessible à Carole |
| scripts/cms-server.ps1 et build-site.ps1 | Serveur et générateur PowerShell | Retirer du parcours actif une fois la nouvelle édition validée |
| public/images/ | 3 images originales, 6 variantes WebP, 2 fichiers .gitkeep | Conserver les originaux ; sélectionner les visuels et optimiser au build |
| public/js/images.js | Remplacement des images par variantes WebP côté navigateur | Remplacer par images responsive générées au build |
| public/journal/ | Journal de travail, Markdown mensuel, messages JSON et interface JS | Conserver les sources ; décider du maintien de l'interface interne |
| functions/api/ | 4 fonctions : questions, réponse par ID, effacements, identité | Préserver avant décision ; vérifier Access et exporter KV si utilisé |
| .github/workflows/deploy-pages.yml | Optimisation Python puis Wrangler pages deploy public sur push main | Adapter au build Astro et à dist après validation |
| .github/workflows/optimiser-images.yml | Optimisation manuelle via workflow_dispatch | Éviter le doublon avec le nouveau pipeline images |
| outils/, installeur/, scripts de publication | Aides Mac/Windows et installation | Archiver/remplacer les instructions obsolètes après validation |
| documentation/, CLAUDE.md, codex.md, README.md | Documentation du fonctionnement actuel | Garder l'historique, réécrire le guide actif pour la nouvelle stack |
| public/index-backup.html et index-problematique.html | Anciennes variantes exposables dans le dossier public | Exclure du futur livrable public après accord |

Aucun package.json, projet Astro, configuration Tailwind, fichier PDF, ni AGENTS.md dans l'arbre suivi examiné.
Le document « Le nombre des anges 101 » n'est donc pas dans ce dépôt ; son contenu n'a pas été examiné.

## 3. Anomalies et dépendances à traiter

1. Le JSON annonce « Ose visualiser !!! » alors que l'accueil affiche « Ose t'écouter !!! ». Le chemin JSON images/hero_caromancie.png n'existe pas dans l'arbre courant ; le HTML utilise hero_caromancie-1.png. La migration doit choisir une source éditoriale unique.
2. Des phrases tronquées et du texte de démonstration sont présents dans l'accueil et la Boutique.
3. La documentation annonce une optimisation automatique des images au push ; le workflow dédié est manuel. Le workflow de déploiement lance cependant aussi l'optimisation.
4. Le workflow de production déploie public sans exécuter le générateur PowerShell : un changement JSON seul n'est pas nécessairement répercuté dans le HTML.
5. Le journal dépend de QUESTIONS_KV. Certaines routes de lecture/écriture ne contrôlent pas l'identité dans leur code ; leur protection dépend donc des règles Cloudflare Access, non vérifiées.
6. Le brief ancien parle de Calendly, mais la page Boutique actuelle examinée ne contient aucun widget. Ne pas considérer la réservation comme opérationnelle.
7. La branche main n'est pas protégée selon les métadonnées de branches consultées. La refonte restera isolée jusqu'à revue.

## 4. Architecture cible proposée

- Astro en génération statique, TypeScript pour la logique métier.
- Tailwind CSS 4 via @tailwindcss/vite.
- Pages et articles préconstruits ; JavaScript uniquement pour les interactions utiles.
- Cloudflare Pages, build npm run build, sortie dist. Aucun adaptateur serveur nécessaire pour cette cible statique.
- Une seule méthode de publication : conserver de préférence GitHub Actions + Wrangler, déjà présent, et l'adapter. Vérifier d'abord si une intégration Git native Pages fonctionne aussi afin d'éviter deux déploiements concurrents.
- Aucun appel IA payant nécessaire au fonctionnement initial.
- Contenus éditoriaux Markdown/JSON avec validation de schéma ; calculs et interprétations séparés.
- Ne pas créer de copie intégrale du livre dans le dépôt public. Une fois le PDF fourni, repérer les thèmes utiles et rédiger les contenus du site avec références de pages internes au travail éditorial.

Structure visée :
- src/pages/ : accueil, numerologie/, nombres-des-anges/, cartomancie/, a-propos/, contact/, pages légales et 404.
- src/layouts/ et src/components/ : structure commune et composants.
- src/content/ : articles et interprétations validées.
- src/lib/ : calculs purs, validation des entrées.
- src/styles/ : Tailwind et variables visuelles.
- src/assets/ : images à transformer ; public/ pour les seuls fichiers copiés tels quels.
- documentation/ : guide de développement, édition Carole et déploiement.

Direction graphique à valider : premium, lisible, chaleureuse, pensée mobile ; palette ivoire, encre et touches dorées discrètes.

## 5. Plan d'exécution et points de contrôle

1. Sauvegarde et audit — réalisés pour Git. Avant toute bascule : vérifier les changements locaux de Carole/Arnaud, exporter KV et relever Pages/Access/DNS.
2. Cadrage — valider ce plan, le sort du journal/CMS, la navigation et l'offre de départ. Distinguer les nombres des anges des calculs classiques de numérologie : le livre ne définit pas nécessairement les deux.
3. Socle isolé — installer les versions stables compatibles Astro/Tailwind, fixer une version Node compatible et le lockfile ; ajouter dev, check et build. Actualiser CLAUDE.md et README. Ne pas modifier la publication de main.
4. Première expérience — accueil premium, recherche d'un nombre avec petit corpus relu, page d'interprétation, approche de Carole et contact effectif. Calcul du chemin de vie seulement après validation de sa règle et de sa place dans l'offre.
5. Contenu et conversion — analyser le PDF lorsqu'il sera disponible, rédiger un premier lot original, définir une prestation ou un produit, son prix et le parcours de commande. Ne pas inventer d'avis ni de moyens de paiement actifs.
6. Migration contrôlée — porter les contenus/visuels retenus ; préserver les URL utiles ou préparer des redirections. Pour le journal, maintenir sa protection et ses fonctions si conservé. Lister les retraits exacts avant toute suppression.
7. Vérification — check et build, tests des vrais cas limites des calculs/recherche, navigation clavier et mobile, liens, images, métadonnées, sitemap et 404. Vérifier que dist ne publie aucun document interne ni ancienne page indésirable.
8. Prévisualisation — déployer la branche sur une prévisualisation distincte et non indexable, sans exposer les données internes ; faire relire le contenu et le parcours.
9. Bascule — après validation de la prévisualisation, fusionner la PR, adapter le déploiement à dist, vérifier le domaine et les parcours. Conserver la branche de sauvegarde.

Retour arrière : créer une branche de restauration depuis le commit sauvegardé et redéployer son dossier public avec la configuration précédente. Restaurer aussi les réglages externes nécessaires depuis leur relevé ; éviter tout reset forcé de main.

## 6. Critères de fin

- Parcours mobile utilisable, contenus relus, recherche fiable et offre compréhensible.
- Build reproductible et publication unique vérifiée.
- Source éditoriale unique et guide simple pour Carole sous Windows.
- Sauvegarde conservée et retour arrière documenté.
- Suppressions explicitement listées et validées avant exécution.

## Références techniques consultées

- https://docs.astro.build/en/guides/styling/
- https://developers.cloudflare.com/pages/framework-guides/deploy-an-astro-site/
- https://developers.cloudflare.com/pages/configuration/build-configuration/

Limite de cet audit : inspection des sources et de Git ; aucun test navigateur, lancement du CMS, accès KV ou vérification du domaine en production. Aucun déploiement effectué.
