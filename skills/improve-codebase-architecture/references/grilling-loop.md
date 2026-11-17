# Grilling loop — local fallback

Adapted from Matt Pocock, `mattpocock/skills`, MIT; Git tree `5863806dd4e15c63174bee4e7515a4256792ecfa`, `skills/productivity/grilling/SKILL.md`. See [LICENSE](../LICENSE). This reference replaces an unavailable dependency; do not claim that the standalone skill was invoked.

## Decision tree and frontier

Begin only after the user selects an architecture candidate. Map constraints, dependency strategies, module shape, seam placement and surviving tests as a **design tree**. Each decision branches into decisions depending on it.

The **frontier** contains only questions whose prerequisites are settled. Work in finite rounds: number the current frontier questions, give a specific recommended answer for each, then wait. Phrase questions so “yes” accepts the recommendation. A dependent question belongs in a later round, not beside its unresolved prerequisite. Group a large frontier into readable batches without dropping branches; do not ask an unbounded stream of speculative questions.

For each question use:

- **Q1 — Decision title:** the concrete decision, relevant constraints and real alternatives.
- **Recommendation:** the proposed answer and short reason; “yes” accepts it.

After each answer, record settled decisions, update branches, recompute the frontier, and ask the newly unblocked questions. Surface conflicts explicitly instead of silently choosing for the user.

## Facts are the agent's work; decisions are the user's

Check repository code, configuration, tests and existing ADRs yourself. If bounded read-only subagents are available, delegate independent fact-finding; otherwise inspect sequentially. Never invent successful delegation or a fresh context window. An outstanding fact-finding task is an unsettled prerequisite: only its dependent questions wait, while other ready questions may proceed. Do not ask the user for a fact that can be verified locally.

Ask the user about requirements, acceptable trade-offs or authorization that cannot be inferred. Check claims against code and distinguish observed behavior from requested behavior. Read [domain-modeling-core.md](domain-modeling-core.md) when terminology crystallizes and [codebase-design-core.md](codebase-design-core.md) when comparing designs.

## Completion

The loop ends when the frontier is empty, every relevant branch has been visited, and no decision is silently assumed. Summarize the agreed design and ask the user to confirm shared understanding. **Do not implement the design before confirmation.** ADR recording also requires its own confirmation; temporary rejection alone is not an ADR-worthy decision.
