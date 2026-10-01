import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

// Fast is a mode of a model, not a separate model. Two mechanisms:
// - variantModels: the request's model ID gets a "-fast" suffix (Cursor serves
//   the same model faster under that ID), so no *-fast entries in models.json.
// - priorityModels: service_tier=priority. Add IDs *only after* confirming the
//   gateway/deployment accepts it.
// Only type imports from pi-coding-agent: prime loads this file too and does
// not ship that package.
const DEFAULT_VARIANT_MODELS: string[] = [];
const DEFAULT_PRIORITY_MODELS: string[] = [];
const CONFIG_PATH = fileURLToPath(new URL("./fast-mode.json", import.meta.url));
type Config = { persistState: boolean; active: boolean; variantModels: string[]; priorityModels: string[] };
const defaults: Config = {
  persistState: true,
  active: false,
  variantModels: DEFAULT_VARIANT_MODELS,
  priorityModels: DEFAULT_PRIORITY_MODELS,
};

const strings = (value: unknown, fallback: string[]) =>
  Array.isArray(value) ? value.filter((id: unknown): id is string => typeof id === "string") : fallback;

function loadConfig(): Config {
  if (!existsSync(CONFIG_PATH)) {
    writeFileSync(CONFIG_PATH, `${JSON.stringify(defaults, null, 2)}\n`, { mode: 0o600 });
    return { ...defaults };
  }
  try {
    const data = JSON.parse(readFileSync(CONFIG_PATH, "utf8"));
    return {
      persistState: typeof data.persistState === "boolean" ? data.persistState : defaults.persistState,
      active: typeof data.active === "boolean" ? data.active : defaults.active,
      variantModels: strings(data.variantModels, defaults.variantModels),
      priorityModels: strings(data.priorityModels, defaults.priorityModels),
    };
  } catch (error) {
    console.warn(`[fast-mode] Cannot read ${CONFIG_PATH}: ${String(error)}`);
    return { ...defaults };
  }
}

export default function (pi: ExtensionAPI) {
  let config: Config = { ...defaults };
  let active = false;

  function save() {
    if (config.persistState) {
      // Re-read to preserve changes to the allowlists made while running.
      const current = loadConfig();
      writeFileSync(CONFIG_PATH, `${JSON.stringify({ ...current, active }, null, 2)}\n`, { mode: 0o600 });
    }
  }

  const key = (ctx: ExtensionContext) => (ctx.model ? `${ctx.model.provider}/${ctx.model.id}` : "");
  const kind = (ctx: ExtensionContext) =>
    config.variantModels.includes(key(ctx)) ? "model variant" : config.priorityModels.includes(key(ctx)) ? "priority service tier" : undefined;

  function status(ctx: ExtensionContext): string {
    if (!ctx.model) return "No model selected.";
    const how = kind(ctx);
    if (!how) return `No known fast mode for ${key(ctx)}. Add it to variantModels or priorityModels in ${CONFIG_PATH}.`;
    return `Fast ${active ? "on" : "off"} (${how}): ${key(ctx)}`;
  }

  function toggle(ctx: ExtensionContext, requested?: boolean) {
    active = requested ?? !active;
    save();
    ctx.ui.notify(kind(ctx) ? status(ctx) : `Fast ${active ? "on" : "off"}; ${status(ctx)}`, kind(ctx) ? "info" : "warning");
  }

  pi.registerCommand("fast", {
    description: "Toggle fast mode for supported models (/fast [on|off|status])",
    getArgumentCompletions: (prefix) => {
      const items = ["on", "off", "status"].filter((value) => value.startsWith(prefix));
      return items.length ? items.map((value) => ({ value, label: value })) : null;
    },
    handler: async (args, ctx) => {
      const action = args.trim().toLowerCase();
      if (action === "status") ctx.ui.notify(status(ctx), "info");
      else if (action === "" || action === "on" || action === "off") toggle(ctx, action === "" ? undefined : action === "on");
      else ctx.ui.notify("Usage: /fast [on|off|status]", "warning");
    },
  });
  pi.registerShortcut("ctrl+alt+f", {
    description: "Toggle fast mode for the current model",
    handler: (ctx) => toggle(ctx),
  });

  pi.on("before_provider_request", (event, ctx) => {
    const payload = event.payload;
    if (!active || !payload || typeof payload !== "object" || Array.isArray(payload)) return;
    const how = kind(ctx);
    if (how === "model variant" && typeof payload.model === "string" && !payload.model.endsWith("-fast")) {
      return { ...payload, model: `${payload.model}-fast` };
    }
    if (how === "priority service tier") return { ...payload, service_tier: "priority" };
  });

  pi.on("session_start", async () => {
    config = loadConfig();
    active = config.persistState && config.active;
  });
}
