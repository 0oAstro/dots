import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { select } from "./cache";

export default async function (pi: ExtensionAPI) {
  const selection = select();
  for (const entry of selection.entries) {
    const module = await import(entry);
    const factory = module.default;
    if (typeof factory !== "function") throw new Error(`Invalid processes factory: ${entry}`);
    await factory(pi);
  }
}
