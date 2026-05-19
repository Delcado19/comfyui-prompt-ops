const state = {
  library: null,
  categoryIndex: 0,
  snippetIndex: 0,
  dirty: false,
};

const elements = {
  status: document.querySelector("#status"),
  categoryList: document.querySelector("#category-list"),
  snippetList: document.querySelector("#snippet-list"),
  snippetTitle: document.querySelector("#snippet-title"),
  addCategory: document.querySelector("#add-category-btn"),
  addSnippet: document.querySelector("#add-snippet-btn"),
  deleteSnippetButton: document.querySelector("#delete-snippet-btn"),
  deleteCategoryButton: document.querySelector("#delete-category-btn"),
  saveButton: document.querySelector("#save-btn"),
  generateButton: document.querySelector("#generate-btn"),
  installButton: document.querySelector("#install-btn"),
  log: document.querySelector("#log"),
  form: document.querySelector("#editor-form"),
  categoryLabel: document.querySelector("#category-label"),
  categoryId: document.querySelector("#category-id"),
  categoryPrefix: document.querySelector("#category-prefix"),
  categoryOrder: document.querySelector("#category-order"),
  snippetId: document.querySelector("#snippet-id"),
  snippetTrigger: document.querySelector("#snippet-trigger"),
  snippetWord: document.querySelector("#snippet-word"),
  snippetText: document.querySelector("#snippet-text"),
};

function slugify(value) {
  return String(value || "")
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "_")
    .replace(/^_+|_+$/g, "");
}

function currentCategory() {
  return state.library?.categories?.[state.categoryIndex] || null;
}

function currentSnippet() {
  const category = currentCategory();
  return category?.snippets?.[state.snippetIndex] || null;
}

function setStatus(message) {
  elements.status.textContent = `${message}${state.dirty ? " - unsaved" : ""}`;
}

function refreshStatus() {
  const base = elements.status.dataset.base || "Ready";
  setStatus(base);
}

function setPersistentStatus(message) {
  elements.status.dataset.base = message;
  setStatus(message);
}

function setLog(message, open = true) {
  elements.log.textContent = message;
  elements.log.hidden = !open;
}

function markDirty() {
  state.dirty = true;
  setPersistentStatus("Editing");
}

function textNode(value) {
  return document.createTextNode(String(value || ""));
}

function ensureSelection() {
  if (!state.library.categories.length) {
    state.categoryIndex = -1;
    state.snippetIndex = -1;
    return;
  }

  state.categoryIndex = Math.max(0, Math.min(state.categoryIndex, state.library.categories.length - 1));
  const category = currentCategory();
  const count = category.snippets?.length || 0;
  state.snippetIndex = count ? Math.max(0, Math.min(state.snippetIndex, count - 1)) : -1;
}

function renderCategories() {
  elements.categoryList.innerHTML = "";

  state.library.categories.forEach((category, index) => {
    const button = document.createElement("button");
    button.type = "button";
    button.className = `row${index === state.categoryIndex ? " active" : ""}`;

    const main = document.createElement("span");
    main.className = "row-main";

    const title = document.createElement("strong");
    title.append(textNode(category.label));

    const detail = document.createElement("span");
    detail.append(textNode(`:${category.prefix}_`));

    const count = document.createElement("span");
    count.className = "row-meta";
    count.append(textNode(category.snippets.length));

    main.append(title, detail);
    button.append(main, count);

    button.addEventListener("click", () => {
      saveFormToState();
      state.categoryIndex = index;
      state.snippetIndex = category.snippets.length ? 0 : -1;
      render();
    });
    elements.categoryList.append(button);
  });
}

function renderSnippets() {
  const category = currentCategory();
  elements.snippetList.innerHTML = "";
  elements.snippetTitle.textContent = category ? `${category.label} Snippets` : "Snippets";

  if (!category) return;

  category.snippets.forEach((snippet, index) => {
    const button = document.createElement("button");
    button.type = "button";
    button.className = `row${index === state.snippetIndex ? " active" : ""}`;

    const main = document.createElement("span");
    main.className = "row-main";

    const title = document.createElement("strong");
    title.append(textNode(snippet.trigger));

    const detail = document.createElement("span");
    detail.append(textNode(snippet.text));

    const chevron = document.createElement("span");
    chevron.className = "row-chevron";
    chevron.append(textNode(">"));

    main.append(title, detail);
    button.append(main, chevron);

    button.addEventListener("click", () => {
      saveFormToState();
      state.snippetIndex = index;
      render();
    });
    elements.snippetList.append(button);
  });
}

function renderEditor() {
  const category = currentCategory();
  const snippet = currentSnippet();
  const hasCategory = Boolean(category);
  const hasSnippet = Boolean(snippet);

  elements.categoryLabel.disabled = !hasCategory;
  elements.categoryId.disabled = !hasCategory;
  elements.categoryPrefix.disabled = !hasCategory;
  elements.categoryOrder.disabled = !hasCategory;
  elements.snippetId.disabled = !hasSnippet;
  elements.snippetTrigger.disabled = !hasSnippet;
  elements.snippetWord.disabled = !hasSnippet;
  elements.snippetText.disabled = !hasSnippet;
  elements.addSnippet.disabled = !hasCategory;
  elements.deleteCategoryButton.disabled = !hasCategory;
  elements.deleteSnippetButton.disabled = !hasSnippet;

  elements.categoryLabel.value = category?.label || "";
  elements.categoryId.value = category?.id || "";
  elements.categoryPrefix.value = category?.prefix || "";
  elements.categoryOrder.value = category?.order || "";
  elements.snippetId.value = snippet?.id || "";
  elements.snippetTrigger.value = snippet?.trigger || "";
  elements.snippetWord.checked = snippet?.word !== false;
  elements.snippetText.value = snippet?.text || "";
}

