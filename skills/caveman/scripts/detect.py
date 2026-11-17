#!/usr/bin/env python3
"""Detect whether a file is natural language (compressible) or code/config (skip)."""

import json
import re
from pathlib import Path

# Extensions that are natural language and compressible. `.mdc` is a prose rule
# format; TeX/Typst remain code by default in this Copilot adapter.
COMPRESSIBLE_EXTENSIONS = {".md", ".mdc", ".txt", ".markdown", ".rst"}

# Extensions that are code/config and should be skipped
SKIP_EXTENSIONS = {
    ".py", ".js", ".ts", ".tsx", ".jsx", ".json", ".yaml", ".yml",
    ".toml", ".env", ".lock", ".css", ".scss", ".html", ".xml",
    ".sql", ".sh", ".bash", ".zsh", ".go", ".rs", ".java", ".c",
    ".cpp", ".h", ".hpp", ".rb", ".php", ".swift", ".kt", ".lua",
    ".dockerfile", ".makefile", ".csv", ".ini", ".cfg",
    ".typ", ".typst", ".tex",
}

# Well-known build/config files that carry no (or a misleading) extension —
# `Dockerfile` has no suffix so `.dockerfile` above never matches it, and
# `CMakeLists.txt` would ride the compressible `.txt` rule. Checked by
# basename before any extension rule.
KNOWN_CODE_FILENAMES = {
    "dockerfile", "containerfile", "makefile", "gnumakefile", "jenkinsfile",
    "vagrantfile", "rakefile", "gemfile", "justfile", "procfile", "brewfile",
    "earthfile", "fastfile", "podfile",
    "cmakelists.txt",
}

# Dotfiles whose entire name sits where pathlib expects a suffix, so
# `Path(".cursorrules").suffix` is `""` just as it is for `.env`. These are the
# prose ones — Cursor's and its imitators' legacy single-file rule formats —
# and the only bare dotfiles that may be compressed. Everything else is
# treated as config; see the dotfile branch in `detect_file_type`.
PROSE_DOTFILES = {
    ".cursorrules", ".windsurfrules", ".clinerules", ".aiderrules",
    ".goosehints", ".augmentrules",
}

# Extensions on SKIP_EXTENSIONS that are data/config rather than program text.
CONFIG_EXTENSIONS = {".json", ".yaml", ".yml", ".toml", ".ini", ".cfg", ".env"}
SENSITIVE_NAME_RE = re.compile(
    r"(?i)^(?:credentials?(?:[._-].*)?|secrets?(?:[._-].*)?|passwords?(?:[._-].*)?|"
    r"\.env(?:\..*)?|\.netrc|\.npmrc|\.pypirc|\.pgpass|\.s3cfg|\.boto|"
    r"id_(?:rsa|dsa|ecdsa|ed25519)(?:\.pub)?|authorized_keys|known_hosts|"
    r".*\.(?:pem|key|p12|pfx|crt|cer|jks|keystore|asc|gpg))$"
)
SENSITIVE_PATH_PARTS = {".ssh", ".aws", ".gnupg", ".kube", ".docker"}
SENSITIVE_NAME_TOKENS = ("secret", "credential", "password", "passwd", "apikey", "accesskey", "token", "privatekey")

# Patterns that indicate a line is code
CODE_PATTERNS = [
    re.compile(r"^\s*(import |from .+ import |require\(|const |let |var )"),
    re.compile(r"^\s*(def |class |function |async function |export )"),
    re.compile(r"^\s*(if\s*\(|for\s*\(|while\s*\(|switch\s*\(|try\s*\{)"),
    re.compile(r"^\s*[\}\]\);]+\s*$"),  # closing braces/brackets
    re.compile(r"^\s*@\w+"),  # decorators/annotations
    re.compile(r'^\s*"[^"]+"\s*:\s*'),  # JSON-like key-value
    re.compile(r"^\s*\w+\s*=\s*[{\[\(\"']"),  # assignment with literal
]


def _is_code_line(line: str) -> bool:
    """Check if a line looks like code."""
    return any(p.match(line) for p in CODE_PATTERNS)


def _is_json_content(text: str) -> bool:
    """Check if content is valid JSON."""
    try:
        json.loads(text)
        return True
    except (json.JSONDecodeError, ValueError):
        return False


