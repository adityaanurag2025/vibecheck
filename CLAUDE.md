# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

vibecheck is itself a **Claude Code skill**, not a runnable application. There is no build, no test suite, no package to install — the deliverable is the skill files that get copied into `~/.claude/skills/vibecheck/` by `install.sh`. When a user runs the skill in *their* Next.js project, Claude reads `SKILL.md` and executes the audit against their working directory.

This means there are two distinct contexts, and conflating them is the main pitfall:
- **Authoring context** (this repo): you're editing the skill's instructions, scanners, and check definitions.
- **Runtime context** (a user's project): the skill scans `.` (the user's cwd). Scanners and `SKILL.md` paths assume they live at `~/.claude/skills/vibecheck/`.

## Architecture

`SKILL.md` is the orchestration brain. It defines the 6-step audit flow Claude follows at runtime: (1) verify it's a Next.js App Router project, (2) run the bash scanners, (3) run judgment-based checks, (4) aggregate and score, (5) fill the report template, (6) print a chat summary. Editing the audit's behavior almost always means editing `SKILL.md`.

The 12 checks split across two detection mechanisms:

- **Scripted checks** — a `scripts/scan-*.sh` does deterministic pattern matching (e.g. regex for known API-key formats). Used where pattern matching is reliable.
- **Judgment-based checks** — no scanner; `SKILL.md` directs Claude to read specific files (e.g. every `route.ts` and `"use server"` file) and apply a check definition. Used where pattern matching produces too many false positives (missing auth, swallowed errors, missing `error.tsx`).

Some checks (e.g. 01, 06) are hybrid: a scanner catches obvious cases and Claude catches the subtle ones.

Every check has a definition file in `checks/NN-name.md` describing what to flag, true positives, false positives to skip, and the suggested fix. The `checks/` definitions are the source of truth for *what* a check means; the scanners and `SKILL.md` are *how* it runs.

Severity tiers and scoring (defined in `SKILL.md`): Critical (×2 penalty), High (×1), Medium (×0.3), applied to `score = 10 - 2·crit - 1·high - 0.3·med`, clamped to `[0,10]`.

## Conventions when adding or editing a check

A check is **one self-contained `checks/NN-name.md` file plus an optional `scripts/scan-name.sh`**. To add a check:
1. Write `checks/NN-name.md` (follow the structure of existing files: What to look for / True positives / False positives to skip / Suggested fix).
2. If it's pattern-matchable, add `scripts/scan-name.sh`; otherwise add it to the judgment-based list in `SKILL.md` Step 3.
3. Wire it into `SKILL.md` (scanner list in Step 2 or judgment list in Step 3).
4. Add a true-positive instance to `examples/demo-app/` so the demo still contains an instance of every check.
5. Update the check list in `README.md`.

### Scanner contract

Every scanner emits lines in exactly this format (parsed downstream by Claude):

```
[SEVERITY] check-name: file:line — message
```

Scanners must:
- Scan `.` (the runtime cwd), not the skill directory.
- Exclude `node_modules`, `.next`, `.git`, `dist`, `build`, and `*.test.*` / `*.spec.*` files.
- Strip the leading `./` from paths (`${file#./}`).
- Never crash the audit — fail soft (`|| true`, `2>/dev/null`). `set -euo pipefail` is standard at the top, but pipelines that may legitimately match nothing must not abort.

### The demo app is broken on purpose

`examples/demo-app/` is a deliberately broken Next.js app containing a true positive of every check (including committed `.env` files and fake-looking secrets). Do **not** "fix" it, and the skill must never flag findings inside `examples/demo-app/` when someone audits this repo itself (noted in `SKILL.md` Step "What NOT to do").

## v1 scope guardrails (from SKILL.md and README)

The skill is intentionally constrained — preserve these unless explicitly changing scope:
- Audit-only. No auto-fix, no `npm install`, no modifying the user's files, no running their build/tests/dev server.
- Only writes a single `vibecheck-report.md` to the audited project's root.
- Next.js **App Router** only (requires `next` in deps + an `app/` dir). Pages Router, Python/FastAPI, and CI integration are explicitly roadmap, not v1.

## Tone for findings (when working on report/output text)

Findings read like a code review from a friend, not a regulator. Be specific ("DELETE /api/todos accepts any request without checking the session", not "missing auth"). Don't pad or invent issues to hit a quota — zero findings is a valid result.
