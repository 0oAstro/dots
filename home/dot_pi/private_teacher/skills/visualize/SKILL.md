---
name: visualize
description: Add one correct, minimal figure to a lesson when an idea is clearer as a picture. Mermaid inline for structure and flow; the svg-maker subagent for spatial or geometric pictures such as coordinates, number lines, vectors, plots, and layouts.
---

# Visualize

A picture earns its place only when it shows what words cannot: shape, structure, direction, relation, or geometry. If prose or one equation already carries the idea, do not draw. A missing figure is cheaper than a false one.

## Choose the form

- **Structure, flow, dependency, sequence, state, tree, comparison**: write a ```mermaid block inline. Obsidian renders it. Keep to about seven nodes or fewer. Quote labels with spaces or symbols.
- **Positions and shapes** (coordinate geometry, number lines, vectors, function plots, physical layouts): send the `svg-maker` subagent.

## Brief the svg-maker

The most common failure is cramming. Cut to the fewest elements that carry the idea. For each element ask: if I delete it, is the idea still clear? If yes, delete it.

Give the concept and the exact elements: coordinates, labels, proportions, orientation, and the one idea the figure must show. The maker sees nothing of the lesson.

- Bad: "a diagram about vectors"
- Good: "Axes from -1 to 4 on both. Vector $v = (3, 1)$ from the origin in blue, labelled $v$. Vector $w = (1, 2)$ from the origin in orange, labelled $w$. Dashed copy of $w$ from the tip of $v$ to $(4, 3)$, and $v + w$ from the origin to $(4, 3)$ in black. Show that addition is tip to tail."

Dispatch it in the background with the `Agent` tool, `subagent_type: "svg-maker"`. Say in your reply that a figure is coming, and keep teaching.

## Embed the result

The maker returns:

```
RESULT:
filename: viz-<slug>-<timestamp>.png
path: <vault>/viz/viz-<slug>-<timestamp>.png
```

Embed it with an Obsidian wikilink and a width:

```
![[viz-<slug>-<timestamp>.png|500]]
```

Introduce the figure in one sentence and point at its parts by name. Do not narrate every element.

If it returns `RESULT: NONE`, simplify the brief or drop the figure. Never write an SVG or a PNG embed yourself. Correctness depends on the maker's render-and-look loop.
