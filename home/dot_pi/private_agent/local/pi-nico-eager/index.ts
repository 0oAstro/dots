import registerNico from "../../npm/node_modules/pi-subagents/index.js";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  const deferredApi = new Proxy(pi, {
    get(target, key) {
      if (key === "registerTool") {
        return (tool: Parameters<ExtensionAPI["registerTool"]>[0]) => {
          if (tool.name === "subagents_enable") return;
          const deferred = tool.name === "subagent" || tool.name === "bg_wait";
          target.registerTool(deferred ? {
            ...tool,
            exposure: "deferred",
            namespace: {
              name: tool.name === "subagent" ? "delegation" : "background",
              description: tool.name === "subagent"
                ? "Operator-authorized specialist delegation and run management. Complexity alone never authorizes delegation."
                : "Waits for provider or detached jobs without native completion notifications.",
            },
          } : tool);
        };
      }
      const value = Reflect.get(target, key);
      return typeof value === "function" ? value.bind(target) : value;
    },
  });
  registerNico(deferredApi);
}
