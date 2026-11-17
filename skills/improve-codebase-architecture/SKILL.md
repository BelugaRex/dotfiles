---
name: improve-codebase-architecture
description: Scan a codebase for deepening opportunities, present them as a visual HTML report, then grill through whichever one you pick.
disable-model-invocation: true
---

# Improve Codebase Architecture

Surface architectural friction and propose **deepening opportunities**: refactors that turn shallow modules into deep ones. The aim is testability and AI-navigability.

This command is _informed_ by the project's domain model and built on a shared design vocabulary:

- If `codebase-design` is actually available in this session, invoke it; otherwise read [references/codebase-design-core.md](references/codebase-design-core.md). This supplies **module**, **interface**, **depth**, **seam**, **adapter**, **leverage**, **locality**, the deletion test, interface test surfaces and justified adapters. Use that architecture vocabulary consistently; never claim a missing or failed skill invocation succeeded.
- The project's domain glossary (default `GLOSSARY.md`) gives names to good seams; ADRs in `docs/adr/` record decisions this command should not re-litigate. Respect existing glossary conventions; do not migrate `CONTEXT.md` just to adopt the upstream default name.

The three references in this directory are complete local fallbacks, not three new skill entries. Use native dependencies only when the host actually exposes them; read the fallback after any unavailable/failed invocation.

## Process

### 1. Explore

**Scope before you scan: YAGNI.** Deepening a module pays off by making future changes to it easier, so put extra weight on the parts of the codebase that have recently changed. Decide *where* to look before you look:

- If the user named a direction (a module, a subsystem, a pain point), take it, and skip the inference below.
- Otherwise, walk back a good stretch of the commit history (`git log --oneline`) to find the codebase's hot spots, the files and areas that keep coming up, and let those paths pull your attention first. If the changes are scattered with no clear hot spot, widen the net.

Read the project's domain glossary (`GLOSSARY.md` by default, or the established location/context map) and any ADRs in the area you're touching first.

Then, if a read-only subagent is actually available, assign bounded code exploration to an independent context. Otherwise inspect sequentially yourself and label it as such; never fabricate fresh-context findings. Don't follow rigid heuristics; explore organically and note where you experience friction:

- Where does understanding one concept require bouncing between many small modules?
- Where are modules **shallow**, with an interface nearly as complex as the implementation?
- Where have pure functions been extracted just for testability, but the real bugs hide in how they're called (no **locality**)?
- Where do tightly-coupled modules leak across their seams?
- Which parts of the codebase are untested, or hard to test through their current interface?

Apply the **deletion test** to anything you suspect is shallow: would deleting it concentrate complexity, or just move it? A "yes, concentrates" is the signal you want.

### 2. Present candidates as an HTML report

Write a self-contained HTML file to the OS temp directory so nothing lands in the repo. Resolve the temp dir from `$TMPDIR`, falling back to `/tmp` (or `%TEMP%` on Windows), and write to `<tmpdir>/architecture-review-<timestamp>.html` so each run gets a fresh file. Open it for the user (`xdg-open <path>` on Linux, `open <path>` on macOS, `start <path>` on Windows) and tell them the absolute path.

The report uses **Tailwind via CDN** for layout and styling, and **Mermaid via CDN** for diagrams where a graph/flow/sequence reliably communicates the structure. Mix Mermaid with hand-crafted CSS/SVG visuals: use Mermaid when relationships are graph-shaped (call graphs, dependencies, sequences), and hand-built divs/SVG when you want something more editorial (mass diagrams, cross-sections, collapse animations). Each candidate gets a **before/after visualisation**. Be visual.

For each candidate, render a card with:

- **Files**: which files/modules are involved
- **Problem**: why the current architecture is causing friction
- **Solution**: plain English description of what would change
- **Benefits**: explained in terms of locality and leverage, and how tests would improve
- **Before / After diagram**: side-by-side, custom-drawn, illustrating the shallowness and the deepening
- **Recommendation strength**: one of `Strong`, `Worth exploring`, `Speculative`, rendered as a badge

End the report with a **Top recommendation** section: which candidate you'd tackle first and why.

**Use the project's glossary for the domain, and the loaded `codebase-design` skill or [local core](references/codebase-design-core.md) for architecture.** If the domain glossary defines "Order," talk about "the Order intake module," not "the FooBarHandler," and not "the Order service."

**ADR conflicts**: if a candidate contradicts an existing ADR, only surface it when the friction is real enough to warrant revisiting the ADR. Mark it clearly in the card (e.g. a warning callout: _"contradicts ADR-0007, but worth reopening because…"_). Don't list every theoretical refactor an ADR forbids.

See [HTML-REPORT.md](HTML-REPORT.md) for the full HTML scaffold, diagram patterns, and styling guidance.

Do NOT propose interfaces yet. After the file is written, ask the user: "Which of these would you like to explore?"

### 3. Grilling loop

Once the user picks a candidate, invoke `grilling` only if actually available; otherwise read [references/grilling-loop.md](references/grilling-loop.md). Walk the decision tree in rounds: constraints, dependencies, module shape, what sits behind the seam, and surviving tests. Investigate facts yourself; wait for the user's decisions. Do not implement before shared understanding is confirmed.

As domain decisions crystallize, invoke `domain-modeling` only if available; otherwise read [references/domain-modeling-core.md](references/domain-modeling-core.md). Apply it inline:

- **Naming a deepened module after a new domain concept?** Resolve its meaning and add it to the existing glossary, creating `GLOSSARY.md` lazily only if no glossary convention exists.
- **Sharpening a fuzzy term during the conversation?** Update the appropriate glossary once agreed; keep implementation decisions out of it.
- **User rejects the candidate with a load-bearing reason?** Offer an ADR only if the decision is hard to reverse, surprising without context, and a real trade-off: _"Want me to record this as an ADR so future architecture reviews don't re-suggest it?"_ Write only after confirmation; skip ephemeral or self-evident reasons.
- **Want alternative interfaces?** Invoke `codebase-design` if available and use design-it-twice; otherwise follow that section of [references/codebase-design-core.md](references/codebase-design-core.md). Use genuinely independent read-only agents when possible, or honestly labeled sequential alternatives. Present a recommendation, then seek agreement before implementation.
