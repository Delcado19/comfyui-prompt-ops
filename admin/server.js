const childProcess = require("node:child_process");
const crypto = require("node:crypto");
const fs = require("node:fs/promises");
const path = require("node:path");

const express = require("express");
const helmet = require("helmet");
const YAML = require("yaml");

const repoRoot = path.resolve(__dirname, "..");
const libraryFile = path.join(repoRoot, "library", "prompt_library.yml");
const publicDir = path.join(__dirname, "public");

const app = express();
const port = Number(process.env.PORT || 5177);
const csrfToken = crypto.randomBytes(32).toString("hex");

app.use(
  helmet({
    contentSecurityPolicy: {
      directives: {
        defaultSrc: ["'self'"],
        baseUri: ["'self'"],
        formAction: ["'self'"],
        imgSrc: ["'self'", "data:"],
        objectSrc: ["'none'"],
        scriptSrc: ["'self'"],
        styleSrc: ["'self'"],
      },
    },
  }),
);
app.use(express.json({ limit: "2mb" }));
app.use(express.static(publicDir));

function slugify(value) {
  return String(value || "")
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "_")
    .replace(/^_+|_+$/g, "");
}

function normalizeLibrary(input) {
  const categories = Array.isArray(input.categories) ? input.categories : [];
  const seenCategoryIds = new Set();
  const seenPrefixes = new Set();
  const seenTriggers = new Set();

  const normalized = {
    version: Number(input.version || 1),
    categories: categories.map((category, categoryIndex) => {
      const id = slugify(category.id || category.label);
      const prefix = slugify(category.prefix || id);
      const label = String(category.label || id).trim();
      const order = Number.isFinite(Number(category.order))
        ? Number(category.order)
        : (categoryIndex + 1) * 10;

      if (!id) throw new Error("Category id is required.");
      if (!prefix) throw new Error(`Category '${id}' needs a prefix.`);
      if (seenCategoryIds.has(id)) throw new Error(`Duplicate category id: ${id}`);
      if (seenPrefixes.has(prefix)) throw new Error(`Duplicate category prefix: ${prefix}`);

      seenCategoryIds.add(id);
      seenPrefixes.add(prefix);

      const snippets = Array.isArray(category.snippets) ? category.snippets : [];

      return {
        id,
        label,
        prefix,
        order,
        snippets: snippets.map((snippet) => {
          const snippetId = slugify(snippet.id || snippet.trigger);
          const trigger = String(snippet.trigger || `:${prefix}_${snippetId}`).trim();
          const text = String(snippet.text || "").trim();
          const word = !Object.is(snippet.word, false);

          if (!snippetId) throw new Error(`Snippet id is required in category '${id}'.`);
          if (!/^:[a-z0-9_]+$/.test(trigger)) {
            throw new Error(`Invalid trigger '${trigger}'.`);
          }
          if (!text) throw new Error(`Snippet '${snippetId}' in '${id}' needs text.`);
          if (seenTriggers.has(trigger)) throw new Error(`Duplicate trigger: ${trigger}`);

          seenTriggers.add(trigger);

          return {
            id: snippetId,
            trigger,
            word,
            text,
          };
        }),
      };
    }),
  };

  normalized.categories.sort((a, b) => a.order - b.order || a.id.localeCompare(b.id));
  return normalized;
}

async function readLibrary() {
  const raw = await fs.readFile(libraryFile, "utf8");
  return normalizeLibrary(YAML.parse(raw));
}

async function writeLibrary(library) {
  const normalized = normalizeLibrary(library);
  const yaml = YAML.stringify(normalized, {
    lineWidth: 0,
    minContentWidth: 120,
  });

  await fs.mkdir(path.dirname(libraryFile), { recursive: true });
  await fs.writeFile(libraryFile, yaml, "utf8");
  return normalized;
}

function runPowerShell(scriptName, args = []) {
  const scriptPath = path.join(repoRoot, "scripts", scriptName);
  const command = process.env.PWSH || "pwsh";

  return new Promise((resolve, reject) => {
    childProcess.execFile(
      command,
      ["-NoProfile", "-ExecutionPolicy", "Bypass", "-File", scriptPath, ...args],
      {
        cwd: repoRoot,
        windowsHide: true,
        maxBuffer: 1024 * 1024 * 5,
      },
      (error, stdout, stderr) => {
        const result = {
          command: `${command} ${scriptName}`,
          stdout,
          stderr,
        };

        if (error) {
          error.result = result;
          reject(error);
          return;
        }

        resolve(result);
      },
    );
  });
}

async function runPipeline() {
  const steps = [
    "generate_snippets_from_library.ps1",
    "validate_yaml.ps1",
    "validate_snippets.ps1",
    "check_duplicate_triggers.ps1",
    "generate_prompt_builder.ps1",
    "generate_snippet_docs.ps1",
  ];

  const results = [];

  for (const step of steps) {
    results.push(await runPowerShell(step));
  }

  return results;
}

function requireCsrf(request, response, next) {
  // The local admin UI has no session layer, so a process-local token gates same-origin state changes.
  const header = request.get("x-csrf-token") || "";
  const headerToken = Buffer.from(header);
  const expectedToken = Buffer.from(csrfToken);
  if (headerToken.length !== expectedToken.length || !crypto.timingSafeEqual(headerToken, expectedToken)) {
    response.status(403).json({ error: "Invalid CSRF token." });
    return;
  }

  next();
}

app.get("/api/library", async (_request, response) => {
  try {
    response.json(await readLibrary());
  } catch (error) {
    response.status(500).json({ error: error.message });
  }
});

app.get("/api/csrf-token", (_request, response) => {
  response.json({ csrfToken });
});

app.put("/api/library", requireCsrf, async (request, response) => {
  try {
    const library = await writeLibrary(request.body);
    response.json(library);
  } catch (error) {
    response.status(400).json({ error: error.message });
  }
});

app.post("/api/generate", requireCsrf, async (_request, response) => {
  try {
    response.json({ results: await runPipeline() });
  } catch (error) {
    response.status(500).json({
      error: error.message,
      result: error.result || null,
    });
  }
});

app.post("/api/install", requireCsrf, async (_request, response) => {
  try {
    // Regenerate before copying so Install can't deploy snippets that are
    // stale relative to the last-saved library.
    const results = await runPipeline();
    results.push(await runPowerShell("install_snippets.ps1"));
    response.json({ results });
  } catch (error) {
    response.status(500).json({
      error: error.message,
      result: error.result || null,
    });
  }
});

app.get(/.*/, (_request, response) => {
  response.sendFile(path.join(publicDir, "index.html"));
});

app.listen(port, "127.0.0.1", () => {
  console.log(`Prompt library admin running at http://127.0.0.1:${port}`);
});
