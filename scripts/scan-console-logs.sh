#!/usr/bin/env bash
# scan-console-logs.sh — find console.log/debug/info in source (not test) files.
set -euo pipefail

grep -rEn \
  --include='*.ts' --include='*.tsx' --include='*.js' --include='*.jsx' \
  --exclude-dir=node_modules --exclude-dir=.next --exclude-dir=.git --exclude-dir=dist --exclude-dir=build --exclude-dir=tests --exclude-dir=__tests__ \
  --exclude='*.test.*' --exclude='*.spec.*' \
  'console\.(log|debug|info)\s*\(' . 2>/dev/null \
  | while IFS=: read -r file line _; do
      printf '[MEDIUM] console-log-in-prod: %s:%s — console.log/debug/info call in source. Remove or guard with `if (process.env.NODE_ENV !== "production")` before deploying.\n' "${file#./}" "$line"
    done || true
