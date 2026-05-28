# vibecheck

> Find out what'll break in production, before production does.

A Claude Code skill that audits AI-generated Next.js apps for the 12 things that always go wrong.

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

---

## What it does

You vibe-coded an app. It runs on localhost. Now what?

vibecheck audits your Next.js project against a curated checklist of the 12 production-readiness issues that AI-assisted codebases consistently get wrong: exposed secrets, missing auth, no input validation, swallowed errors, hardcoded URLs.

Run once. Get a severity-tiered report in 30 seconds. Decide what to fix.

[See a sample report](examples/sample-report.md) — generated from the broken demo app in this repo.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/adityaanurag2025/vibecheck/main/install.sh | bash
```

That installs the skill into `~/.claude/skills/vibecheck/`. No npm, no Node deps, nothing to configure.

## Run it

Open Claude Code in any Next.js App Router project and ask:

> vibecheck this project

Claude reads the skill, runs the scanners, applies the judgment-based checks, and writes a report to `vibecheck-report.md` in your project root. A summary prints to chat.

## What it checks

**🔴 Critical — security or data loss**
1. Exposed secrets in source (API keys, tokens, DB passwords)
2. `.env*` files not in `.gitignore`
3. Missing auth on API routes / Server Actions that mutate data
4. `dangerouslySetInnerHTML` without sanitization

**🟠 High — production failure or silent breakage**
5. Missing input validation on Server Actions / API routes
6. Server secrets leaked via `NEXT_PUBLIC_` prefix
7. Swallowed errors (empty catches, no-op `.catch()`)
8. Hardcoded `localhost` / dev URLs

**🟡 Medium — operational pain, bad UX**
9. Missing error boundaries (`error.tsx`)
10. Missing loading states (`loading.tsx`, bare `useEffect` fetches)
11. `console.log` left in production code
12. Missing `not-found.tsx` (404)

Each check has a dedicated [definition file](checks/) explaining what it looks for, what it ignores, and how to fix it.

## Try it on the demo app

This repo includes [a deliberately-broken Next.js app](examples/demo-app/) you can audit immediately:

```bash
cd ~/.claude/skills/vibecheck/examples/demo-app
# then ask Claude Code to vibecheck this project
```

It contains a true-positive instance of every check vibecheck runs.

## Founder note

I'm not a traditional software engineer. I worked in supply chain (Blue Yonder, TCS) for years before AI coding tools made it possible for someone like me to actually build things. I built three apps with Claude and Cursor before realizing they all had the same set of problems: secrets in source, no input validation, hardcoded localhost URLs that worked perfectly until they didn't.

vibecheck is the audit I wish I'd had on day one — the friend who quietly tells you what's wrong before your launch tweet goes out.

If you're in the same boat: I made this for us.

— Aditya

## FAQ

**Does this replace tests?**
No. vibecheck catches structural issues with how AI-assisted code is typically written. It doesn't verify your business logic. You still need tests.

**Does it support Pages Router?**
Not in v1. Next.js App Router only. Pages Router is on the roadmap.

**Python? FastAPI?**
Not in v1. Roadmap.

**Will it modify my code?**
No. v1 is audit-only — it writes a single report file (`vibecheck-report.md`) and that's it. v2 will add an opt-in "guide me through fixes" mode.

**Does it run npm install / build / tests?**
No. It only reads files.

## Contributing

PRs welcome — especially new checks. Each check is one self-contained file in [`checks/`](checks/) plus an optional scanner script in [`scripts/`](scripts/). See [CONTRIBUTING.md](CONTRIBUTING.md) (coming soon).

## Roadmap

- **v2:** Interactive triage — walk through findings, apply safe fixes with consent.
- **v3:** Python support (FastAPI, Streamlit).
- **v4:** CI integration (GitHub Action wrapper).

## License

[MIT](LICENSE)
