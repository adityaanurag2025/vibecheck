#!/usr/bin/env bash
# scan-secrets.sh — find hardcoded API keys/tokens in source files.
# Output format: [SEVERITY] check-name: file:line — message
set -euo pipefail

scan() {
  local name="$1"
  local pattern="$2"
  grep -rEn \
    --include='*.ts' --include='*.tsx' --include='*.js' --include='*.jsx' --include='*.json' \
    --exclude-dir=node_modules --exclude-dir=.next --exclude-dir=.git --exclude-dir=dist --exclude-dir=build \
    --exclude='*.test.*' --exclude='*.spec.*' \
    "$pattern" . 2>/dev/null \
    | while IFS=: read -r file line _; do
        printf '[CRITICAL] exposed-secrets: %s:%s — Hardcoded %s pattern detected\n' "${file#./}" "$line" "$name"
      done || true
}

scan 'OpenAI key'      'sk-[a-zA-Z0-9_-]{20,}'
scan 'Anthropic key'   'sk-ant-[a-zA-Z0-9_-]{20,}'
scan 'GitHub token'    'gh[ps]_[a-zA-Z0-9]{36}'
scan 'Google API key'  'AIza[0-9A-Za-z_-]{35}'
scan 'Slack token'     'xox[bpoa]-[0-9a-zA-Z-]+'
scan 'AWS access key'  'AKIA[0-9A-Z]{16}'
