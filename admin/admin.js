const form = document.querySelector("#editorForm");
const editorTitle = document.querySelector("#editorTitle");
const saveButton = document.querySelector("#saveButton");
const publishButton = document.querySelector("#publishButton");
const saveState = document.querySelector("#saveState");
const previewFrame = document.querySelector("#previewFrame");
const refreshPreview = document.querySelector("#refreshPreview");
const tabs = [...document.querySelectorAll(".section-tab")];

let siteData = null;
let currentSection = "pages";
let hasUnsavedChanges = false;
let lastFocusedTextarea = null;
let lastFocusedField = null;

const sectionTitles = {
  hero: "Bandeau",
  philosophy: "Approche",
  contact: "Contact",
  pages: "Pages",
  settings: "Réglages"
};

const pageTemplates = [
  {
    id: "presentation",
    name: "Page de présentation",
    description: "Idéale pour expliquer une approche, un parcours ou une activité.",
    page: {
      title: "Nouvelle page de présentation",
      slug: "presentation",
      intro: "Une introduction courte pour poser le cadre et donner envie de lire la suite.",
      sections: [
        {
          title: "Ce que tu trouveras ici",
          text: "Présente le sujet de la page avec des mots simples, concrets et accueillants."
        },
        {
          title: "Ma manière d'accompagner",
          text: "Explique ton approche, ton ton, ce qui rend ton accompagnement particulier."
        }
      ],
      callToAction: "Envie d'en parler ? Contacte-moi pour faire le point ensemble."
    }
  },
  {
    id: "offre",
    name: "Page d'offre",
    description: "Prête pour détailler une consultation, un service ou une formule.",
    page: {
      title: "Nouvelle offre",
      slug: "offre",
      intro: "Décris ici à qui s'adresse cette offre et ce qu'elle permet de clarifier.",
      sections: [
        {
          title: "Pour qui ?",
          text: "Indique les situations, besoins ou questions pour lesquels cette offre est adaptée."
        },
        {
          title: "Comment ça se passe ?",
          text: "Explique le déroulé, la durée, le format et ce que la personne peut attendre."
        },
        {
          title: "Ce que tu repars avec",
          text: "Mets en avant le résultat concret : clarté, apaisement, pistes d'action ou prochain pas."
        }
      ],
      callToAction: "Je réserve mon moment d'échange."
    }
  },
  {
    id: "faq",
    name: "Page questions fréquentes",
    description: "Utile pour rassurer et répondre aux questions avant le contact.",
    page: {
      title: "Questions fréquentes",
      slug: "questions-frequentes",
      intro: "Quelques réponses simples pour t'aider à savoir si cet accompagnement te convient.",
      sections: [
        {
          title: "Faut-il préparer quelque chose ?",
          text: "Tu peux venir avec une question précise ou simplement avec ce que tu ressens en ce moment."
        },
        {
          title: "Est-ce que la séance se fait à distance ?",
          text: "Oui, l'échange peut se faire en ligne, tranquillement, à ton rythme."
        },
        {
          title: "Et si je ne sais pas quoi demander ?",
          text: "Ce n'est pas un problème. On peut partir de ton ressenti et clarifier ensemble ce qui demande de l'attention."
        }
      ],
      callToAction: "Une autre question ? Écris-moi simplement."
    }
  }
];

const contentModules = [
  {
    id: "text",
    name: "Bloc de texte",
    description: "Un titre et un texte libre insere entre deux blocs de page.",
    block: {
      type: "text",
      width: 100,
      title: "Nouveau bloc de texte",
      text: "Texte a personnaliser."
    }
  },
  {
    id: "button",
    name: "Bouton",
    description: "Un lien visible pour guider vers une action.",
    snippet: `[bouton texte="Prendre rendez-vous" lien="#contact"]`
  },
  {
    id: "link",
    name: "Lien",
    description: "Un bloc lien insere entre deux blocs de page.",
    block: {
      type: "link",
      width: 100,
      text: "Lire la suite",
      url: "#contact"
    }
  },
  {
    id: "image",
    name: "Image",
    description: "Un bloc image insere entre deux blocs de page.",
    block: {
      type: "image",
      width: 100,
      source: "",
      alt: "",
      caption: "",
      link: ""
    }
  },
  {
    id: "box",
    name: "Encart doux",
    description: "Une information importante mise en valeur.",
    snippet: `[encart texte="Texte important a mettre en avant."]`
  },
  {
    id: "quote",
    name: "Citation",
    description: "Une phrase forte ou un temoignage court.",
    snippet: `[citation texte="Une phrase inspirante a personnaliser." source=""]`
  },
  {
    id: "separator",
    name: "Separateur",
    description: "Une respiration visuelle entre deux idees.",
    snippet: `[separateur]`
  },
  {
    id: "qa",
    name: "Question / reponse",
    description: "Une question frequente avec sa reponse.",
    snippet: `[question titre="Comment se deroule une seance ?" reponse="Reponse a personnaliser."]`
  }
];

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

