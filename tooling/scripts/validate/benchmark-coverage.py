#!/usr/bin/env python3
from __future__ import annotations

import json
import sys
from collections import defaultdict
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
MANIFEST_PATH = ROOT / "tooling" / "evals" / "benchmarks" / "manifest.json"

ARCHITECTURES = {
    "mvc",
    "mvp",
    "mvvm-uikit",
    "mvvm-swiftui",
    "mvvm-c",
    "mvi",
    "reactive",
    "coordinator",
    "viper",
    "clean-swift",
    "clean-architecture",
    "tca",
    "redux-reswift",
    "ribs",
    "modular-tma",
}


def fail(message: str) -> None:
    print(f"benchmark coverage validation failed: {message}", file=sys.stderr)
    sys.exit(1)


def main() -> None:
    if not MANIFEST_PATH.exists():
        fail(f"Missing manifest: {MANIFEST_PATH.relative_to(ROOT)}")
    manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))

    coverage: dict[str, set[str]] = defaultdict(set)
    for case in manifest.get("cases", []):
        slug = case.get("architecture")
        if slug not in ARCHITECTURES:
            fail(f"Unknown architecture in case {case.get('id')!r}: {slug!r}")
        assertions = case.get("architecture_assertions", [])
        if not assertions:
            fail(f"Case {case.get('id')!r} has no architecture assertions")
        bucket = "negative" if any(assertion.get("expect_match") is False for assertion in assertions) else "positive"
        coverage[slug].add(bucket)

    missing = {
        slug: sorted({"positive", "negative"} - coverage.get(slug, set()))
        for slug in sorted(ARCHITECTURES)
        if coverage.get(slug, set()) != {"positive", "negative"}
    }
    if missing:
        details = "; ".join(f"{slug}: {', '.join(kinds)}" for slug, kinds in missing.items())
        fail(f"missing benchmark coverage: {details}")

    print(f"Benchmark coverage validation passed for {len(ARCHITECTURES)} architectures.")


if __name__ == "__main__":
    main()
