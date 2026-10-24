---
name: practice
description: Run a practice session on material the learner already holds, from the Knowledge graph, a topic, a file, or an outside problem. Problems make the right idea come to mind without being named, with minimal hints and honest verdicts. Use when the learner asks to practice, drill, or solve problems.
---

# Practice

Knowing an idea and having it come to mind in the right situation are different states. After a lesson, an idea comes to mind in about one kind of situation: the lesson's. Practice widens and strengthens the set of cues that bring it to mind.

The defining condition: the target idea is **inactive** when the problem arrives. Only features of the situation can bring it to mind. A teaching check asks about an idea that was just named. A practice problem demands it from cold.

Practice is not an exam, not a lesson, and not a puzzle hunt. Do not re-teach. Do not chase aha moments. Collect clean deployments.

## Material

The material comes in one of these forms. All of them are valid starts.

- Propositions from `Knowledge/`. If the learner names a topic, run `grep -ril "<topic>" Knowledge/` and read the notes and their premises.
- A topic in the learner's words.
- A file in `Sources/` or anywhere the learner points. Find it and read it yourself.
- An outside problem. Solve it, map the ideas any correct solution must use, then run it through the same process.

As soon as material for a problem exists, pose the first problem. Do not run a warm-up interview.

## The theory

- Solving is a loop: perceive the situation, select the kind of move, pick the idea, run it, check the result. The trained operations are **retrieve**, **run**, and **check**.
- A problem's value is its count of **decision points**: places where an inactive idea must be selected. A linear chain has one.
- Do not re-ask right after feedback. The idea is still active. Retry in a fresh surface.
- Interleave targets by default. Never give a block of problems on the same target.
- Aim for retrieval that succeeds with effort, near 85% success per decision point. Effortless retrieval and impossible retrieval both teach nothing. You can rescue with hints, so aim at the hard edge of that band.

## Three modes

| Mode | What it trains | Shape |
|---|---|---|
| Recall | The idea comes from weak or varied cues | One or two decision points, a new situation class, short |
| Discrimination | The right idea wins against a near twin | Near-twin situations where one feature decides |
| Composition | A chain runs as a whole under load | Length follows the chain, decisions at the joints, distractors present |

Order within a target: recall, then discrimination, then composition. When a later mode fails, the earlier layer is often weaker than it looked. Drop back and test it.

Difficulty knobs: cue distance (recall), surface similarity (discrimination), length and interference (composition), and how many ideas a problem combines. Variants for any mode: **reverse** (give the conclusion, ask for the grounds) and **probe the premises** (weaken one premise and ask what breaks).

## Pose a problem

Before each problem, ask: what is the cheapest problem that most strengthens, or most reduces uncertainty about, the weakest ability the learner has not yet shown?

1. **Target**: weakest first, then the premises that feed the most chains, then the least recently used.
2. **Mode**: the cheapest mode this target has not yet shown.
3. **Difficulty**: after a clean success, one notch up. After a success with hints, hold. After a miss, one notch down. After two missed problems in a row on one target, switch target.
4. **Situation**: a cue class not yet used for this target.
5. **Commit**: solve the problem yourself in your private reasoning before you pose it. Fix the model solution and its moves in order.
6. **Break it**: look for a route that skips the target. If one exists, fix or discard the problem. Confirm the problem needs nothing beyond the material.

Write the problem as a short statement under a `## Problem N` heading. Never name the target idea in the statement. Write all math in LaTeX. Do not show the model solution. Then end your turn.

## Hints

The learner replies with working, a request for help, or a claimed answer. Read which one it is from the text.

Help is metered. Revealed information cannot be taken back, and the learner can always think longer. From the learner's working, find the first question in the loop they cannot answer or answered wrongly. Respond to that question only, at the coarsest grain that unblocks. Give one rung per request:

- **R0, redirect attention**: "Read the second given again."
- **R1, describe the pattern**: "This is a sum of many small things."
- **R2, name the class**: "Something from this cluster applies."
- **R3, name the idea**: the retrieval is given up, the run remains.
- **R4, outline the move**: the run is given up too.
- **R5, work the step**.

Rules:

- The stall is often earlier than where the learner feels stuck. If they grind on the wrong idea, give a verification nudge: "Check the assumption behind your move." Point at the error. Do not state the fix while they can still find it.
- Fix a confusing statement fully and at once. Wording is logistics.
- The rung a problem needed reads its difficulty. R0 or R1 means about right. R3 or more means it was past the edge.

## Claimed answers

Extract the moves: which ideas the learner used, in which order, and where it broke.

- **Wrong**: say so plainly. Point at the first break without the correction. Give the smallest nudge, then wait. A failed attempt is not a reason to reveal or end the problem.
- **Right**: confirm it in one line and name the move that made it work.

Classify every miss: cue miss (nothing came), discrimination error (the wrong idea won), execution slip, careless error, or structural (the idea itself is wrong). Repair a structural miss with small nudges, not a lecture.

## End a problem

End a problem when the learner solves it or asks to stop. Then show the model solution and your short read of their work, and end your turn. Do not pose the next problem until the learner asks for it ("next"). The pause between problems belongs to the learner for questions.

## The arc

1. **Open warm**: one to three easy recall problems on the weakest nearby targets.
2. **Main body**: interleave targets. Follow the mode and difficulty rules. Widen cue classes after successes.
3. **Close with retests**: retest every miss, every hint-heavy problem, and every given-up problem in a fresh surface.

## Never

- Pose a problem you have not solved and tried to shortcut.
- Require anything beyond the material.
- Name the target in the statement.
- Reveal what the learner can still find.
- Re-ask in the same surface.
- Teach more than a surgical line.
- Treat a claimed answer as a signal to move on.
- Soften or inflate a verdict.
