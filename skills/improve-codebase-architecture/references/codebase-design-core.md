# Codebase design core — local fallback

Adapted from Matt Pocock, `mattpocock/skills`, MIT; Git tree `5863806dd4e15c63174bee4e7515a4256792ecfa`, `skills/engineering/codebase-design/{SKILL.md,DEEPENING.md,DESIGN-IT-TWICE.md}`. See [LICENSE](../LICENSE). This is a reference, not a separately installed skill.

## Vocabulary

Use these terms consistently in reports and discussions; use the project's glossary for domain names.

- **Module**: anything with an interface and an implementation: function, class, package or tier-spanning slice. Not a synonym for a deployment unit.
- **Interface**: everything a caller must know: types, invariants, ordering, errors, configuration and performance constraints, not just method signatures.
- **Implementation**: the code hidden behind the interface; distinct from an adapter's role at a seam.
- **Depth**: behavior a caller/test can exercise per unit of interface learned. **Deep** means much behavior behind a small interface; **shallow** means the interface is nearly as complex as the implementation. Not a line-count ratio.
- **Seam**: a location at which behavior can vary without editing that location; where the interface lives.
- **Adapter**: a concrete thing satisfying an interface at a seam; describes a role, not implementation size.
- **Leverage**: capability callers gain per unit of interface; one implementation pays back across many callers/tests.
- **Locality**: change, bugs, knowledge and verification concentrate in one place; fix once, fixed everywhere.

Avoid substituting component/service/unit for module, API/signature for the whole interface, or boundary for seam. A module presents one coherent interface; it can contain private internal seams as well as its external seam.

## Diagnose before designing

- Prefer recently changed, painful code; do not invent abstractions for hypothetical future needs.
- **Deletion test**: imagine deleting the module. If complexity vanishes, it was pass-through. If complexity reappears across callers, it was earning its keep. Distinguish eliminating complexity from merely moving it.
- **The interface is the test surface**: callers and tests cross the same seam. Tests that must reach past it suggest the module is the wrong shape.
- **One adapter means a hypothetical seam; two adapters mean a real one.** Do not introduce a port unless real production/test variation justifies it.
- Increase leverage by simplifying methods, parameters and caller obligations, not by inflating implementation. Accept dependencies rather than constructing them internally; return observable results where appropriate. Keep private testing seams out of the external interface.

## Dependency categories and test strategies

Use these exact badge labels in the HTML report. Classify the candidate's relevant dependencies; a candidate may span categories.

| Label | Meaning | Strategy |
|-------|---------|----------|
| `in-process` | Pure computation/in-memory state, no I/O | Consolidate behavior and test observable outcomes through the interface; no adapter required. |
| `local-substitutable` | A real local stand-in exists, e.g. PGLite or in-memory filesystem | Test the deep module with that stand-in. Keep this seam internal; do not expose an external port solely for tests. If no suitable stand-in exists, do not pretend this category is satisfied. |
| `ports & adapters` | Remote but owned dependency | Deep module owns logic; define a port at the seam and inject HTTP/gRPC/queue production and in-memory test adapters. Explain the two real variations. |
| `mock` | True external dependency outside your control | Inject an external port; tests supply a mock adapter and verify observable behavior, not internal calls indiscriminately. |

**Replace, don't layer**: once behavior-equivalent tests exist at the deepened interface, remove redundant shallow-module tests rather than retaining two implementation-coupled suites. Preserve distinct coverage until its replacement is verified; do not delete tests as part of merely producing a report. New tests assert outcomes and survive internal refactors. Explain both leverage for callers and locality for maintainers.

## Design it twice — only after candidate selection

1. Frame constraints, domain terminology, dependency categories and what would sit behind the seam. An illustrative sketch clarifies constraints; it is not an approved interface.
2. If independent read-only subagents are actually available, give at least three bounded technical briefs with different goals: minimize the interface (1–3 entry points); maximize justified flexibility; optimize the common caller. A fourth may explore ports/adapters. Give each the same evidence, vocabulary and constraints. Do not give them edits or overlapping implementation ownership.
3. If independent agents or parallel execution are unavailable, develop the same distinct alternatives sequentially and label them **sequential alternatives**, not fresh-context or independent agent findings. Never claim a tool ran when it did not.
4. For each alternative show interface/types and caller obligations, usage, hidden implementation, dependency/adapters strategy, trade-offs and where leverage is thin.
5. Present alternatives then compare depth, locality, seam placement, testability and migration risk. Recommend the strongest or a justified hybrid. Reach explicit agreement before implementation; a design exercise is not authorization to refactor.
