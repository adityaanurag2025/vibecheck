# Check 11: console.log Left in Production Code

**Severity:** Medium
**Detection:** Scripted (`scripts/scan-console-logs.sh`).

## What to look for

`console.log`, `console.debug`, or `console.info` calls in non-test source files. In production these:
- Bloat the client bundle slightly.
- Can leak user data (tokens, PII) to anyone with browser devtools.
- Generally signal "this was a debugging session that never got cleaned up."

`console.warn` and `console.error` are NOT flagged — they're legitimate signals.

## True positives

```ts
console.log("user logged in:", user);
console.debug("response data:", data);
```

## False positives to skip

- Test files (already excluded by scanner).
- Calls guarded by `if (process.env.NODE_ENV !== "production")`.
- Logs in CLI scripts or one-off tools (not part of the deployed app).

## Suggested fix

Either:

1. Remove the call.
2. Replace with `console.warn` / `console.error` if the signal is genuinely useful.
3. Replace with a proper logger (`pino`, `winston`, server-only) for server code.
4. Guard with NODE_ENV:

```ts
if (process.env.NODE_ENV !== "production") {
  console.log("debug:", value);
}
```
