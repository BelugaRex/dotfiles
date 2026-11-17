# Copilot selective refresh — 2026-11-17

Source: `JuliusBrussee/caveman`, v4.1.0, commit `9b243662ff98d392bc0a95b865a554583d71be75`, tree `e9ca72f48c334c799d86941a45eafb814ba5cbbf`.

`detect.py` and `validate.py` are modified from the pinned upstream versions. Copyright (c) 2026 Julius Brussee; the upstream MIT permission notice is preserved in `LICENSE-MIT`.

- Preserved the single entry, task-scoped style restoration, intensity/Wenyan modes and natural-language routing.
- Ported `.mdc`, known build-file, dotfile/generated-file detection; added pre-read sensitive path/name rejection, TeX/Typst skip, size cap and conservative symlink handling.
- Ported document-ordered fenced/indented blocks, variable-run inline-code pairing, path loss and heading checks. Added strict decoding, raw newline preservation, unclosed-fence failure, full inline-span multiplicity and nonzero failure exits.
- Kept all existing `check_candidate.py` guards and warnings-as-failure; added body first-line anchor, new thematic-break/body-mapping rejection and symlink rejection.
- Preserved comments and clarity requirements in style guidance.
- Did not install upstream `compress.py`, provider SDKs, CLI model calls, hooks or telemetry. Current Copilot generates candidates; helper scripts only read local inputs.

Original snapshot, pinned sources/hash inventory, synthetic tests and rollback instructions
are retained in private local maintenance records and are not distributed in this repository.
The repository contains only the reviewed skill snapshot and its public provenance.

These are conservative mechanical checks, not a complete Markdown parser, credential scanner, semantic equivalence proof or independent model evaluation. Complex valid Markdown may be rejected. Authorization and semantic review are still required.
