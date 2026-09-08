---
name: cavecrew
description: >
  Decision guide for two reusable user-level VS Code agents: read-only
  `cavecrew` (`locate|analyze|review`) and bounded-write
  `cavecrew-builder` (`build`)
  with direct search in caller-declared context. Reuse instances, allow only
  builder-to-cavecrew nesting, and keep integration in the main thread.
  Trigger: "delegate to subagent", "use cavecrew", "parallel investigation",
  "parallel review", "parallel edit".
---

Cavecrew uses exactly two user-level templates, split by permission boundary:

- `~/.copilot/agents/cavecrew.agent.md`: peer read-only finder/analyst/reviewer with `read + search`.
- `~/.copilot/agents/cavecrew-builder.agent.md`: bounded writer with `read + search + edit + agent`, direct read/search in declared `context_paths`, and `agents: ['cavecrew']`.

When no model override is passed, these subagents use the current model: treat them as peer clones, not junior workers. Scale by launching more instances, not by creating role aliases. The main thread owns file allocation, integration, conflict handling, and validation because it has the complete ownership map, not because it is assumed smarter.

## Why exactly two templates

- `locate` and `review` need the same least-privilege tools: `read` + `search`.
- `analyze` uses the same tools but applies full peer-level reasoning to a bounded technical question.
- Write permission is a real security boundary, so it remains isolated in `cavecrew-builder`.
- A separate finder is unnecessary because builder reuses `cavecrew` through a one-name allowlist.
- Multiple instances provide parallelism without multiplying templates.

## When to use cavecrew

| Task | Use |
|---|---|
| Locate definitions, callers, uses, tests | `cavecrew`, `mode: locate` |
| Analyze a bounded architecture or implementation question | `cavecrew`, `mode: analyze` |
| Review supplied diff or bounded changed lines | `cavecrew`, `mode: review` |
| Implement a 1–4 file slice with no ownership overlap; search declared context directly | `cavecrew-builder`, `mode: build` |
| Broad open-ended exploration without a stable scope | `Explore` |
| Surgical edit, scope obvious | Main thread |
| Same-file edits, 3+ files, or cross-cutting refactor | Main thread |
| Deep review with rationale and alternatives | `Explore` or main thread |
| One-line answer you already know | Main thread, no subagent |

Rule: use `cavecrew` whenever a bounded read-only peer can work independently, and builder when file ownership is explicit and disjoint. Use `Explore` only when the scope itself still needs discovery or long-form prose is the deliverable.

## `cavecrew` invocation contract

- Give `mode`, bounded scope, exact question, and expected evidence in the first prompt. Use `analyze` for peer-level design or tradeoff reasoning.
- Subagents are stateless; do not expect follow-up clarification.
- For parallel work, send 2–3 disjoint scopes in one batch and aggregate in main thread.
- Never ask `cavecrew` to edit, execute commands, browse, or inspect secrets.

## `cavecrew-builder` invocation contract

- Give `mode: build`, `owned_files` with 1–4 exact workspace-relative files, `context_paths` with 0–12 explicit read/search files or directories, one change goal, and file-checkable acceptance criteria.
- Run builders in parallel only when every `owned_files` set is mutually exclusive.
- Let the builder search `owned_files` plus `context_paths` directly; use nested `cavecrew mode: locate|analyze|review` only for parallel independent evidence or a second perspective, and keep nested scope inside those declared paths.
- Nested delegation requires `chat.subagents.allowInvocationsFromSubagents: true`; VS Code defaults it to `false`.
- If finder use is mandatory but unavailable, require `blocked` and zero edits. Never allow `*`, self-calls, or builder-to-builder delegation.
- Never ask builder to run commands, browse, inspect secrets, delete/rename without explicit scope, or claim tests passed. Broad `execute` remains withheld because prompt text cannot safely sandbox a shell.
- Main thread must inspect every diff and run all validation.

## `mode: locate` output

```
matches:
- path:line — `symbol` — short fact
totals: N matches in M files.
```

Or `No match.` Paths are workspace-relative; lines are 1-based.

## `mode: review` output

```
path:line: <emoji> <severity>: <problem>. <fix>.
totals: N🔴 N🟡 N🔵 N❓
```

Or `No issues.` Review requires a unified diff or files + line ranges + expected behavior.

## `mode: analyze` output

```
evidence:
- path:line — `symbol` — verified fact
conclusion: concise answer or recommended approach
risks:
- concise residual risk
```

## Chaining patterns

**Locate → fix → review**:
1. `cavecrew` with `mode: locate` returns sites.
2. Main thread or one bounded builder edits the owned files and searches only declared context.
3. `cavecrew` with `mode: review` audits supplied diff or changed lines.
4. Main thread integrates and validates.

**Parallel scout** (when investigation is broad):
Spawn 2–3 `cavecrew` `mode: locate|analyze` calls with disjoint angles such as definitions, callers, tests, and design risks. Aggregate in main thread.

**Parallel review**:
Spawn multiple `mode: review` calls only when each receives a complete, non-overlapping review scope.

**Parallel build**:
Spawn 2–3 `cavecrew-builder` calls only after assigning mutually exclusive 1–4-file ownership. A builder may call `cavecrew` for bounded cross-file evidence; it may not delegate edits.

## Iteration gate

Do not add a third template because one task feels awkward. Add one only when:

1. The required tool permissions cannot safely fit the read-only `cavecrew` boundary, and
2. They also cannot safely fit the bounded `cavecrew-builder` boundary,
3. The same delegation pattern has appeared at least three times, and
4. A stable input/output contract can be written and verified.

## What NOT to do

- Don't omit `mode` or scope and expect the agent to guess.
- Don't call `mode: review` without a diff or bounded changed lines.
- Don't ask `cavecrew` for edits or either agent for tests, terminal work, web access, or secrets; the main thread owns execution.
- Don't assign overlapping files to parallel builders.
- Don't create finder, investigator, reviewer, or domain-specific builder aliases; reuse the two templates.
- Don't configure `agents: '*'`, self-recursion, or builder-to-builder calls.
- Don't expect prose. Cavecrew output is structured, sometimes terse to the point of cryptic. If a human will read it directly, paraphrase.

## Auto-clarity

Use normal complete language for security warnings, sensitive-data boundaries, irreversible actions, and any ambiguity where compression could mislead.
