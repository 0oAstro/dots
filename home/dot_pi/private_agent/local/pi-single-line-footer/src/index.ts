import type { AssistantMessage } from "@earendil-works/pi-ai";
import type { ExtensionContext } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

function formatTokens(count: number): string {
  if (count < 1000) return `${Math.round(count)}`;
  if (count < 10_000) return `${(count / 1000).toFixed(1)}k`;
  if (count < 1_000_000) return `${Math.round(count / 1000)}k`;
  if (count < 10_000_000) return `${(count / 1_000_000).toFixed(1)}M`;
  return `${Math.round(count / 1_000_000)}M`;
}

function installFooter(ctx: ExtensionContext): void {
  if (ctx.mode !== "tui") return;

  ctx.ui.setFooter((tui, theme, footerData) => {
    let disposed = false;
    const refresh = () => {
      if (!disposed) tui.requestRender();
    };
    const unsubscribe = footerData.onBranchChange(refresh);
    const timer = setInterval(refresh, 1_000);
    timer.unref?.();

    const cleanup = () => {
      if (disposed) return;
      disposed = true;
      clearInterval(timer);
      unsubscribe();
    };

    return {
      invalidate: refresh,
      dispose: cleanup,
      render(width: number): string[] {
        if (disposed) return [];
        try {
          let input = 0;
          let output = 0;
          let cacheRead = 0;
          let cacheWrite = 0;
          let cost = 0;
          let latestHit: number | undefined;

          for (const entry of ctx.sessionManager.getEntries()) {
            let usage: AssistantMessage["usage"] | undefined;
            if (entry.type === "message" && entry.message.role === "assistant") {
              usage = (entry.message as AssistantMessage).usage;
              const prompt = usage.input + usage.cacheRead + usage.cacheWrite;
              latestHit = prompt > 0 ? (usage.cacheRead / prompt) * 100 : undefined;
            } else if (entry.type === "message" && entry.message.role === "toolResult") {
              usage = entry.message.usage;
            } else if (entry.type === "branch_summary" || entry.type === "compaction") {
              usage = entry.usage;
            }
            if (!usage) continue;
            input += usage.input;
            output += usage.output;
            cacheRead += usage.cacheRead;
            cacheWrite += usage.cacheWrite;
            cost += usage.cost.total;
          }

          const parts: string[] = [];
          for (const text of footerData.getExtensionStatuses().values()) {
            const clean = text.replace(/[\r\n\t]/g, " ").replace(/ +/g, " ").trim();
            if (clean) parts.push(clean);
          }
          if (input) parts.push(theme.fg("accent", `↑${formatTokens(input)}`));
          if (output) parts.push(theme.fg("success", `↓${formatTokens(output)}`));
          if (cacheRead) parts.push(theme.fg("muted", `R${formatTokens(cacheRead)}`));
          if (cacheWrite) parts.push(theme.fg("warning", `W${formatTokens(cacheWrite)}`));
          if ((cacheRead || cacheWrite) && latestHit !== undefined) {
            parts.push(theme.fg("success", `CH${latestHit.toFixed(1)}%`));
          }

          const subscription = /(?:codex|kimi-coding)/i.test(ctx.model?.provider ?? "");
          if (cost || subscription) {
            parts.push(theme.fg("warning", `$${cost.toFixed(3)}${subscription ? " (sub)" : ""}`));
          }

          const context = ctx.getContextUsage();
          const window = context?.contextWindow ?? ctx.model?.contextWindow ?? 0;
          const percent = context?.percent;
          const contextText = `${percent == null ? "?" : percent.toFixed(1)}%/${formatTokens(window)} (auto)`;
          const contextColor = percent != null && percent > 90 ? "error" : percent != null && percent > 70 ? "warning" : "muted";
          parts.push(theme.fg(contextColor, contextText));

          let left = parts.join(theme.fg("dim", " | "));
          const model = ctx.model?.id ?? "no-model";
          const thinking = ctx.thinkingLevel === "off" ? "thinking off" : ctx.thinkingLevel ?? "off";
          const right = ctx.model?.reasoning
            ? `${theme.fg("accent", model)} ${theme.fg("dim", "•")} ${theme.fg("muted", thinking)}`
            : theme.fg("accent", model);
          const maxLeft = Math.max(0, width - visibleWidth(right) - 2);
          if (visibleWidth(left) > maxLeft) left = truncateToWidth(left, maxLeft, "...");
          const gap = " ".repeat(Math.max(2, width - visibleWidth(left) - visibleWidth(right)));
          return [truncateToWidth(left + gap + right, width, "")];
        } catch {
          cleanup();
          return [];
        }
      },
    };
  });
}

export default function footerExtension(pi: { on: Function }): void {
  pi.on("session_start", (_event: unknown, ctx: ExtensionContext) => installFooter(ctx));
}
