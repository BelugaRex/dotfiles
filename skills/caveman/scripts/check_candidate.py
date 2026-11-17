#!/usr/bin/env python3
"""Read-only, conservative structure checks for a Copilot-generated candidate."""
import argparse
from collections import Counter
from pathlib import Path
import re

from validate import extract_fenced_spans, validate

MAX_BYTES = 500_000
FRONTMATTER = re.compile(r'\A\ufeff?---\r?\n.*?\r?\n---(?:\r?\n|\Z)', re.DOTALL)
LIST_MARKER = re.compile(r'^(\s*(?:[-*+]|\d+[.)])\s+)', re.MULTILINE)
NUMBERS = re.compile(r'\d+(?:[._:-]\d+)*%?')
LINK_TARGET = re.compile(r'\]\(([^\n]*)\)')
REFERENCE_LINK = re.compile(r'^ {0,3}\[[^\]]+\]:.*$', re.MULTILINE)
HTML_COMMENT = re.compile(r'<!--[\s\S]*?-->')


def frontmatter(text):
    match = FRONTMATTER.match(text)
    return match.group(0) if match else ''


def indented_lines(text):
    # Conservative: four-space prose is treated as protected too.
    return [line for line in text.splitlines(keepends=True)
            if line.startswith(('    ', '\t'))]


def table_shape(text):
    return [line.count('|') for line in text.splitlines() if '|' in line]


def masked_body(text):
    """Inspect prose framing only, excluding frontmatter and protected code."""
    text = text[len(frontmatter(text)):].lstrip('\ufeff')
    lines = text.split('\n')
    fenced = {index for span in extract_fenced_spans(lines) for index in span}
    return ['' if index in fenced or line.startswith(('    ', '\t')) else line
            for index, line in enumerate(lines)]


def body_mapping_count(lines):
    delimiters = [index for index, line in enumerate(lines) if line.strip() == '---']
    key = re.compile(r'^[A-Za-z_][A-Za-z0-9_.-]*:(?:\s.*)?$')
    count = 0
    for start, end in zip(delimiters, delimiters[1:]):
        content = [line for line in lines[start + 1:end] if line.strip()]
        if content and key.match(content[0]) and all(
                key.match(line) or line.startswith((' ', '\t', '- ')) for line in content):
            count += 1
    return count


def framing_issues(before, after):
    try:
        original, candidate = masked_body(before), masked_body(after)
    except ValueError as error:
        return [str(error)]
    issues = []
    anchor = lambda text: next((line for line in text[len(frontmatter(text)):].lstrip('\ufeff').splitlines()
                                if line.strip()), '')
    if anchor(before) != anchor(after):
        issues.append('First nonblank prose line changed; preserve the body anchor')
    thematic = re.compile(r'^ {0,3}(?:(?:\* *){3,}|(?:- *){3,}|(?:_ *){3,})\r?$')
    if sum(bool(thematic.fullmatch(line)) for line in candidate) > sum(
            bool(thematic.fullmatch(line)) for line in original):
        issues.append('Added thematic break in body')
    if body_mapping_count(candidate) > body_mapping_count(original):
        issues.append('Added frontmatter-like mapping in body')
    return issues


def check_candidate(original, candidate):
    """Return issues without modifying either file or claiming semantic proof."""
    original, candidate = Path(original), Path(candidate)
    if original.resolve() == candidate.resolve():
        return ['Original and candidate must be different files']
    for path in (original, candidate):
        if path.is_symlink() or any(parent.is_symlink() for parent in path.parents):
            return [f'Symlink path requires separate target authorization: {path}']
        if not path.is_file():
            return [f'Not a file: {path}']
        if path.stat().st_size > MAX_BYTES:
            return [f'File exceeds {MAX_BYTES} bytes: {path}']
    try:
        original_bytes = original.read_bytes()
        candidate_bytes = candidate.read_bytes()
        before = original_bytes.decode('utf-8')
        after = candidate_bytes.decode('utf-8')
    except UnicodeError:
        return ['Both files must be valid UTF-8; no lossy decoding allowed']

    issues = []
    if not before.strip() or not after.strip():
        issues.append('Empty original or candidate')
    if len(after) >= len(before):
        issues.append('Candidate is not shorter in characters (not a token metric)')
    if frontmatter(before) != frontmatter(after):
        issues.append('Frontmatter changed')
    issues.extend(framing_issues(before, after))
    if original_bytes.startswith(b'\xef\xbb\xbf') != candidate_bytes.startswith(b'\xef\xbb\xbf'):
        issues.append('UTF-8 BOM changed')
    def newline_styles(data):
        return set(re.findall(rb'\r\n|\r|\n', data))
    if newline_styles(original_bytes) != newline_styles(candidate_bytes):
        issues.append('Newline style changed')
    if len(newline_styles(original_bytes)) > 1 or len(newline_styles(candidate_bytes)) > 1:
        issues.append('Mixed newline styles require manual handling')
    if before.endswith('\n') != after.endswith('\n'):
        issues.append('Trailing newline changed')
    if indented_lines(before) != indented_lines(after):
        issues.append('Indented code or protected indentation changed')
    if LIST_MARKER.findall(before) != LIST_MARKER.findall(after):
        issues.append('List markers, numbering or hierarchy changed')
    if table_shape(before) != table_shape(after):
        issues.append('Table structure changed')
    if Counter(NUMBERS.findall(before)) != Counter(NUMBERS.findall(after)):
        issues.append('Numbers, versions or dates changed')
    if LINK_TARGET.findall(before) != LINK_TARGET.findall(after):
        issues.append('Markdown link targets changed')
    if REFERENCE_LINK.findall(before) != REFERENCE_LINK.findall(after):
        issues.append('Reference link definitions changed')
    if HTML_COMMENT.findall(before) != HTML_COMMENT.findall(after):
        issues.append('HTML comments changed')
    result = validate(original, candidate)
    issues.extend(result.errors)
    issues.extend('Warning treated as failure: ' + warning for warning in result.warnings)
    return issues


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('original', type=Path)
    parser.add_argument('candidate', type=Path)
    args = parser.parse_args()
    try:
        issues = check_candidate(args.original, args.candidate)
    except OSError as error:
        issues = [str(error)]
    if issues:
        for issue in issues:
            print('FAIL:', issue)
        return 1
    print('PASS: mechanical checks only; semantic review and backup still required')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
