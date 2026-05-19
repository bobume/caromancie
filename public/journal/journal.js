// Premier mois du journal — ne pas changer
var DEBUT = { annee: 2026, mois: 5 };

var NOMS_MOIS = ['', 'Janvier', 'Fevrier', 'Mars', 'Avril', 'Mai', 'Juin',
  'Juillet', 'Aout', 'Septembre', 'Octobre', 'Novembre', 'Decembre'];

function tousLesMoisDepuisDebut() {
  var liste = [];
  var now = new Date();
  var annee = DEBUT.annee;
  var mois = DEBUT.mois;
  while (annee < now.getFullYear() || (annee === now.getFullYear() && mois <= now.getMonth() + 1)) {
    var mm = mois < 10 ? '0' + mois : '' + mois;
    liste.push({ fichier: annee + '-' + mm, label: NOMS_MOIS[mois] + ' ' + annee });
    mois++;
    if (mois > 12) { mois = 1; annee++; }
  }
  return liste.reverse(); // plus recent en premier
}

var MOIS_COURANT = (function() {
  var now = new Date();
  var mm = now.getMonth() + 1;
  return now.getFullYear() + '-' + (mm < 10 ? '0' + mm : mm);
})();

function moisActif() {
  var hash = window.location.hash.replace('#', '');
  if (hash && MOIS_DISPONIBLES.some(function(m) { return m.fichier === hash; })) {
    return hash;
  }
  return MOIS_COURANT;
}

function chargerJournal(mois) {
  var contenu = document.getElementById('journal-contenu');
  contenu.innerHTML = '<p class="chargement">Chargement...</p>';

  fetch('data/' + mois + '.md?v=1')
    .then(function(r) {
      if (!r.ok) throw new Error('introuvable');
      return r.text();
    })
    .then(function(md) {
      contenu.innerHTML = markdownVersHTML(md);
    })
    .catch(function() {
      contenu.innerHTML = '<p class="absent">Ce mois n\'a pas encore de journal. Il sera ajout&eacute; bient&ocirc;t.</p>';
    });
}

function markdownVersHTML(md) {
  var lignes = md.split('\n');
  var html = '';
  var dansListe = false;

  lignes.forEach(function(ligne) {
    if (ligne.startsWith('# ')) {
      if (dansListe) { html += '</ul>'; dansListe = false; }
      html += '<h1>' + echapper(ligne.slice(2)) + '</h1>';
    } else if (ligne.startsWith('## ')) {
      if (dansListe) { html += '</ul>'; dansListe = false; }
      var titre = ligne.slice(3);
      var partieDate = titre.split(' — ')[0].trim();
      var partieAuteur = titre.split(' — ')[1] ? titre.split(' — ')[1].trim() : '';
      html += '<h2><span class="entree-date">' + echapper(partieDate) + '</span>';
      if (partieAuteur) html += ' <span class="entree-auteur">' + echapper(partieAuteur) + '</span>';
      html += '</h2>';
    } else if (ligne.startsWith('- ')) {
      if (!dansListe) { html += '<ul>'; dansListe = true; }
      html += '<li>' + inlinesMD(ligne.slice(2)) + '</li>';
    } else if (ligne.trim() === '' || ligne.startsWith('---')) {
      if (dansListe) { html += '</ul>'; dansListe = false; }
      if (ligne.startsWith('---')) html += '<hr>';
    } else if (ligne.trim() !== '') {
      if (dansListe) { html += '</ul>'; dansListe = false; }
      html += '<p>' + inlinesMD(ligne) + '</p>';
    }
  });

  if (dansListe) html += '</ul>';
  return html;
}

function inlinesMD(texte) {
  return echapper(texte)
    .replace(/`([^`]+)`/g, '<code>$1</code>')
    .replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>')
    .replace(/\*([^*]+)\*/g, '<em>$1</em>');
}

function echapper(texte) {
  return texte
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;');
}

function ajouterBouton(menu, m, actif) {
  var btn = document.createElement('button');
  btn.textContent = m.label;
  btn.className = 'btn-mois' + (m.fichier === actif ? ' actif' : '');
  btn.addEventListener('click', function() {
    document.querySelectorAll('.btn-mois').forEach(function(b) { b.classList.remove('actif'); });
    btn.classList.add('actif');
    window.location.hash = m.fichier;
    chargerJournal(m.fichier);
  });
  menu.appendChild(btn);
}

function construireMenu(actif) {
  var menu = document.getElementById('menu-mois');
  var candidats = tousLesMoisDepuisDebut();
  var verifications = candidats.map(function(m) {
    return fetch('data/' + m.fichier + '.md', { method: 'HEAD' })
      .then(function(r) { return r.ok ? m : null; })
      .catch(function() { return null; });
  });

  Promise.all(verifications).then(function(resultats) {
    var disponibles = resultats.filter(Boolean);
    if (disponibles.length === 0) {
      menu.innerHTML = '<p style="color:#756a7c;font-size:0.9rem">Aucun journal disponible.</p>';
      return;
    }
    disponibles.forEach(function(m) { ajouterBouton(menu, m, actif); });

    // Si le mois actif n'existe pas, charger le plus recent disponible
    var existe = disponibles.some(function(m) { return m.fichier === actif; });
    chargerJournal(existe ? actif : disponibles[0].fichier);
  });
}

document.addEventListener('DOMContentLoaded', function() {
  var actif = moisActif();
  construireMenu(actif);
});
