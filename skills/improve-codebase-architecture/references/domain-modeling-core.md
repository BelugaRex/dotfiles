# Domain modeling core — local fallback

Adapted from Matt Pocock, `mattpocock/skills`, MIT; Git tree `5863806dd4e15c63174bee4e7515a4256792ecfa`, `skills/engineering/domain-modeling/{SKILL.md,GLOSSARY-FORMAT.md,ADR-FORMAT.md}`. See [LICENSE](../LICENSE). This is a local reference, not a new independently registered skill.

## Follow the project's language

Read existing terminology and nearby ADRs first. Respect the project's established glossary location/format, including a legacy `CONTEXT.md` if it actually serves that purpose; do not rename or migrate files merely because the upstream default is now `GLOSSARY.md`.

If `GLOSSARY-MAP.md` exists, follow its context links and relationships. Otherwise use a root glossary for a single-context project. Create a default `GLOSSARY.md` **lazily**, only when the first project-specific term has been resolved. Add a multi-context map only when real multiple contexts require one, not as boilerplate. Infer the relevant context from code; ask when genuinely ambiguous.

## Actively sharpen the model

- Challenge terms conflicting with established definitions and ask which meaning is intended.
- Resolve overloaded language into precise canonical concepts; use concrete edge cases to test their relationships.
- Cross-reference claims against code. Surface contradictions as observed behavior versus intended model, not an assumed decision.
- Once a term is agreed, update the appropriate glossary inline rather than batching unresolved notes. Reading the glossary alone is not permission to change its model.

## Glossary format

Start with a context-name heading and one or two sentences explaining the context. Under `## Language`, each entry has a bold canonical term, a one- or two-sentence definition of **what it is**, and an `_Avoid_` list of competing names. For example: **Invoice**: A request for payment sent to a customer after delivery. _Avoid_: Bill, payment request.

Pick one preferred term rather than listing synonyms as equivalent. Include only concepts specific to the project's domain, not generic timeouts, error types or utility patterns. Group under subheadings when natural clusters emerge. Keep implementation details, decisions, scratch notes and specifications out of the glossary.

A context map, when needed, lists each context with a relative link to its glossary and purpose, then directional relationships such as events consumed or shared domain identifiers. Each context may have its own `docs/adr/`; system-wide ADRs stay at the root convention. Preserve existing project conventions.

## ADR threshold and approval

Offer an ADR only when **all three** are true:

1. The decision is hard to reverse at meaningful cost.
2. It would surprise a future reader without the missing context.
3. There were real alternatives and a genuine trade-off.

Good candidates include expensive lock-in, non-obvious integration choices, deliberate deviations, invisible external constraints, or a load-bearing rejection reason future reviewers would otherwise re-propose. Skip temporary priorities, obvious choices and easily reversed decisions.

**Ask before writing an ADR.** A suitable offer is: “Want me to record this as an ADR so future architecture reviews don't re-suggest it?” Do not interpret rejecting a candidate as consent to write. Do not silently replace or re-litigate existing ADRs; flag real friction and seek agreement.

## ADR format and sequence

Use the existing convention or default to `docs/adr/NNNN-slug.md`; create the directory only for an approved first ADR. Inspect existing numbers and increment the highest by one, preserving sequential four-digit numbering.

An ADR normally contains only a short decision-title heading and **one paragraph of 1–3 sentences**: context, decision and why. Optional status (`proposed`, `accepted`, `deprecated`, `superseded by ADR-NNNN`), considered options or consequences belong only when genuinely informative. Do not fill a large template merely for completeness. Preserve relevant alternatives and rationale, not every conversational turn.
