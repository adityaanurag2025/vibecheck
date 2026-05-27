# Check 02: .env Files Not Gitignored

**Severity:** Critical
**Detection:** Scripted (`scripts/scan-env-files.sh`).

## What to look for

`.env`, `.env.local`, `.env.production`, etc. that exist on disk but are NOT covered by a `.gitignore` rule. If they're not ignored, they'll be committed — meaning every secret inside them is in git history forever.

## True positives

- `.env` file exists, `.gitignore` does not contain `.env`, `.env*`, or `.env.*`.
- `.env.local` exists and the `.gitignore` only lists `.env` (misses the local variant).

## False positives to skip

- `.env.example` — convention for committed placeholder files (these should be gitignored only if they contain real values).

## Suggested fix

Add to `.gitignore`:
```
.env
.env.*
!.env.example
```

Then, if any env file has already been committed: rotate every secret it contained AND remove from history (`git rm --cached .env`, commit, then optionally use `git filter-repo` to scrub history).
