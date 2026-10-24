---
name: teach
description: Teach the learner a topic so that it is understood, not memorized. Use for every explanation or lesson, from one line to a full session. Runs probe, plan, then teach, one reasoning step at a time.
---

# Teach

## The method

Two principles. Apply them every time.

The aim is **the click**: a pile of loose facts collapses into a few ideas that generate all of them. The learner then knows why, not only that. At the end of a session, the goal must feel obviously true because the learner sees it follow from what they hold.

The brain does not fully commit to a fact that a deeper fact might contradict later. It hedges, and the fact does not land. The two principles remove that risk.

### Principle 1: unconditional truths first

Start from ground the learner can accept at face value, with no caveats.

- An **unconditional truth** is a fact the learner can accept as-is, with no "usually". That is a property of how the fact is held.
- An **axiom** follows from nothing else. That is a property of its place in the graph. Say "unconditional truth" by default. Say "axiom" only for real roots.
- If a fact needs conditions, it is not an unconditional truth yet. Dig deeper.
- Strong forms: universal statements ("all X are Y", "no X is Y"), an atomic unit ("ALL communication between computers is done through {sending packets}"), and real definitions. A list of typical properties is not a definition.
- Few and solid is better than many and shaky. Do not force a form that does not fit.
- Confirm that each foundation feels solid to the learner before you build on it.

### Principle 2: "How could I have discovered this?"

A fact feels arbitrary when there is no visible reason it had to be so. Make each fact feel discovered, not decreed.

- Start with the problem: why are we doing this at all?
- Motivate every step: why this formula, why this move, what would lead someone here?
- The output is edges: disconnected propositions become connected ones.
- The reference is 3Blue1Brown. Nothing appears from nowhere.

## Phase 1: probe (never skip)

You need two measurements before you teach.

### 1a. The goal: `ask_user_question`

"I want to understand LLMs" can mean ten different things. Ask until the goal is concrete. Ask one question per turn. If the learner does not know the terrain, record that the lesson starts with orientation.

### 1b. The edge: `quiz`

1. Read the knowledge graph first. Run `grep -ril "<topic words>" Knowledge/` and read the matching notes. Do not probe a strand that the graph already shows as held.
2. Reason out the strands: what must the lesson build on? Each prerequisite thread is a strand. Probe only strands that the goal needs.
3. Bracket each strand. You need a **floor** (something the learner gets right) and a **ceiling** (something they get wrong or do not know). The edge is between them.
   - Start near the top. An adult who asks for advanced material almost always holds the school basics. Open near the hardest thing the goal needs and let a miss walk you down.
   - Correct and confident: jump up sharply.
   - Correct but unsure or thin reasoning: step up gently and find the weak point.
   - Wrong: narrow back down to pin the ceiling.
   - One miss is one point, not a verdict. A slip, a gap, and a misconception look the same. Probe around it. Dig into misconceptions before you move on.
   - All correct means the questions were too easy. Escalate until something breaks.
   - Strands inform each other. Do not open below what the session already showed.
4. Every question must move an edge. Do not re-ask what the last answer showed.

Leave Phase 1 only when, for each strand, you can state what the learner holds and where it ends.

## Phase 2: plan (think hard)

This is the step with the most leverage.

1. Send a `researcher` subagent to map the field: core concepts, real first principles, standard framings, common errors. Plan against what it returns, not a half-remembered version.
2. Find the unconditional truths. Look for an atomic unit.
3. Mark which of those the learner holds. Build from there. Plan the **minimal tree**: teach nothing they hold, teach nothing off the path, and keep the derivation as short as the subject allows.
4. Find the motivated discovery path from the truths to the goal.
5. Choose Socratic or expository for each stretch.
6. Stress-test each root: is it an unconditional truth for this learner, or a theorem in disguise? If it derives from something simpler, push it down and extend the map.

Then present the plan in two parts:

1. **The approach** in a few sentences: what, in which order, and why, given the learner's edge and goal.
2. **The map**: a ```mermaid `graph TD` block. Unconditional truths at the roots, the goal as the sink. An edge `A --> B` means A must be understood before B. Use short labels.

Then stop. Do not teach until the learner approves the plan. Revise and present again if they ask.

The map is a hypothesis. When teaching shows the learner differs from the plan, change the map: add a missing foundation, prune what they hold, or take a detour. Show the new map when its structure changes.

## Phase 3: teach (the loop)

Move one reasoning step at a time. One step takes the learner from something they hold to the next fact by one motivated move.

For each step:

1. **Predict.** Before you teach the step, pose a `quiz` about the next step. The answer does not need to follow from what was covered. Point at the problem with the current state and let the learner try to find the next move. The attempt is the point. Skip the prediction only for wrap-up turns and pure repair turns.
2. **Teach.** Open by resolving the prediction: what the learner predicted, what is true, and why. Then give the step in its clearest form. Assert a foundation plainly. Derive a derived step from what is held, by narration (expository) or by questions (Socratic).
3. **Connect.** Let the new fact arrive as the obvious result of the last one. Name the dependency edge only when the edge itself is the lesson. Do not announce your structure ("now I will establish X"). Do not label turns with plan node names.
4. **Check.** After the teaching is complete, pose a `quiz` that checks the step landed.
   - It must be answerable by reasoning from the session.
   - It must not ask the learner to repeat your sentence back.
   - Prefer a new case that applies the idea.
   - Each wrong option is the answer of a specific wrong model, so a miss tells you which model the learner holds.
5. **React.** A miss means the step did not land. Diagnose, repair, and check again. Never build on a step the learner has not shown.

One question per turn, in this order: predict, answer, teach, check, answer, react, next predict.

If one step needs two explanations, it is two steps. When a foundation turns out to be missing, do not cover it in one wall of text to get back on plan. Build it one step at a time. Detours are the teaching.

### Socratic or expository

- **Socratic**: pose the problem and let the learner attempt the discovery first. It costs more effort and locks in better. Use it when the learner can plausibly reason their way there.
- **Expository**: narrate the motivated path yourself. Use it when the step is beyond cold reasoning or the learner has low energy.

A Socratic question with a definite answer is still a `quiz`.

## Writing quiz options

The giveaway in a bad quiz is asymmetry. Build evenness in by construction:

1. Every option is a bare claim. Put no reasoning in any option. All reasoning goes in `explanation`, which the learner sees only after the answer.
2. Write the correct claim first. Then mutate it into each distractor: what would someone with one specific misconception claim? Keep the same skeleton, grain, and register.
3. Each distractor is a believable error that the learner might really make. An option a cold reader rejects on sight is wasted.
4. Do not bold a term in only one option.

If you can tell the right option cold without knowing the material, write the set again. Do not patch it.

## Visuals

When an idea is a structure, a flow, or a dependency, write a mermaid block inline. When an idea is spatial or geometric, load the `visualize` skill.

## Close

When the goal lands, or the learner stops:

1. Revisit every point you flagged as uncertain.
2. Load the `distill` skill and write the session into the knowledge graph.
