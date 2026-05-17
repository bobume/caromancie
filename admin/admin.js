const form = document.querySelector("#editorForm");
const editorTitle = document.querySelector("#editorTitle");
const saveButton = document.querySelector("#saveButton");
const publishButton = document.querySelector("#publishButton");
const saveState = document.querySelector("#saveState");
const previewFrame = document.querySelector("#previewFrame");
const refreshPreview = document.querySelector("#refreshPreview");
const tabs = [...document.querySelectorAll(".section-tab")];

let siteData = null;
let currentSection = "hero";
let hasUnsavedChanges = false;

const sectionTitles = {
  hero: "Bandeau",
  philosophy: "Approche",
  contact: "Contact",
  settings: "Réglages"
};

function field(label, path, value, options = {}) {
  const id = path.replaceAll(".", "-");
  const helper = options.helper ? `<p class="helper">${options.helper}</p>` : "";

  if (options.multiline) {
    const rows = options.rows ? ` rows="${options.rows}"` : "";
    return `<div class="field">
      <label for="${id}">${label}</label>
      <textarea id="${id}" data-path="${path}"${rows}>${escapeHtml(value)}</textarea>
      ${helper}
    </div>`;
  }

  const type = options.type || "text";
  return `<div class="field">
    <label for="${id}">${label}</label>
    <input id="${id}" data-path="${path}" type="${type}">
    ${helper}
  </div>`;
}

function escapeHtml(value) {
  return String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
}

function getPath(object, path) {
  return path.split(".").reduce((value, key) => value?.[key], object);
}

function setPath(object, path, value) {
  const keys = path.split(".");
  const last = keys.pop();
  const target = keys.reduce((item, key) => item[key], object);
  target[last] = value;
}

function bindFieldValues() {
  form.querySelectorAll("[data-path]").forEach((input) => {
    const value = getPath(siteData, input.dataset.path) ?? "";
    if (input.tagName === "INPUT") {
      input.value = value;
    }

    input.addEventListener("input", () => {
      setPath(siteData, input.dataset.path, input.value);
      setDirty();
    });
  });
}

function setDirty() {
  hasUnsavedChanges = true;
  saveState.textContent = "Modifications non enregistrées";
  saveState.style.color = "#68408c";
}

function setSaved() {
  hasUnsavedChanges = false;
  saveState.textContent = "Enregistré";
  saveState.style.color = "#587461";
}

function setStatus(message, color = "#756a7c") {
  saveState.textContent = message;
  saveState.style.color = color;
}

async function readApiResult(response) {
  const text = await response.text();

  try {
    return JSON.parse(text);
  }
  catch (error) {
    return {
      ok: false,
      message: text || "Le serveur local n'a pas renvoyé de détail."
    };
  }
}

function renderHero() {
  editorTitle.textContent = sectionTitles.hero;
  form.innerHTML = [
    field("Titre principal", "hero.title", siteData.hero.title),
    field("Premier texte", "hero.paragraphs.0", siteData.hero.paragraphs[0], { multiline: true }),
    field("Deuxième texte", "hero.paragraphs.1", siteData.hero.paragraphs[1], { multiline: true }),
    field("Troisième texte", "hero.paragraphs.2", siteData.hero.paragraphs[2], { multiline: true }),
    field("Image", "hero.image", siteData.hero.image, {
      helper: "Exemple : images/hero_caromancie.png"
    }),
    field("Texte alternatif de l'image", "hero.imageAlt", siteData.hero.imageAlt)
  ].join("");
  bindFieldValues();
}