def _is_yaml_content(lines: list[str]) -> bool:
    """Heuristic: check if content looks like YAML."""
    yaml_indicators = 0
    for line in lines[:30]:
        stripped = line.strip()
        if stripped.startswith("---"):
            yaml_indicators += 1
        elif re.match(r"^\w[\w\s]*:\s", stripped):
            yaml_indicators += 1
        elif stripped.startswith("- ") and ":" in stripped:
            yaml_indicators += 1
    # If most non-empty lines look like YAML
    non_empty = sum(1 for l in lines[:30] if l.strip())
    return non_empty > 0 and yaml_indicators / non_empty > 0.6


def detect_file_type(filepath: Path) -> str:
    """Classify a file as 'natural_language', 'code', 'config', or 'unknown'.

    Returns:
        One of: 'natural_language', 'code', 'config', 'unknown'
    """
    ext = filepath.suffix.lower()
    name = filepath.name.lower()

    # Refuse sensitive names and path components before reading any contents.
    if SENSITIVE_NAME_RE.match(name):
        return "config"
    raw_parts = {part.lower() for part in filepath.parts}
    normalized_parts = {re.sub(r"[_\-\s.]", "", part) for part in raw_parts}
    if raw_parts & SENSITIVE_PATH_PARTS or any(
        token in part for part in normalized_parts for token in SENSITIVE_NAME_TOKENS
    ):
        return "config"
    if filepath.is_symlink() or any(parent.is_symlink() for parent in filepath.parents):
        return "unknown"  # Resolve and authorize the real target separately.

    # Known code filenames win over any extension rule
    if name in KNOWN_CODE_FILENAMES:
        return "code"

    if name.startswith(".") and name not in PROSE_DOTFILES:
        return "config"
    if not ext and name in PROSE_DOTFILES:
        return "natural_language"

    # Extension-based classification
    if ext in COMPRESSIBLE_EXTENSIONS:
        return "natural_language"
    if ext in SKIP_EXTENSIONS:
        return "code" if ext not in CONFIG_EXTENSIONS else "config"

    # Extensionless files (like CLAUDE.md, TODO) — check content
    if not ext:
        try:
            if filepath.stat().st_size > 500_000:
                return "unknown"
            text = filepath.read_bytes().decode("utf-8")
        except (OSError, UnicodeError):
            return "unknown"

        lines = text.splitlines()[:50]

        # Shebang means executable script, never prose
        if text.startswith("#!"):
            return "code"

        if _is_json_content(text[:10000]):
            return "config"
        if _is_yaml_content(lines):
            return "config"

        code_lines = sum(1 for l in lines if l.strip() and _is_code_line(l))
        non_empty = sum(1 for l in lines if l.strip())
        if non_empty > 0 and code_lines / non_empty > 0.4:
            return "code"

        return "natural_language"

    return "unknown"


def should_compress(filepath: Path) -> bool:
    """Conservative eligibility, not authorization or proof of valid UTF-8."""
    if filepath.is_symlink() or not filepath.is_file():
        return False
    if filepath.stat().st_size > 500_000:
        return False
    if filepath.name.lower().endswith(".original.md"):
        return False
    if detect_file_type(filepath) != "natural_language":
        return False
    return not is_generated(filepath)


GENERATED_MARKER_RE = re.compile(r"\bgenerated by\b|@generated\b", re.IGNORECASE)


def is_generated(filepath: Path) -> bool:
    """True when line 1 says the file is generated. Its generator rewrites it,
    so compressing it only spends tokens on text about to be replaced (#1350)."""
    try:
        with filepath.open(encoding="utf-8", errors="replace") as handle:
            first_line = handle.readline(512)
    except OSError:
        return False
    return bool(GENERATED_MARKER_RE.search(first_line))


if __name__ == "__main__":
    import sys

    if len(sys.argv) < 2:
        print("Usage: python detect.py <file1> [file2] ...")
        sys.exit(1)

    for path_str in sys.argv[1:]:
        p = Path(path_str).absolute()
        file_type = detect_file_type(p)
        compress = should_compress(p)
        print(f"  {p.name:30s} type={file_type:20s} compress={compress}")
