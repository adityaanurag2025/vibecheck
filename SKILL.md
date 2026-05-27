---
name: vibecheck
description: Audits an AI-generated Next.js App Router project for the 12 most common production-readiness issues and produces a severity-tiered markdown report. Trigger when the user asks to "vibecheck", "audit my Next.js app", or wants a production-readiness check.
---

# vibecheck

When invoked, run a production-readiness audit on the current Next.js App Router project and produce a markdown report.

## Step 1: Verify this is a Next.js App Router project

Check, in order:

1. `package.json` exists and includes `"next"` in `dependencies` or `devDependencies`.
2. An `app/` directory exists at the project root.

If either check fails, stop and tell the user:

> vibecheck v1 only audits Next.js App Router projects. I couldn't find a `package.json` with Next.js as a dependency, or an `app/` directory at the project root. If your project uses the older Pages Router (`pages/` directory), Pages Router support is on the roadmap but not in v1.

If both checks pass, continue.

## Step 2: Run the bash scanners

Run each of these scripts from the user's project root and collect their output. Each emits zero or more lines in the format `[SEVERITY] check-name: file:line — message`.

````bash
bash ~/.claude/skills/vibecheck/scripts/scan-secrets.sh
bash ~/.claude/skills/vibecheck/scripts/scan-env-files.sh
bash ~/.claude/skills/vibecheck/scripts/scan-dangerous-html.sh
bash ~/.claude/skills/vibecheck/scripts/scan-console-logs.sh
bash ~/.claude/skills/vibecheck/scripts/scan-localhost-urls.sh
bash ~/.claude/skills/vibecheck/scripts/scan-public-env-leaks.sh
````

Run each from the user's current working directory (the project being audited), not from inside the skill directory. The scanners scan `.` (the cwd), which is exactly what we want.

If any scanner exits non-zero or produces no output when it should have, note it but continue with the rest. Never crash the whole audit on a single scanner failure.

## Step 3: Run the judgment-based checks

For checks where pattern-matching isn't reliable, read the relevant files yourself and apply the check definition. Each definition lives in `~/.claude/skills/vibecheck/checks/`. Read the definitions before running these checks:

- **Check 03 (Missing auth):** Read each `app/api/**/route.ts` and each file containing `"use server"`. Apply `checks/03-missing-auth.md`.
- **Check 05 (Missing input validation):** Same set of files. Apply `checks/05-missing-input-validation.md`.
- **Check 06 (Leaked server secrets, code-side):** The scanner catches obvious cases; you also check for less-obvious naming patterns. Apply `checks/06-leaked-server-secrets.md`.
- **Check 07 (Swallowed errors):** Read files that contain `try {` or `.catch(`. Apply `checks/07-swallowed-errors.md`.
- **Check 09 (Missing error.tsx):** Check filesystem: is there an `app/error.tsx`? For routes with async data fetching, is there a sibling `error.tsx` in the segment?
- **Check 10 (Missing loading states):** Is there an `app/loading.tsx`? For client components with bare `useEffect` fetches, do they render any loading UI?
- **Check 12 (Missing not-found.tsx):** Is there an `app/not-found.tsx`?

For each finding, capture: severity, check name, file path, line number (if applicable), and a short specific explanation.

## Step 4: Aggregate and score

Score formula: `10 - (criticals * 2) - (highs * 1) - (mediums * 0.3)`, clamped to `[0, 10]`. Round to one decimal.

Score labels:
- `8.0+` → "Almost Ready to Ship"
- `5.0–7.9` → "Needs Work"
- `2.0–4.9` → "Not Ready to Ship"
- `< 2.0` → "Critical — Do Not Deploy"

## Step 5: Write the report

Read `~/.claude/skills/vibecheck/templates/report-template.md`. Substitute placeholders with the gathered findings. Write the filled template to `vibecheck-report.md` in the user's project root.

The `Top 3 things to fix first` should be the three highest-impact specific findings (not generic advice). Pick the ones with the highest blast radius if exploited.

## Step 6: Summarize in chat

Print a short summary to the chat:

````
🔍 vibecheck complete

Score: 3.4 / 10 — Not Ready to Ship
  🔴 4 Critical
  🟠 3 High
  🟡 2 Medium

Top 3 to fix first:
1. <first specific finding>
2. <second specific finding>
3. <third specific finding>

Full report written to vibecheck-report.md
````

## Notes on tone

- Direct, no condescension. The user is a developer who built something real. Treat findings as a code review from a friend, not an inspection from a regulator.
- Be specific. "Missing auth" is bad; "DELETE /api/todos accepts any request without checking the session" is good.
- Don't pad. Zero findings is fine. Don't invent issues to hit a quota.

## What NOT to do

- Don't auto-fix anything in v1.
- Don't `npm install` or modify the project's files.
- Don't run the project's tests, build, or dev server.
- Don't scan `node_modules/`, `.next/`, or any `.test.` / `.spec.` files.
- Don't include findings in `vibecheck/examples/demo-app/` itself if the user happens to be inside this repo — that demo is deliberately broken on purpose.
