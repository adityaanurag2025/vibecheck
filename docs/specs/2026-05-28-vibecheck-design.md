# vibecheck — Design Spec

**Date:** 2026-05-28
**Owner:** Aditya Anurag
**Status:** Draft v1, pending user review

---

## 1. What it is, in one sentence

A Claude Code skill that audits a vibe-coded Next.js / React / TypeScript app and produces a severity-tiered "what will break in production" report.

## 2. Audience and positioning

**Target user:** Developers — especially "vibe-coders" — who built a working Next.js app with Claude / Cursor / Copilot and now want to ship it but don't know what they don't know.

**Core promise:** "Run vibecheck and find out the 10–20 things that will embarrass you in production, in 30 seconds, without leaving your editor."

**Why it can go viral:**
- Solves a felt pain that nobody currently solves well (generic linters don't speak the AI-generated-code dialect).
- Demo is screenshot-friendly: one beautiful report with red/yellow/green tiers.
- Plays on the "vibe-coder" identity that's having a cultural moment.
- Authentic founder story: built by a non-traditional coder who needed it himself.

## 3. Scope (v1)

**In scope:**
- Curated checklist of 12 high-impact checks (4 Critical / 4 High / 4 Medium).
- Next.js (App Router) / React / TypeScript codebases.
- Markdown report output, written to `vibecheck-report.md` in project root + summary in chat.
- One-command install (`curl ... | bash`) into `~/.claude/skills/vibecheck/`.
- A deliberately-broken demo Next.js app in `examples/` so anyone can try the skill without their own project.

**Out of scope for v1 (explicit non-goals):**
- Auto-fixing issues (planned v2).
- Interactive triage walkthrough (planned v2).
- Python / FastAPI / Streamlit support (planned later if traction).
- Pages Router (older Next.js) — App Router only.
- CI integration / GitHub Action wrapper.
- Web UI / dashboard.
- Multi-project scanning.

## 4. Architecture

### Invocation flow

1. User in any Next.js project runs the skill (e.g., types `/vibecheck` or asks Claude to vibecheck the project).
2. Claude reads `SKILL.md` — the orchestration brain.
3. Claude runs the bash helper scripts in `scripts/` to gather mechanically-detectable findings. Each script emits JSON lines to stdout.
4. Claude reads the project's key files itself — `next.config.*`, `package.json`, `app/**/route.ts`, server actions, env access points, auth middleware — and applies judgment-based checks defined in `checks/*.md`.
5. Claude aggregates everything into the report template and writes `vibecheck-report.md` to the project root.
6. Claude prints a chat summary: severity counts + top 3 things to fix.

### Repo layout

```
vibecheck/
├── SKILL.md                  # The brain — orchestration prompt for Claude
├── README.md                 # Marketing-facing, install, demo, vibe
├── checks/                   # One file per check: pattern, why it matters, fix
│   ├── 01-exposed-secrets.md
│   ├── 02-env-not-gitignored.md
│   ├── 03-missing-auth.md
│   ├── 04-dangerous-html.md
│   ├── 05-missing-input-validation.md
│   ├── 06-leaked-server-secrets.md
│   ├── 07-swallowed-errors.md
│   ├── 08-hardcoded-localhost.md
│   ├── 09-missing-error-boundary.md
│   ├── 10-missing-loading-states.md
│   ├── 11-console-log-in-prod.md
│   └── 12-missing-not-found.md
├── scripts/                  # Bash helpers for scannable patterns
│   ├── scan-secrets.sh
│   ├── scan-env-files.sh
│   ├── scan-dangerous-html.sh
│   ├── scan-console-logs.sh
│   ├── scan-localhost-urls.sh
│   └── scan-public-env-leaks.sh
├── templates/
│   └── report-template.md    # The output format
├── examples/
│   ├── demo-app/             # Deliberately-broken Next.js app for testing
│   └── sample-report.md      # Real audit output, used in README
├── install.sh                # One-liner installer
└── docs/specs/               # This spec lives here
```

**Why bash, not Node:** zero install, runs on every dev machine, no `package.json` dependency to maintain. The skill stays portable and dependency-free.

**Why one-file-per-check:** each check is self-contained. New checks land as single-file PRs. Contributors don't need to understand the orchestration brain to add a check.

**Why a real demo app, not screenshots only:** "try it on the demo app" is a much stronger CTA than a screenshot. Demo app gets cloned with the repo.

## 5. The checklist (v1)

12 checks across three severity tiers. Each check has a slot in `checks/*.md` describing: pattern, examples of true positives, examples of false positives to avoid, suggested fix, code snippet.

### Critical — security or data loss

1. **Exposed secrets in source code** — hardcoded API keys (`sk-`, `ghp_`, `AIza`, etc.), Bearer tokens, DB connection strings in committed files.
2. **`.env*` files not gitignored** — `.env`, `.env.local`, `.env.production` tracked by git or missing from `.gitignore`.
3. **Missing auth on protected endpoints** — `app/api/**/route.ts` handlers and Server Actions that mutate data without a session/auth check.
4. **`dangerouslySetInnerHTML` without sanitization** — XSS risk; flagged unless paired with DOMPurify or equivalent.

### High — production failure or silent breakage

5. **Missing input validation on Server Actions / API routes** — taking `formData` or request body straight into DB calls without `zod` / `yup` / manual validation.
6. **Server-side secrets leaked via `NEXT_PUBLIC_`** — sensitive env vars (anything matching `*SECRET*`, `*KEY*`, `*TOKEN*`, `*PASSWORD*`) prefixed with `NEXT_PUBLIC_`, which exposes them to the client bundle.
7. **Swallowed errors / empty catches** — `catch (e) {}`, `.catch(() => {})`, async event handlers without `try/catch`.
8. **Hardcoded localhost or dev URLs** — `http://localhost:*`, `127.0.0.1`, hardcoded staging/dev API bases shipped in source.

### Medium — operational pain, bad UX

9. **Missing error boundaries** — App Router routes that fetch data without an `error.tsx` sibling.
10. **Missing loading states** — async routes/components without `loading.tsx` or any loading UI; bare `useEffect` fetches with no loading indicator.
11. **`console.log` left in production code paths** — non-test, non-dev-only `console.log` / `console.debug` calls in `app/`, `lib/`, `components/`.
12. **Missing `not-found.tsx`** — App Router projects without 404 handling.

## 6. Report format

The output report is a single Markdown file the user can read, share, screenshot, or paste into an LLM for fix help.

### Structure

```markdown
# vibecheck report

**Project:** <repo name>
**Scanned:** <date> <time>
**Score:** 3 / 10 — Not Ready to Ship

## TL;DR
- 🔴 4 Critical issues
- 🟠 6 High-severity issues
- 🟡 9 Medium-severity issues

## Top 3 things to fix first
1. <highest impact finding>
2. <second>
3. <third>

---

## 🔴 Critical

### 1. Exposed OpenAI API key in `lib/llm.ts:12`
**What's wrong:** Hardcoded `sk-...` token in committed source. Anyone with repo access — including past contributors and anyone who clones a leaked copy — can use your OpenAI account.
**Suggested fix:** Move to `process.env.OPENAI_API_KEY`, add to `.env.local`, rotate the existing key immediately.
```ts
// lib/llm.ts:12
- const apiKey = "sk-proj-abc123...";
+ const apiKey = process.env.OPENAI_API_KEY;
```

### 2. ...

---

## 🟠 High
...

## 🟡 Medium
...

---

## What vibecheck did NOT check
<honesty section — what we don't cover, so users don't assume "vibecheck-clean = production-clean">
```

### Scoring

Simple, transparent: `10 - (criticals * 2) - (highs * 1) - (mediums * 0.3)`, clamped to `[0, 10]`. Score is for vibes (and shareability) — the issue list is the truth.

### Tone

Honest, direct, no condescension. Vibe-coders feel judged enough; this skill is "a friend doing a code review," not "an expert dunking on you."

## 7. Marketing / README angle

The README does as much work as the code. For virality, this section is non-optional.

### Hero

- **Headline:** "vibecheck — find out what'll break in production, before production does."
- **Subhead:** "A Claude Code skill that audits AI-generated Next.js apps for the 12 things that always go wrong."
- **Demo:** animated terminal recording (asciinema) showing a 30-second audit run end-to-end on the demo app.

### The pitch (above the fold)

> You vibe-coded an app. It runs on localhost. Now what?
>
> vibecheck audits your Next.js project against a curated checklist of the 12 production-readiness issues that AI-assisted codebases consistently get wrong: exposed secrets, missing auth, no input validation, swallowed errors, hardcoded URLs.
>
> Run once. Get a severity-tiered report in 30 seconds. Decide what to fix.

### Install

```bash
curl -fsSL https://raw.githubusercontent.com/<user>/vibecheck/main/install.sh | bash
```
Then in any Next.js project: ask Claude to vibecheck it.

### Founder note (signature section — drives shares)

A short, honest paragraph from the author: supply chain professional who learned to code with AI, built three apps that broke in production in different ways, made this for himself first. Authenticity > polish.

### Sections (in order)

1. Hero + demo gif
2. What it checks (the 12-item list, with badges)
3. Install (one-liner)
4. Run it (one sentence)
5. Sample report (link to `examples/sample-report.md`)
6. Founder note
7. FAQ ("does this replace tests?", "does it support Pages Router?", "what about Python?")
8. Contributing (how to add a check)
9. Roadmap (v2 = interactive fix walkthrough)

## 8. Data flow

```
user invocation
  ↓
SKILL.md loaded
  ↓
parallel:
  ├── run scripts/*.sh → JSON findings → stdout
  └── Claude reads checks/*.md to load judgment-based check definitions
  ↓
Claude reads project files relevant to judgment checks
(next.config, route handlers, server actions, middleware, env access)
  ↓
aggregate findings, dedupe, assign severity
  ↓
fill templates/report-template.md
  ↓
write vibecheck-report.md to project root
  ↓
print chat summary (severity counts + top 3 actions)
```

## 9. Error handling and edge cases

- **Not a Next.js project:** skill detects no `next` in `package.json` → exits with a friendly "vibecheck only audits Next.js App Router projects in v1" message. Doesn't try to fake an audit.
- **Pages Router project:** detected via `pages/` directory without `app/` → friendly message, App Router only in v1.
- **A scanner script fails:** continue with the rest, note "1 scanner errored — N findings may be incomplete" in the report. Never crash the whole audit.
- **Empty project / fresh `create-next-app`:** report shows "no issues found" rather than padding with false positives. Important — the demo must work cleanly on a vanilla scaffold.
- **Monorepo:** v1 only audits the cwd. Document the limitation; deeper monorepo support is post-v1.

## 10. Testing strategy

Two layers:

1. **Demo app in `examples/demo-app/`** — a deliberately broken Next.js app containing one true-positive instance of each of the 12 checks. CI runs vibecheck on it and asserts every check fires exactly once.
2. **Negative-case scaffold** — fresh `create-next-app` output committed as a baseline. CI runs vibecheck on it and asserts zero Critical and zero High findings (a couple of Medium "nice to have" findings are acceptable).

These two tests together prevent both false negatives (missed real issues) and false positives (alarmist findings on clean code).

## 11. Success metrics (post-launch)

A skill is "viral enough" if any one of these hits in 60 days:

- 500+ GitHub stars
- A single tweet about it crossing 100 likes from someone outside the author's network
- One inbound mention from a recognized creator (Theo, Lee Robinson, Guillermo, etc.)
- 5+ external contributors PR'ing new checks

If none hit, the skill is still useful personally — but the marketing assumption (vibe-coder identity riding the cultural wave) was wrong, and v2 needs rethinking before more effort.

## 12. Open questions (resolve before implementation)

- **GitHub username/org** for the install URL — need to confirm.
- **Repo name availability check** — `vibecheck` may be taken on GitHub; if so, fallbacks: `vibecheck-skill`, `vibe-check`, `the-vibecheck`.
- **License** — MIT is the default unless there's a reason not to.
- **Skill name in Claude** — does the slash command `/vibecheck` collide with anything in the user's existing skills? Verify before locking.
