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
      mettreAJourDerniereEntree(md);
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
  afficherRappelSynchro();
  chargerMessages();
  var actif = moisActif();
  construireMenu(actif);
});

function afficherRappelSynchro() {
  if (sessionStorage.getItem('synchro_vu')) return;
  var estWindows = navigator.userAgent.toLowerCase().indexOf('windows') !== -1;
  var commande = estWindows ? 'outils\\windows\\verifier-synchro.bat' : 'bash outils/mac/verifier-synchro.sh';
  var label = estWindows ? 'Windows' : 'Mac';
  var el = document.getElementById('rappel-synchro');
  el.innerHTML =
    '<div class="rappel-inner">' +
    '<span class="rappel-texte">Debut de session (' + label + ') : verifie ta synchro avant de travailler &rarr;</span>' +
    '<code id="cmd-synchro">' + commande + '</code>' +
    '<button class="btn-copier" onclick="copierCommande()">Copier</button>' +
    '<button class="btn-fermer-rappel" onclick="fermerRappel()" title="Fermer">&times;</button>' +
    '</div>';
  el.style.display = 'block';
}

function copierCommande() {
  var cmd = document.getElementById('cmd-synchro').textContent;
  var btn = document.querySelector('.btn-copier');
  if (navigator.clipboard) {
    navigator.clipboard.writeText(cmd).then(function() {
      btn.textContent = 'Copie !';
      setTimeout(function() { btn.textContent = 'Copier'; }, 2000);
    });
  } else {
    var el = document.createElement('textarea');
    el.value = cmd;
    document.body.appendChild(el);
    el.select();
    document.execCommand('copy');
    document.body.removeChild(el);
    btn.textContent = 'Copie !';
    setTimeout(function() { btn.textContent = 'Copier'; }, 2000);
  }
}

function fermerRappel() {
  document.getElementById('rappel-synchro').style.display = 'none';
  sessionStorage.setItem('synchro_vu', '1');
}

function chargerMessages() {
  fetch('data/messages.json?v=1')
    .then(function(r) { return r.ok ? r.json() : []; })
    .then(function(messages) {
      var lus = JSON.parse(localStorage.getItem('journal_messages_lus') || '[]');
      var visibles = messages.filter(function(m) { return lus.indexOf(m.id) === -1; });
      if (visibles.length === 0) return;
      var container = document.getElementById('messages-importants');
      container.innerHTML = visibles.map(function(m) {
        return '<div class="message-card" id="msg-' + m.id + '">' +
          '<span class="message-auteur">' + echapper(m.auteur) + '</span>' +
          '<span class="message-texte">' + echapper(m.texte) + '</span>' +
          '<button class="btn-lire" onclick="marquerLu(\'' + m.id + '\')">Lu &#10003;</button>' +
          '</div>';
      }).join('');
    })
    .catch(function() {});
}

function marquerLu(id) {
  var lus = JSON.parse(localStorage.getItem('journal_messages_lus') || '[]');
  lus.push(id);
  localStorage.setItem('journal_messages_lus', JSON.stringify(lus));
  var el = document.getElementById('msg-' + id);
  if (el) el.remove();
}

function mettreAJourDerniereEntree(md) {
  var lignes = md.split('\n');
  var derniere = null;
  lignes.forEach(function(ligne) {
    if (ligne.startsWith('## ')) {
      var titre = ligne.slice(3);
      var parties = titre.split(' — ');
      if (parties.length >= 2) {
        derniere = { date: parties[0].trim(), auteur: parties[1].trim() };
      }
    }
  });
  if (!derniere) return;
  var el = document.getElementById('derniere-entree');
  if (el) el.textContent = 'Derniere entree : ' + derniere.auteur + ', ' + dateRelative(derniere.date);
}

function dateRelative(dateStr) {
  var moisFR = {
    'janvier':0,'fevrier':1,'mars':2,'avril':3,'mai':4,'juin':5,
    'juillet':6,'aout':7,'septembre':8,'octobre':9,'novembre':10,'decembre':11
  };
  var parts = dateStr.toLowerCase().replace(/\./g, '').split(' ');
  if (parts.length < 3) return dateStr;
  var d = parseInt(parts[0]);
  var m = moisFR[parts[1]];
  var y = parseInt(parts[2]);
  if (isNaN(d) || m === undefined || isNaN(y)) return dateStr;
  var date = new Date(y, m, d);
  var now = new Date();
  var nowDate = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  var diff = Math.round((nowDate - date) / 86400000);
  if (diff === 0) return "aujourd'hui";
  if (diff === 1) return 'hier';
  if (diff < 7) return 'il y a ' + diff + ' jours';
  if (diff < 14) return 'il y a 1 semaine';
  return 'il y a ' + Math.round(diff / 7) + ' semaines';
}
