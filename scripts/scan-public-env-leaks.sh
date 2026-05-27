#!/usr/bin/env bash
# scan-public-env-leaks.sh — flag NEXT_PUBLIC_* vars whose name suggests they contain secrets.
set -euo pipefail

for envfile in .env .env.local .env.development .env.production .env.development.local .env.production.local; do
  [[ -f "$envfile" ]] || continue
  grep -nE '^NEXT_PUBLIC_[A-Z_]*(SECRET|KEY|TOKEN|PASSWORD|PRIVATE)' "$envfile" 2>/dev/null \
    | while IFS=: read -r line content; do
        var_name=$(printf '%s' "$content" | sed -E 's/=.*//')
        printf '[HIGH] leaked-server-secret: %s:%s — %s is exposed to the browser via the NEXT_PUBLIC_ prefix. Variables that look like secrets (KEY/TOKEN/SECRET/PASSWORD) should be server-only.\n' "$envfile" "$line" "$var_name"
      done || true
done

grep -rEn \
  --include='*.ts' --include='*.tsx' --include='*.js' --include='*.jsx' \
  --exclude-dir=node_modules --exclude-dir=.next --exclude-dir=.git --exclude-dir=dist --exclude-dir=build \
  --exclude='*.test.*' --exclude='*.spec.*' \
  'process\.env\.NEXT_PUBLIC_[A-Z_]*(SECRET|KEY|TOKEN|PASSWORD|PRIVATE)' . 2>/dev/null \
  | while IFS=: read -r file line _; do
      printf '[HIGH] leaked-server-secret: %s:%s — Reading NEXT_PUBLIC_*SECRET/KEY/TOKEN/PASSWORD from code. The value ships in the browser bundle.\n' "${file#./}" "$line"
    done || true