function imageField(label, path, value, options = {}) {
  const id = path.replaceAll(".", "-");
  const helper = options.helper ? `<p class="helper">${options.helper}</p>` : "";
  const preview = value
    ? `<img class="image-preview" src="/${escapeHtml(value)}" alt="">`
    : `<p class="empty-state compact-state">Aucune image choisie.</p>`;
  const current = value ? `<p class="helper">Image actuelle : ${escapeHtml(value)}</p>` : "";

  return `<div class="field image-field">
    <label for="${id}">${label}</label>
    ${preview}
    <input id="${id}" type="file" accept="image/*" data-image-path="${path}">
    ${current}
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

function slugify(value) {
  return String(value || "page")
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 64) || "page";
}

function ensureUniqueSlug(slug, currentIndex = -1) {
  const base = slugify(slug);
  let candidate = base;
  let counter = 2;

  while (siteData.pages.some((page, index) => index !== currentIndex && page.slug === candidate)) {
    candidate = `${base}-${counter}`;
    counter += 1;
  }

  return candidate;
}

function normalizePageSlugs() {
  const used = new Set();

  siteData.pages = siteData.pages.map((page) => {
    const base = slugify(page.slug || page.title);
    let candidate = base;
    let counter = 2;

    while (used.has(candidate)) {
      candidate = `${base}-${counter}`;
      counter += 1;
    }

    used.add(candidate);
    return {
      ...page,
      slug: candidate
    };
  });
}

function getPath(object, path) {
  return path.split(".").reduce((value, key) => value?.[key], object);
}

function setPath(object, path, value) {
  const keys = path.split(".");
  const last = keys.pop();
  const target = keys.reduce((item, key) => {
    if (item[key] === undefined || item[key] === null) {
      item[key] = /^\d+$/.test(key) ? [] : {};
    }
    return item[key];
  }, object);
  target[last] = value;
}

function cloneTemplate(template) {
  return JSON.parse(JSON.stringify(template.page));
}

function getBlockWidth(section) {
  return Number(section?.width) === 50 ? 50 : 100;
}

function normalizePageSections(sections) {
  return sections.map((section) => ({
    ...section,
    width: getBlockWidth(section)
  }));
}

function ensureSiteShape() {
  siteData = siteData && typeof siteData === "object" ? siteData : {};

  siteData.site = siteData.site || {};
  siteData.hero = siteData.hero || {};
  siteData.philosophy = siteData.philosophy || {};
  siteData.contact = siteData.contact || {};
  siteData.footer = siteData.footer || {};

  if (!Array.isArray(siteData.navigation)) {
    siteData.navigation = [];
  }

  if (!Array.isArray(siteData.hero.paragraphs)) {
    siteData.hero.paragraphs = [];
  }

  if (!Array.isArray(siteData.philosophy.cards)) {
    siteData.philosophy.cards = [];
  }

  if (!Array.isArray(siteData.contact.paragraphs)) {
    siteData.contact.paragraphs = [];
  }

  if (!Array.isArray(siteData.pages)) {
    siteData.pages = [];
  }

  siteData.pages = siteData.pages.map((page) => ({
    ...page,
    sections: normalizePageSections(Array.isArray(page.sections) ? page.sections : [])
  }));
}

function bindFieldValues() {
  form.querySelectorAll("[data-path]").forEach((input) => {
    const value = getPath(siteData, input.dataset.path) ?? "";
    if (input.tagName === "INPUT" && input.type !== "file") {
      input.value = value;
    }

    input.addEventListener("input", () => {
      setPath(siteData, input.dataset.path, input.value);
      setDirty();
    });

    input.addEventListener("focus", () => {
      lastFocusedField = input;
    });

    if (input.tagName === "TEXTAREA") {
      input.addEventListener("focus", () => {
        lastFocusedTextarea = input;
      });
      input.addEventListener("click", () => {
        lastFocusedTextarea = input;
      });
      input.addEventListener("keyup", () => {
        lastFocusedTextarea = input;
      });
    }
  });
}

function modulePicker() {
  const modules = contentModules
    .map((module) => `<button class="module-option" type="button" data-module="${module.id}">
      <span>${escapeHtml(module.name)}</span>
      <small>${escapeHtml(module.description)}</small>
    </button>`)
    .join("");

  return `<div class="module-picker">
    <h3>Ajouter un module</h3>
    <p class="helper">Clique dans une zone de texte ou un bloc de page, puis choisis un module.</p>
    <div class="module-grid">${modules}</div>
  </div>`;
}

function bindModulePicker() {
  form.querySelectorAll("[data-module]").forEach((button) => {
    button.addEventListener("click", () => {
      const module = contentModules.find((item) => item.id === button.dataset.module);
      if (module.block) {
        insertPageBlock(module.block);
      }
      else {
        insertModuleSnippet(module.snippet);
      }
    });
  });
}

function cloneBlock(block) {
  return JSON.parse(JSON.stringify(block));
}

function getPageInsertionTarget() {
  const path = lastFocusedField?.dataset?.path || lastFocusedTextarea?.dataset?.path || "";
  const sectionMatch = path.match(/^pages\.(\d+)\.sections\.(\d+)\./);
  if (sectionMatch) {
    return {
      pageIndex: Number(sectionMatch[1]),
      insertIndex: Number(sectionMatch[2]) + 1
    };
  }

  const introMatch = path.match(/^pages\.(\d+)\.intro$/);
  if (introMatch) {
    return {
      pageIndex: Number(introMatch[1]),
      insertIndex: 0
    };
  }

  const ctaMatch = path.match(/^pages\.(\d+)\.callToAction$/);
  if (ctaMatch) {
    const pageIndex = Number(ctaMatch[1]);
    return {
      pageIndex,
      insertIndex: siteData.pages[pageIndex].sections.length
    };
  }

  if (currentSection === "pages" && siteData.pages.length > 0) {
    return {
      pageIndex: 0,
      insertIndex: siteData.pages[0].sections.length
    };
  }

  return null;
}

function insertPageBlock(block) {
  const target = getPageInsertionTarget();
  if (!target) {
    setStatus("Va dans Pages et clique a l'endroit ou ajouter ce bloc", "#a04444");
    return;
  }

  siteData.pages[target.pageIndex].sections.splice(target.insertIndex, 0, cloneBlock(block));
  setDirty();
  renderPages();
  setStatus("Bloc ajoute");
}

function insertModuleSnippet(snippet) {
  const textareas = [...form.querySelectorAll("textarea[data-path]")];
  const target = textareas.includes(lastFocusedTextarea) ? lastFocusedTextarea : textareas[0];

  if (!target) {
    setStatus("Aucune zone de texte disponible", "#a04444");
    return;
  }

  const start = target.selectionStart ?? target.value.length;
  const end = target.selectionEnd ?? target.value.length;
  const before = target.value.slice(0, start);
  const after = target.value.slice(end);
  const prefix = before && !before.endsWith("\n") ? "\n\n" : "";
  const suffix = after && !after.startsWith("\n") ? "\n\n" : "";
  const insertion = `${prefix}${snippet}${suffix}`;

  target.value = `${before}${insertion}${after}`;
  const cursor = before.length + insertion.length;
  target.setSelectionRange(cursor, cursor);
  target.focus();
  target.dispatchEvent(new Event("input", { bubbles: true }));
  setStatus("Module insere");
}

function renderPageSection(section, pageIndex, sectionIndex, sectionCount) {
  const width = getBlockWidth(section);
  const blockLabel = `Bloc ${sectionIndex + 1}`;
  const canMoveUp = sectionIndex > 0;
  const canMoveDown = sectionIndex < sectionCount - 1;
  const widthOptions = `
    <div class="field compact-field">
      <label for="section-width-${pageIndex}-${sectionIndex}">Largeur du bloc</label>
      <select id="section-width-${pageIndex}-${sectionIndex}" data-section-width="${pageIndex}:${sectionIndex}">
        <option value="100"${width === 100 ? " selected" : ""}>Pleine largeur</option>
        <option value="50"${width === 50 ? " selected" : ""}>Demi-largeur</option>
      </select>
    </div>`;
  const blockHeader = (typeLabel) => `<div class="block-heading">
    <h4>${blockLabel} - ${typeLabel}</h4>
  </div>`;
  const moveButtons = `<button class="ghost-button compact block-action-button" type="button" data-move-page-section="${pageIndex}:${sectionIndex}:up"${canMoveUp ? "" : " disabled"}>Monter</button>
    <button class="ghost-button compact block-action-button" type="button" data-move-page-section="${pageIndex}:${sectionIndex}:down"${canMoveDown ? "" : " disabled"}>Descendre</button>`;
  const removeButton = `<button class="danger-button compact block-action-button" type="button" data-remove-page-section="${pageIndex}:${sectionIndex}">Effacer</button>`;

  if (section.type === "image") {
    const preview = section.source
      ? `<img class="image-preview" src="/${escapeHtml(section.source)}" alt="${escapeHtml(section.alt || "")}">`
      : `<p class="empty-state compact-state">Aucune image choisie.</p>`;

    return `<div class="nested-group module-section" data-page-section-card="${pageIndex}:${sectionIndex}">
      <div class="group-header">
        ${blockHeader("Image")}
        <div class="inline-actions">${moveButtons}${removeButton}</div>
      </div>
      ${widthOptions}
      ${preview}
      <div class="field">
        <label for="image-upload-${pageIndex}-${sectionIndex}">Image</label>
        <input id="image-upload-${pageIndex}-${sectionIndex}" type="file" accept="image/*" data-image-upload="${pageIndex}:${sectionIndex}">
        <p class="helper">Choisis une image depuis l'ordinateur. Elle sera ajoutee au dossier images du site.</p>
      </div>
      ${field("Texte alternatif", `pages.${pageIndex}.sections.${sectionIndex}.alt`, section.alt)}
      ${field("Legende", `pages.${pageIndex}.sections.${sectionIndex}.caption`, section.caption)}
      ${field("Lien de l'image", `pages.${pageIndex}.sections.${sectionIndex}.link`, section.link, {
        helper: "Optionnel. Exemple : #contact, presentation.html ou https://..."
      })}
    </div>`;
  }

  if (section.type === "link") {
    return `<div class="nested-group module-section" data-page-section-card="${pageIndex}:${sectionIndex}">
      <div class="group-header">
        ${blockHeader("Lien")}
        <div class="inline-actions">${moveButtons}${removeButton}</div>
      </div>
      ${widthOptions}
      ${field("Texte du lien", `pages.${pageIndex}.sections.${sectionIndex}.text`, section.text)}
      ${field("Adresse du lien", `pages.${pageIndex}.sections.${sectionIndex}.url`, section.url, {
        helper: "Exemple : #contact, presentation.html ou https://..."
      })}
    </div>`;
  }

  const blockTitle = section.type === "text" ? "Bloc de texte" : "Bloc";

  return `<div class="nested-group" data-page-section-card="${pageIndex}:${sectionIndex}">
    <div class="group-header">
      ${blockHeader(blockTitle)}
      <div class="inline-actions">${moveButtons}${removeButton}</div>
    </div>
    ${widthOptions}
    ${field("Titre du bloc", `pages.${pageIndex}.sections.${sectionIndex}.title`, section.title)}
    ${field("Texte du bloc", `pages.${pageIndex}.sections.${sectionIndex}.text`, section.text, { multiline: true })}
  </div>`;
}

function movePageSection(pageIndex, fromIndex, toIndex) {
  const sections = siteData.pages[pageIndex]?.sections;
  if (
    !Array.isArray(sections) ||
    fromIndex === toIndex ||
    fromIndex < 0 ||
    toIndex < 0 ||
    fromIndex >= sections.length ||
    toIndex >= sections.length
  ) {
    return;
  }

  const [section] = sections.splice(fromIndex, 1);
  sections.splice(toIndex, 0, section);
  setDirty();
  renderPages();
  setStatus("Bloc deplace");
}

function bindPageSectionLayoutControls() {
  form.querySelectorAll("[data-section-width]").forEach((select) => {
    select.addEventListener("change", () => {
      const [pageIndex, sectionIndex] = select.dataset.sectionWidth.split(":").map(Number);
      siteData.pages[pageIndex].sections[sectionIndex].width = Number(select.value) === 50 ? 50 : 100;
      setDirty();
    });
  });
}

async function uploadImageFile(file) {
  const data = new FormData();
  data.append("image", file);

  setStatus("Ajout de l'image...");

  const response = await fetch("/api/images", {
    method: "POST",
    body: data
  });
  const result = await readApiResult(response);

  if (!response.ok || !result.ok) {
    setStatus(result.message || "Impossible d'ajouter l'image", "#a04444");
    return null;
  }

  return result.path;
}

async function uploadImageToPath(file, path) {
  const imagePath = await uploadImageFile(file);
  if (!imagePath) {
    return;
  }

  setPath(siteData, path, imagePath);
  setDirty();
  renderEditor();
  setStatus("Image ajoutee");
}

async function uploadSectionImage(file, pageIndex, sectionIndex) {
  const imagePath = await uploadImageFile(file);
  if (!imagePath) {
    return;
  }

  siteData.pages[pageIndex].sections[sectionIndex].source = imagePath;
  setDirty();
  renderPages();
  setStatus("Image ajoutee");
}

function bindImageUploads() {
  form.querySelectorAll("[data-image-path]").forEach((input) => {
    input.addEventListener("change", () => {
      const file = input.files?.[0];
      if (!file) {
        return;
      }

      uploadImageToPath(file, input.dataset.imagePath);
    });
  });

  form.querySelectorAll("[data-image-upload]").forEach((input) => {
    input.addEventListener("change", () => {
      const file = input.files?.[0];
      if (!file) {
        return;
      }

      const [pageIndex, sectionIndex] = input.dataset.imageUpload.split(":").map(Number);
      uploadSectionImage(file, pageIndex, sectionIndex);
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
    imageField("Image", "hero.image", siteData.hero.image, {
      helper: "Choisis une image depuis un dossier de l'ordinateur."
    }),
    field("Texte alternatif de l'image", "hero.imageAlt", siteData.hero.imageAlt)
  ].join("");
  bindFieldValues();
  bindImageUploads();
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

function renderPages() {
  editorTitle.textContent = sectionTitles.pages;
  const templates = pageTemplates
    .map((template) => `<button class="template-option" type="button" data-template="${template.id}">
      <span>${escapeHtml(template.name)}</span>
      <small>${escapeHtml(template.description)}</small>
    </button>`)
    .join("");

  const pages = siteData.pages.length
    ? siteData.pages.map((page, pageIndex) => {
      const sections = page.sections
        .map((section, sectionIndex) => renderPageSection(section, pageIndex, sectionIndex, page.sections.length))
        .join("");

      return `<div class="group page-group">
        <div class="group-header">
          <div>
            <h3>${escapeHtml(page.title || "Page sans titre")}</h3>
            <p class="helper">Adresse : /${escapeHtml(page.slug || "page")}.html</p>
          </div>
          <div class="inline-actions">
            <button class="ghost-button compact" type="button" data-preview-page="${pageIndex}">Aperçu</button>
            <button class="danger-button compact" type="button" data-remove-page="${pageIndex}">Supprimer</button>
          </div>
        </div>
        ${field("Titre de la page", `pages.${pageIndex}.title`, page.title)}
        ${field("Adresse de la page", `pages.${pageIndex}.slug`, page.slug, {
          helper: "Exemple : consultations ou questions-frequentes"
        })}
        ${field("Introduction", `pages.${pageIndex}.intro`, page.intro, { multiline: true })}
        ${sections}
        <button class="ghost-button compact" type="button" data-add-page-section="${pageIndex}">Ajouter un bloc</button>
        ${field("Appel à l'action", `pages.${pageIndex}.callToAction`, page.callToAction, { multiline: true, rows: 3 })}
      </div>`;
    }).join("")
    : `<p class="empty-state">Aucune page ajoutée pour le moment. Choisis un modèle ci-dessus pour démarrer.</p>`;

  form.innerHTML = `${modulePicker()}
    <p class="cms-version-note">Version blocs : les boutons Monter, Descendre et Effacer sont dans chaque bloc ci-dessous.</p>
    <div class="template-picker">
      <h3>Ajouter une page</h3>
      <div class="template-grid">${templates}</div>
    </div>
    ${pages}`;

  bindFieldValues();
  bindModulePicker();
  bindImageUploads();
  bindPageSectionLayoutControls();

  form.querySelectorAll("[data-template]").forEach((button) => {
    button.addEventListener("click", () => {
      const template = pageTemplates.find((item) => item.id === button.dataset.template);
      const page = cloneTemplate(template);
      page.slug = ensureUniqueSlug(page.slug);
      siteData.pages.push(page);
      setDirty();
      renderPages();
    });
  });

  form.querySelectorAll("[data-remove-page]").forEach((button) => {
    button.addEventListener("click", () => {
      siteData.pages.splice(Number(button.dataset.removePage), 1);
      setDirty();
      renderPages();
    });
  });

  form.querySelectorAll("[data-preview-page]").forEach((button) => {
    button.addEventListener("click", () => {
      const page = siteData.pages[Number(button.dataset.previewPage)];
      previewFrame.src = `/${slugify(page.slug)}.html?t=${Date.now()}`;
    });
  });

  form.querySelectorAll("[data-add-page-section]").forEach((button) => {
    button.addEventListener("click", () => {
      siteData.pages[Number(button.dataset.addPageSection)].sections.push({
        width: 100,
        title: "Nouveau bloc",
        text: "Texte à personnaliser."
      });
      setDirty();
      renderPages();
    });
  });

  form.querySelectorAll("[data-remove-page-section]").forEach((button) => {
    button.addEventListener("click", () => {
      const [pageIndex, sectionIndex] = button.dataset.removePageSection.split(":").map(Number);
      siteData.pages[pageIndex].sections.splice(sectionIndex, 1);
      setDirty();
      renderPages();
    });
  });

  form.querySelectorAll("[data-move-page-section]").forEach((button) => {
    button.addEventListener("click", () => {
      const [pageIndex, sectionIndex, direction] = button.dataset.movePageSection.split(":");
      const fromIndex = Number(sectionIndex);
      const toIndex = direction === "up" ? fromIndex - 1 : fromIndex + 1;
      movePageSection(Number(pageIndex), fromIndex, toIndex);
    });
  });

  form.querySelectorAll("[data-path$='.slug']").forEach((input) => {
    input.addEventListener("blur", () => {
      const pageIndex = Number(input.dataset.path.split(".")[1]);
      const nextSlug = ensureUniqueSlug(input.value, pageIndex);
      siteData.pages[pageIndex].slug = nextSlug;
      input.value = nextSlug;
      setDirty();
    });
  });
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
    pages: renderPages,
    settings: renderSettings
  };

  renderers[currentSection]();
}

async function loadSite() {
  try {
    const response = await fetch("/api/site");
    const text = await response.text();

    if (!response.ok) {
      throw new Error(text || "Impossible de charger les donnees du site.");
    }

    siteData = JSON.parse(text);
    ensureSiteShape();
    renderEditor();
  }
  catch (error) {
    form.innerHTML = `<p class="empty-state">${escapeHtml(error.message || "Le CMS n'a pas pu charger les donnees du site.")}</p>`;
    setStatus("Erreur de chargement", "#a04444");
  }
}

async function saveSite() {
  saveButton.disabled = true;
  setStatus("Enregistrement...");

  normalizePageSlugs();

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
