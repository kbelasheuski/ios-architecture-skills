#!/usr/bin/env bash
set -euo pipefail

target="${1:-plugin/skills/ios-architect/references}"

python3 - "$target" <<'PY'
from pathlib import Path
import re
import sys

root = Path.cwd()
target = root / sys.argv[1]
paths = [target] if target.is_file() else sorted(target.glob("*.md"))

checked_blocks = 0
for path in paths:
    text = path.read_text(encoding="utf-8")
    if text.count("```") % 2:
        raise SystemExit(f"{path}: unbalanced fenced code block")
    for match in re.finditer(r"```(?:swift|Swift)\n(.*?)```", text, flags=re.DOTALL):
        checked_blocks += 1
        body = match.group(1).strip()
        if not body:
            raise SystemExit(f"{path}: empty Swift code block")
        if "TODO" in body or "fatalError(\"TODO" in body:
            raise SystemExit(f"{path}: Swift code block contains TODO placeholder")

print(f"Markdown snippet validation passed for {len(paths)} files ({checked_blocks} Swift blocks).")
PY
