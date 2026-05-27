#!/usr/bin/env bash
# scan-localhost-urls.sh — find hardcoded localhost / 127.0.0.1 URLs.
set -euo pipefail

grep -rEn \
  --include='*.ts' --include='*.tsx' --include='*.js' --include='*.jsx' --include='*.json' \
  --exclude-dir=node_modules --exclude-dir=.next --exclude-dir=.git --exclude-dir=dist --exclude-dir=build --exclude-dir=tests --exclude-dir=__tests__ \
  --exclude='*.test.*' --exclude='*.spec.*' \
  'https?://(localhost|127\.0\.0\.1)' . 2>/dev/null \
  | while IFS=: read -r file line _; do
      printf '[HIGH] hardcoded-localhost: %s:%s — Hardcoded localhost/127.0.0.1 URL in source. Replace with `process.env.NEXT_PUBLIC_API_URL` (or server-only env var) so it works in production.\n' "${file#./}" "$line"
    done || true
