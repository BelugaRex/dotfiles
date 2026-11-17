# Local Copilot adapter

- Upstream: OthmanAdi/planning-with-files, canonical `skills/planning-with-files/`.
- Git **tree** SHA: `51bf62def62d1cb317d37936929b4ef97cf862c3` (content tree, not a commit identifier).
- Upstream metadata version: **3.28.2**; local adapter revision: **copilot.1**. At the audit time the latest published release was v3.28.1; this package follows the pinned default-branch snapshot, not that release tag.
- License: [MIT](LICENSE), retained from the repository.

## Delta

The 34 canonical upstream files are installed. Only `SKILL.md` is adapted; every script, template, eval and upstream reference is byte-identical to the pinned source. Added files: this provenance note and `LICENSE`.

The entry preserves persistent three-file planning, native phase/status validation, explicit Next Step, one plan owner, error tracking, task selection, no-history-by-default recovery, and untrusted-data boundaries. It removes Claude-specific frontmatter hooks, environment-path assumptions, plugin/slash-command setup and unsupported runtime promises.

The adapter binds project root/plan ID per helper call and refuses wrong/ambiguous plan recovery. Legacy root plans use explicit paths. The initializer creates files in its working directory, so callers must verify that directory and capture a named initializer's printed plan ID; exports in a subprocess do not pin Copilot itself.

No lifecycle configuration was installed. No automatic injection, stop gate, pre-compaction callback, background loop, scheduler, or automatic session-store access is provided. Host-integration helpers and other-host templates are retained **dormant**, not deployed. History metadata/replay requires explicit user request; a local SHA baseline is not author authentication, user approval, write protection or proof of task completion.

## Maintenance

For a future upgrade, compare the canonical source inventory and hashes, synchronize the entire runtime package, then reapply this small entry-point delta. Do not replace the adapter with raw upstream hooks merely to advance a version number. Validate syntax and task-isolated behavioral fixtures before claiming success. Start a fresh Copilot session to refresh discovered skill metadata; actual automatic invocation remains host-dependent.
