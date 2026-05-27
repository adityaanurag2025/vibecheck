#!/usr/bin/env bash
# install.sh — install vibecheck into ~/.claude/skills/vibecheck/
set -euo pipefail

INSTALL_DIR="${HOME}/.claude/skills/vibecheck"
REPO_URL="${VIBECHECK_REPO_URL:-https://github.com/YOUR_USERNAME/vibecheck.git}"
TMP_DIR="$(mktemp -d)"

echo "vibecheck installer"
echo "==================="

# Check prerequisites.
for cmd in git bash grep; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "error: '$cmd' is required but not installed." >&2
    exit 1
  fi
done

# Clone (or update) the skill.
if [[ -d "$INSTALL_DIR" ]]; then
  echo "Existing install detected at $INSTALL_DIR — updating."
  git -C "$INSTALL_DIR" fetch --quiet origin
  git -C "$INSTALL_DIR" reset --hard origin/main --quiet
else
  echo "Installing to $INSTALL_DIR ..."
  mkdir -p "$(dirname "$INSTALL_DIR")"
  git clone --quiet --depth=1 "$REPO_URL" "$INSTALL_DIR"
fi

# Ensure scripts are executable.
chmod +x "$INSTALL_DIR"/scripts/*.sh "$INSTALL_DIR"/install.sh 2>/dev/null || true

echo ""
echo "✓ vibecheck installed to $INSTALL_DIR"
echo ""
echo "To use it:"
echo "  1. Open Claude Code in any Next.js App Router project."
echo "  2. Ask Claude to 'vibecheck this project' (or type /vibecheck if you've enabled slash-command resolution)."
echo ""
echo "Demo: run vibecheck on the included broken demo app to see what it does:"
echo "  cd $INSTALL_DIR/examples/demo-app"
echo "  # then ask Claude Code to vibecheck"
echo ""

rm -rf "$TMP_DIR"