function render() {
  ensureSelection();
  renderCategories();
  renderSnippets();
  renderEditor();
  refreshStatus();
}

function saveFormToState() {
  const category = currentCategory();
  const snippet = currentSnippet();

  if (!category) return;

  category.label = elements.categoryLabel.value.trim() || category.label;
  category.id = slugify(elements.categoryId.value || category.label);
  category.prefix = slugify(elements.categoryPrefix.value || category.id);
  category.order = Number(elements.categoryOrder.value || category.order || 500);

  if (!snippet) return;

  snippet.id = slugify(elements.snippetId.value || snippet.id);
  snippet.trigger = elements.snippetTrigger.value.trim() || `:${category.prefix}_${snippet.id}`;
  snippet.word = elements.snippetWord.checked;
  snippet.text = elements.snippetText.value.trim();
}

async function requestJson(url, options = {}) {
  const response = await fetch(url, {
    headers: { "Content-Type": "application/json" },
    ...options,
  });
  const data = await response.json().catch(() => ({}));

  if (!response.ok) {
    throw new Error(data.error || `Request failed: ${response.status}`);
  }

  return data;
}

async function loadLibrary() {
  state.library = await requestJson("/api/library");
  state.categoryIndex = 0;
  state.snippetIndex = 0;
  state.dirty = false;
  elements.status.dataset.base = "Ready";
  render();
}

async function saveLibrary() {
  saveFormToState();
  const saved = await requestJson("/api/library", {
    method: "PUT",
    body: JSON.stringify(state.library),
  });
  state.library = saved;
  state.dirty = false;
  elements.status.dataset.base = "Saved";
  render();
}

function commandOutput(data) {
  return (data.results || [])
    .map((result) => `> ${result.command}\n${result.stdout || ""}${result.stderr || ""}`.trim())
    .join("\n\n");
}

elements.form.addEventListener("input", (event) => {
  const category = currentCategory();
  const snippet = currentSnippet();

  if (event.target === elements.categoryLabel && category && !elements.categoryId.value) {
    elements.categoryId.value = slugify(elements.categoryLabel.value);
  }

  if (event.target === elements.snippetId && category && snippet) {
    elements.snippetTrigger.value = `:${category.prefix}_${slugify(elements.snippetId.value)}`;
  }

  markDirty();
});

elements.addCategory.addEventListener("click", () => {
  saveFormToState();
  const nextOrder = Math.max(0, ...state.library.categories.map((category) => Number(category.order) || 0)) + 10;
  state.library.categories.push({
    id: "new_category",
    label: "New Category",
    prefix: "new",
    order: nextOrder,
    snippets: [],
  });
  state.categoryIndex = state.library.categories.length - 1;
  state.snippetIndex = -1;
  markDirty();
  render();
});

elements.addSnippet.addEventListener("click", () => {
  saveFormToState();
  const category = currentCategory();
  if (!category) return;
  const id = "new_snippet";
  category.snippets.push({
    id,
    trigger: `:${category.prefix}_${id}`,
    word: true,
    text: "new prompt text",
  });
  state.snippetIndex = category.snippets.length - 1;
  markDirty();
  render();
});

elements.deleteSnippetButton.addEventListener("click", () => {
  const category = currentCategory();
  if (!category || !currentSnippet()) return;

  category.snippets.splice(state.snippetIndex, 1);
  state.snippetIndex = Math.min(state.snippetIndex, category.snippets.length - 1);

  markDirty();
  render();
});

elements.deleteCategoryButton.addEventListener("click", () => {
  const category = currentCategory();
  if (!category) return;

  const confirmed = window.confirm(`Delete category '${category.label}' and all snippets?`);
  if (!confirmed) return;

  state.library.categories.splice(state.categoryIndex, 1);
  state.categoryIndex = Math.min(state.categoryIndex, state.library.categories.length - 1);
  state.snippetIndex = 0;

  markDirty();
  render();
});

elements.saveButton.addEventListener("click", async () => {
  try {
    setStatus("Saving");
    await saveLibrary();
    setLog("Saved library.", false);
  } catch (error) {
    setStatus("Save failed");
    setLog(error.message);
  }
});

elements.generateButton.addEventListener("click", async () => {
  try {
    setStatus("Generating");
    await saveLibrary();
    const data = await requestJson("/api/generate", { method: "POST" });
    setLog(commandOutput(data));
    setPersistentStatus("Generated");
  } catch (error) {
    setStatus("Generate failed");
    setLog(error.message);
  }
});

elements.installButton.addEventListener("click", async () => {
  try {
    setStatus("Installing");
    await saveLibrary();
    const data = await requestJson("/api/install", { method: "POST" });
    setLog(commandOutput(data));
    setPersistentStatus("Installed");
  } catch (error) {
    setStatus("Install failed");
    setLog(error.message);
  }
});

loadLibrary().catch((error) => {
  setStatus("Load failed");
  setLog(error.message);
});
