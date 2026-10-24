---
name: distill
description: Write what a teaching session taught into the vault's Knowledge graph, as one note per proposition linked to its premises. Use at the end of every teaching session, or when the learner asks to save, extract, or import notes into the graph.
---

# Distill

The knowledge graph is the record that connects sessions. Future probes read it so they do not start from zero. Practice sessions draw problems from it. It stores ideas and how they connect. It does not store grades.

The format is **propositions and reasoning chains**. A proposition is one claim. A chain is the set of premises a claim follows from. This keeps a large body of knowledge in few tokens and keeps the connections exact.

## Procedure

1. Read the session note in `Sessions/` (the newest file, or the one the learner names).
2. List the propositions the session established. Include only what was taught and checked. Do not add ideas the session did not cover.
3. For each proposition, find its premises: the propositions it was derived from in the session. A foundation has no premises.
4. Search for existing notes first: `grep -ril "<key words>" Knowledge/`. Reuse an existing note when it states the same claim. Link new notes to existing premises.
5. Write or update the notes.
6. Report the list of notes you wrote and changed.

## Note format

Path: `Knowledge/<claim-in-a-few-words>.md`. Use lowercase words and hyphens for the file name, for example `Knowledge/line-integral-sums-work-along-a-path.md`.

```markdown
---
type: proposition
kind: foundation | derived
topics: [differential-forms]
sessions: ["[[Sessions/2026-10-24 1530]]"]
---

A 1-form at a point is a linear map from tangent vectors to numbers.

## Follows from

- [[covector-is-a-linear-map-from-vectors-to-numbers]]
- [[tangent-space-holds-velocities-at-a-point]]

## Reasoning

One or two sentences: the move that takes the premises to this claim.
```

Rules:

- One claim per note. State it as a plain sentence. Write math in LaTeX.
- `kind: foundation` notes have no "Follows from" section and no "Reasoning" section.
- Every link in "Follows from" points to another proposition note. Create the premise note if it does not exist.
- When a note already exists, add the new session to `sessions` and add new premises. Do not delete content.
- Imported notes: when the learner gives a file of their own notes, apply the same procedure with that file as the source. Put the file path in `sessions` in place of a session link.

Obsidian's graph view shows the result. Each arrow points from a claim to a premise it rests on.
