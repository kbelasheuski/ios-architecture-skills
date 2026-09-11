#!/usr/bin/env python3
from __future__ import annotations

import json
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
CONTRACT_PATH = ROOT / "tooling" / "evals" / "contract.json"


def fail(message: str) -> None:
    print(f"testing quality validation failed: {message}", file=sys.stderr)
    sys.exit(1)


def read(path: Path) -> str:
    if not path.exists():
        fail(f"Missing file: {path.relative_to(ROOT)}")
    return path.read_text(encoding="utf-8")


def section_body(content: str, heading_regex: str, path: Path) -> str:
    heading = re.search(heading_regex, content, flags=re.IGNORECASE | re.MULTILINE)
    if not heading:
        fail(f"{path.relative_to(ROOT)} is missing section matching {heading_regex!r}")

    next_heading = re.search(r"^##\s+", content[heading.end():], flags=re.MULTILINE)
    if not next_heading:
        return content[heading.end():]
    return content[heading.end(): heading.end() + next_heading.start()]


def count_matches(text: str, regex: str) -> int:
    return len(re.findall(regex, text, flags=re.IGNORECASE | re.MULTILINE | re.DOTALL))


def main() -> None:
    contract = json.loads(read(CONTRACT_PATH))
    default_heading = contract["defaults"]["testing_section_heading_regex"]
    groups = contract["defaults"].get("required_any_groups", [])
    patterns = contract["defaults"].get("required_patterns", [])

    checked = 0
    for playbook in contract["playbooks"]:
        path = ROOT / playbook["path"]
        content = read(path)
        heading_regex = playbook.get("testing_section_heading_regex", default_heading)
        testing = section_body(content, heading_regex, path)

        for group in groups:
            if not any(re.search(pattern, testing, flags=re.IGNORECASE | re.MULTILINE | re.DOTALL)
                       for pattern in group["patterns"]):
                fail(f"{path.relative_to(ROOT)} testing section misses {group['label']}")

        for rule in patterns + playbook.get("required_patterns", []):
            scope = content if rule.get("scope") == "file" else testing
            minimum = int(rule.get("min_count", 1))
            actual = count_matches(scope, rule["regex"])
            if actual < minimum:
                fail(
                    f"{path.relative_to(ROOT)} misses {rule['label']} "
                    f"(expected >= {minimum}, found {actual})"
                )

        checked += 1

    print(f"Testing quality validation passed for {checked} playbooks.")


if __name__ == "__main__":
    main()
