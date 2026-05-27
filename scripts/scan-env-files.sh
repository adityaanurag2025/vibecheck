#!/usr/bin/env bash
# scan-env-files.sh — find .env* files that aren't in .gitignore.
set -euo pipefail

GITIGNORE_CONTENT=""
[[ -f .gitignore ]] && GITIGNORE_CONTENT=$(cat .gitignore)

ENV_FILES=(.env .env.local .env.development .env.production .env.development.local .env.production.local .env.test .env.test.local)

for file in "${ENV_FILES[@]}"; do
  [[ -f "$file" ]] || continue
  if ! printf '%s\n' "$GITIGNORE_CONTENT" | grep -qE "^${file}$|^\.env\*?$|^\.env\.\*$|^\*\.env$"; then
    printf '[CRITICAL] env-not-gitignored: %s — Environment file is tracked by git (or not gitignored). Secrets inside will be committed.\n' "$file"
  fi
done
