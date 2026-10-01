import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { rgbColor, truncateToWidth } from "@earendil-works/pi-tui";

const coral = rgbColor(228, 138, 122);
const blue = rgbColor(79, 142, 179);
const yellow = rgbColor(234, 182, 93);

export default function (pi: ExtensionAPI) {
  pi.on("session_start", (_event, ctx) => {
    if (ctx.mode !== "tui") return;

    ctx.ui.setHeader((_tui, theme) => ({
      render(width) {
        const rows = [
          "",
          theme.style("█████████", { fg: coral }) + "   ",
          theme.style("▀▀▀", { fg: coral, bg: blue }) +
            theme.style("▀▀▀███", { fg: coral }) + "   ",
          theme.style("███", { fg: blue }) + "   " +
            theme.style("███", { fg: coral }) + "   ",
          theme.style("██████", { fg: blue }) + "   " +
            theme.style("███", { fg: yellow }),
          theme.style("███▀▀▀", { fg: blue }) + "   " +
            theme.style("███", { fg: yellow }),
          theme.style("███", { fg: blue }) + "      " +
            theme.style("███", { fg: yellow }),
          "",
        ];
        return rows.map((row) => truncateToWidth(row, width));
      },
      invalidate() {},
    }));
  });
}
