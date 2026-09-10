#!/usr/bin/env python3
from __future__ import annotations

import json
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
MANIFEST_PATH = ROOT / "tooling" / "evals" / "benchmarks" / "manifest.json"


def fail(message: str) -> None:
    print(f"benchmark failed: {message}", file=sys.stderr)
    sys.exit(1)


def main() -> None:
    manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    passed = 0

    for case in manifest.get("cases", []):
        case_id = case["id"]
        file_path = ROOT / case["file"]
        if not file_path.exists():
            fail(f"{case_id}: missing file {case['file']}")
        content = file_path.read_text(encoding="utf-8")

        for assertion in case.get("architecture_assertions", []):
            pattern = assertion["regex"]
            expected = bool(assertion.get("expect_match", True))
            actual = bool(re.search(pattern, content, flags=re.IGNORECASE | re.MULTILINE | re.DOTALL))
            if actual != expected:
                polarity = "match" if expected else "not match"
                fail(f"{case_id}: expected {assertion['label']} to {polarity} /{pattern}/")

        passed += 1

    print(f"Benchmark assertions passed for {passed} cases.")


if __name__ == "__main__":
    main()
