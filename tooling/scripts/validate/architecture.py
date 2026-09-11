#!/usr/bin/env python3
from __future__ import annotations

import json
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
SKILL_ROOT = ROOT / "plugin" / "skills" / "ios-architect"
REFERENCES_DIR = SKILL_ROOT / "references"
SKILL_PATH = SKILL_ROOT / "SKILL.md"
README_PATH = ROOT / "README.md"
CONTRACT_PATH = ROOT / "tooling" / "evals" / "contract.json"

ARCHITECTURES = {
    "mvc": "MVC",
    "mvp": "MVP",
    "mvvm-uikit": "MVVM-UIKit",
    "mvvm-swiftui": "MVVM-SwiftUI",
    "mvvm-c": "MVVM-C",
    "mvi": "MVI",
    "reactive": "Reactive",
    "coordinator": "Coordinator",
    "viper": "VIPER",
    "clean-swift": "Clean Swift",
    "clean-architecture": "Clean Architecture",
    "tca": "TCA",
    "redux-reswift": "Redux/ReSwift",
    "ribs": "RIBs",
    "modular-tma": "Modular TMA",
}

SUPPORT_FILES = {
    "_index",
    "analyser",
    "migrator",
    "reference-feature",
    "researcher",
    "selection-guide",
}


def read(path: Path) -> str:
    if not path.exists():
        fail(f"Missing file: {path.relative_to(ROOT)}")
    return path.read_text(encoding="utf-8")


def fail(message: str) -> None:
    print(f"architecture validation failed: {message}", file=sys.stderr)
    sys.exit(1)


def check_missing(label: str, expected: set[str], actual: set[str]) -> None:
    missing = sorted(expected - actual)
    extra = sorted(actual - expected)
    if missing or extra:
        parts = []
        if missing:
            parts.append(f"missing {label}: {', '.join(missing)}")
        if extra:
            parts.append(f"unexpected {label}: {', '.join(extra)}")
        fail("; ".join(parts))


def main() -> None:
    expected = set(ARCHITECTURES)

    reference_files = {
        path.stem
        for path in REFERENCES_DIR.glob("*.md")
        if path.stem not in SUPPORT_FILES
    }
    check_missing("reference playbooks", expected, reference_files)

    skill = read(SKILL_PATH)
    skill_slugs = set(re.findall(r"`([a-z0-9-]+)`", skill))
    check_missing("SKILL router slugs", expected, skill_slugs & expected)

    index = read(REFERENCES_DIR / "_index.md")
    index_slugs = set(re.findall(r"`([a-z0-9-]+)`", index))
    check_missing("index slugs", expected, index_slugs & expected)

    readme = read(README_PATH).lower()
    missing_readme = [
        slug
        for slug, display in ARCHITECTURES.items()
        if slug not in readme and display.lower() not in readme
    ]
    if missing_readme:
        fail(f"README does not mention: {', '.join(missing_readme)}")

    contract = json.loads(read(CONTRACT_PATH))
    contract_slugs = {
        Path(playbook["path"]).stem
        for playbook in contract.get("playbooks", [])
    }
    check_missing("contract playbooks", expected, contract_slugs & expected)

    selection = read(REFERENCES_DIR / "selection-guide.md").lower()
    for required_heading in (
        "## quick flow",
        "## fit signals",
        "## decision scorecard",
        "## reject conditions",
        "## output template",
    ):
        if required_heading not in selection:
            fail(f"selection-guide.md is missing heading {required_heading!r}")

    print(f"Architecture validation passed for {len(expected)} playbooks.")


if __name__ == "__main__":
    main()