function renderPhilosophy() {
  editorTitle.textContent = sectionTitles.philosophy;
  const cards = siteData.philosophy.cards
    .map((card, index) => `<div class="group">
      <div class="group-header">
        <h3>Carte ${index + 1}</h3>
        <button class="danger-button compact" type="button" data-remove-card="${index}">Supprimer</button>
      </div>
      ${field("Titre", `philosophy.cards.${index}.title`, card.title)}
      ${field("Texte", `philosophy.cards.${index}.text`, card.text, { multiline: true })}
    </div>`)
    .join("");

  form.innerHTML = `${field("Titre de section", "philosophy.title", siteData.philosophy.title)}
    ${cards}
    <button class="ghost-button" type="button" id="addCard">Ajouter une carte</button>`;

  bindFieldValues();

  form.querySelector("#addCard").addEventListener("click", () => {
    siteData.philosophy.cards.push({
      title: "Nouvelle carte",
      text: "Texte à personnaliser."
    });
    setDirty();
    renderPhilosophy();
  });

  form.querySelectorAll("[data-remove-card]").forEach((button) => {
    button.addEventListener("click", () => {
      siteData.philosophy.cards.splice(Number(button.dataset.removeCard), 1);
      setDirty();
      renderPhilosophy();
    });
  });
}

function renderContact() {
  editorTitle.textContent = sectionTitles.contact;
  form.innerHTML = [
    field("Titre", "contact.title", siteData.contact.title),
    field("Premier texte", "contact.paragraphs.0", siteData.contact.paragraphs[0], { multiline: true }),
    field("Deuxième texte", "contact.paragraphs.1", siteData.contact.paragraphs[1], { multiline: true })
  ].join("");
  bindFieldValues();
}

function renderSettings() {
  editorTitle.textContent = sectionTitles.settings;
  form.innerHTML = [
    field("Nom du site", "site.name", siteData.site.name),
    field("Titre de l'onglet", "site.title", siteData.site.title),
    field("Phrase de signature", "site.tagline", siteData.site.tagline),
    field("Copyright", "footer.copyright", siteData.footer.copyright),
    field("Texte du pied de page", "footer.text", siteData.footer.text)
  ].join("");
  bindFieldValues();
}

function renderEditor() {
  tabs.forEach((tab) => {
    tab.classList.toggle("is-active", tab.dataset.section === currentSection);
  });

  const renderers = {
    hero: renderHero,
    philosophy: renderPhilosophy,
    contact: renderContact,
    settings: renderSettings
  };

  renderers[currentSection]();
}

async function loadSite() {
  const response = await fetch("/api/site");
  siteData = await response.json();
  renderEditor();
}

async function saveSite() {
  saveButton.disabled = true;
  setStatus("Enregistrement...");

  const response = await fetch("/api/site", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(siteData)
  });

  if (!response.ok) {
    saveState.textContent = "Erreur pendant l'enregistrement";
    saveState.style.color = "#a04444";
    saveButton.disabled = false;
    return false;
  }

  setSaved();
  saveButton.disabled = false;
  previewFrame.src = `/preview?t=${Date.now()}`;
  return true;
}

async function publishSite() {
  publishButton.disabled = true;
  saveButton.disabled = true;
  setStatus("Préparation de la mise en ligne...");

  try {
    if (hasUnsavedChanges) {
      const saved = await saveSite();
      if (!saved) {
        return;
      }
    }

    setStatus("Envoi vers GitHub...");

    const response = await fetch("/api/publish", {
      method: "POST"
    });
    const result = await readApiResult(response);

    if (!response.ok || !result.ok) {
      setStatus(result.message || "Erreur pendant la mise en ligne", "#a04444");
      return;
    }

    setStatus(result.message || "Mis en ligne", "#587461");
  }
  catch (error) {
    setStatus(error.message || "Erreur pendant la mise en ligne", "#a04444");
  }
  finally {
    publishButton.disabled = false;
    saveButton.disabled = false;
  }
}

tabs.forEach((tab) => {
  tab.addEventListener("click", () => {
    currentSection = tab.dataset.section;
    renderEditor();
  });
});

saveButton.addEventListener("click", saveSite);
publishButton.addEventListener("click", publishSite);
refreshPreview.addEventListener("click", () => {
  previewFrame.src = `/preview?t=${Date.now()}`;
});

loadSite();
