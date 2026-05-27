# Check 06: Server Secrets Leaked via NEXT_PUBLIC_

**Severity:** High
**Detection:** Scripted (`scripts/scan-public-env-leaks.sh`) + Claude judgment.

## What to look for

In Next.js, any env var prefixed with `NEXT_PUBLIC_` is inlined into the client JavaScript bundle. If a variable name matches `SECRET`, `KEY`, `TOKEN`, `PASSWORD`, or `PRIVATE`, it's almost certainly meant to be server-only and the `NEXT_PUBLIC_` prefix is a mistake.

Check both:
1. `.env*` files for `NEXT_PUBLIC_*SECRET-ish` variable declarations.
2. Source code for `process.env.NEXT_PUBLIC_*SECRET-ish` reads.

## True positives

```
# .env.local
NEXT_PUBLIC_DB_PASSWORD=hunter2
NEXT_PUBLIC_OPENAI_KEY=sk-...
```

```tsx
const key = process.env.NEXT_PUBLIC_API_SECRET;  // ← bundled into browser
```

## False positives to skip

- `NEXT_PUBLIC_*` names that don't look like secrets (e.g., `NEXT_PUBLIC_GA_ID`, `NEXT_PUBLIC_POSTHOG_KEY` — analytics keys that are designed to be public).
- The variable contains "KEY" but is genuinely public (Stripe publishable keys: `NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY`).

When in doubt, look at the value's role — if it could be used to authenticate or impersonate a user/service, it shouldn't be `NEXT_PUBLIC_`.

## Suggested fix

```diff
- NEXT_PUBLIC_DB_PASSWORD=hunter2
+ DB_PASSWORD=hunter2
```

Then refactor the code to access it server-side only (in a Server Component, Server Action, Route Handler, or `getServerSideProps`-like code path). Rotate the leaked value if the project has already been built/deployed with the `NEXT_PUBLIC_` prefix.
