#!/usr/bin/env bash
# scan-dangerous-html.sh — find dangerouslySetInnerHTML usage.
set -euo pipefail

grep -rEn \
  --include='*.tsx' --include='*.jsx' \
  --exclude-dir=node_modules --exclude-dir=.next --exclude-dir=.git --exclude-dir=dist --exclude-dir=build \
  --exclude='*.test.*' --exclude='*.spec.*' \
  'dangerouslySetInnerHTML\s*=' . 2>/dev/null \
  | while IFS=: read -r file line _; do
      printf '[CRITICAL] dangerous-html: %s:%s — dangerouslySetInnerHTML used. Ensure content is sanitized (DOMPurify or equivalent) before rendering, especially if sourced from user input or network.\n' "${file#./}" "$line"
    done || true
