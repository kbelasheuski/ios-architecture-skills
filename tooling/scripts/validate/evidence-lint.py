#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import re
import sys
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
RULES_PATH = ROOT / "tooling" / "evals" / "evidence-lint-rules.json"
URL_RE = re.compile(r"https?://[^\s`|)]+")
SEAM_RE = re.compile(
    r"(fake|spy|teststore|scheduler|clock|route|router|interface|builder|component|middleware|store|viewmodel|presenter|interactor|coordinator|repository|dependency|reducer|listener)",
    re.IGNORECASE,
)


def fail(message: str) -> None:
    print(f"FAIL: {message}")
    raise SystemExit(1)


def read(path: Path) -> str:
    if not path.exists():
        fail(f"missing file: {path.relative_to(ROOT)}")
    return path.read_text(encoding="utf-8")


def heading_section(text: str, heading: str) -> str:
    pattern = re.compile(rf"(?m)^##\s+{re.escape(heading)}\s*$")
    match = pattern.search(text)
    if not match:
        fail(f"missing section: ## {heading}")
    start = match.end()
    next_heading = re.search(r"(?m)^##\s+", text[start:])
    end = start + next_heading.start() if next_heading else len(text)
    return text[start:end]


def table_rows(section: str) -> tuple[list[str], list[dict[str, str]]]:
    lines = [line.strip() for line in section.splitlines() if line.strip().startswith("|")]
    if len(lines) < 3:
        fail("expected a markdown table with at least one row")
    header = [cell.strip() for cell in lines[0].strip("|").split("|")]
    rows: list[dict[str, str]] = []
    for line in lines[2:]:
        cells = [cell.strip() for cell in line.strip("|").split("|")]
        if len(cells) != len(header):
            fail(f"malformed table row: {line}")
        rows.append(dict(zip(header, cells)))
    return header, rows


def proof_path(value: str) -> str | None:
    backtick = re.search(r"`([^`]+)`", value)
    if backtick:
        return backtick.group(1)
    plain = re.search(r"(examples/[A-Za-z0-9._/-]+)", value)
    return plain.group(1) if plain else None


def check_url(url: str) -> bool:
    headers = {"User-Agent": "ios-architect-evidence-lint/1.0"}
    for method in ("HEAD", "GET"):
        req = urllib.request.Request(url, method=method, headers=headers)
        try:
            with urllib.request.urlopen(req, timeout=10) as response:
                return 200 <= response.status < 400
        except urllib.error.HTTPError as exc:
            if method == "HEAD" and exc.code in {403, 405, 429}:
                continue
            return False
        except Exception:
            return False
    return False


def validate_playbook(entry: dict[str, str], check_urls: bool) -> int:
    path = ROOT / entry["path"]
    text = read(path)
    rel = path.relative_to(ROOT)

    for required in ("## Decision examples", "## Source-backed proof", "## Concrete test matrix"):
        if required not in text:
            fail(f"{rel}: missing {required}")
    if "TODO" in text or "TBD" in text:
        fail(f"{rel}: contains TODO/TBD placeholder text")

    source_section = heading_section(text, "Source-backed proof")
    header, rows = table_rows(source_section)
    expected = ["Source", "Claim checked", "Local proof"]
    if header != expected:
        fail(f"{rel}: Source-backed proof columns must be {expected}, got {header}")
    if not rows:
        fail(f"{rel}: Source-backed proof must have at least one row")
    for row in rows:
        urls = URL_RE.findall(row["Source"])
        if not urls:
            fail(f"{rel}: source proof row lacks URL: {row}")
        local = proof_path(row["Local proof"])
        if not local:
            fail(f"{rel}: source proof row lacks local proof path: {row}")
        if not (ROOT / local).exists():
            fail(f"{rel}: local proof path does not exist: {local}")
        if len(row["Claim checked"]) < 30:
            fail(f"{rel}: source proof claim is too thin: {row['Claim checked']}")
        if check_urls:
            for url in urls:
                if not check_url(url):
                    fail(f"{rel}: URL liveness failed: {url}")

    matrix_section = heading_section(text, "Concrete test matrix")
    header, rows = table_rows(matrix_section)
    expected = ["Scenario", "Assertion", "Test seam"]
    if header != expected:
        fail(f"{rel}: Concrete test matrix columns must be {expected}, got {header}")
    if len(rows) < 4:
        fail(f"{rel}: Concrete test matrix needs at least 4 rows")
    for row in rows:
        if not row["Scenario"] or not row["Assertion"] or not row["Test seam"]:
            fail(f"{rel}: matrix row has an empty required cell: {row}")
        if len(row["Assertion"]) < 30:
            fail(f"{rel}: matrix assertion is too thin: {row['Assertion']}")
        if not SEAM_RE.search(row["Test seam"]):
            fail(f"{rel}: matrix row lacks a concrete test seam: {row['Test seam']}")

    example = ROOT / entry["local_example"]
    if not example.exists():
        fail(f"{rel}: configured local example path missing: {entry['local_example']}")
    return len(rows)


def heading_matches(text: str, requested: str) -> bool:
    normalized = requested.strip("# ").lower()
    return any(line.startswith("#") and normalized in line.strip("# ").lower() for line in text.splitlines())


def validate_support(entry: dict[str, object]) -> None:
    path = ROOT / str(entry["path"])
    text = read(path)
    rel = path.relative_to(ROOT)
    for heading in entry.get("required_headings", []):
        if not heading_matches(text, str(heading)):
            fail(f"{rel}: missing support heading matching {heading}")
    for required in entry.get("required_text", []):
        if str(required) not in text:
            fail(f"{rel}: missing required text {required}")
    if ".md.md" in text:
        fail(f"{rel}: contains typo-prone .md.md reference")


def active_text_files() -> list[Path]:
    roots = [ROOT / "tooling", ROOT / ".github", ROOT / "plugin" / "skills" / "ios-architect"]
    files: list[Path] = []
    for base in roots:
        if not base.exists():
            continue
        for path in base.rglob("*"):
            if not path.is_file():
                continue
            rel = path.relative_to(ROOT)
            if "tooling/evals/runs" in rel.as_posix():
                continue
            if rel.as_posix() in {"tooling/evals/evidence-lint-rules.json", "tooling/scripts/validate/evidence-lint.py"}:
                continue
            if path.suffix in {".md", ".py", ".json", ".yml", ".yaml", ".sh"}:
                files.append(path)
    return files


def validate_forbidden(rules: dict[str, object]) -> None:
    forbidden = [str(value) for value in rules.get("forbidden_active_text", [])]
    for path in active_text_files():
        text = path.read_text(encoding="utf-8", errors="ignore")
        rel = path.relative_to(ROOT)
        for value in forbidden:
            if value in text:
                fail(f"{rel}: forbidden active text remains: {value}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Validate ios-architect structure/evidence lint.")
    parser.add_argument("--check-urls", action="store_true", help="Also verify source URL liveness.")
    args = parser.parse_args()

    rules = json.loads(read(RULES_PATH))
    matrix_rows = 0
    for playbook in rules["playbooks"]:
        matrix_rows += validate_playbook(playbook, args.check_urls)
    for support in rules["support_docs"]:
        validate_support(support)
    validate_forbidden(rules)

    print(
        f"Evidence lint passed: {len(rules['playbooks'])} playbooks, "
        f"{len(rules['support_docs'])} support docs, {matrix_rows} matrix rows."
    )


if __name__ == "__main__":
    main()
