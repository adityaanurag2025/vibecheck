# Check 07: Swallowed Errors / Empty Catches

**Severity:** High
**Detection:** Claude judgment (regex too lossy for safe-catch detection).

## What to look for

Patterns that silently swallow errors so production failures become invisible:

1. **Empty catch blocks:** `catch (e) {}` or `catch {}`.
2. **No-op promise rejections:** `.catch(() => {})`, `.catch(() => null)`.
3. **Async event handlers without try/catch:** `onClick={async () => { await dangerousOp(); }}` — if `dangerousOp` throws, React will not surface the error.
4. **Catch blocks that only `console.log`** without rethrowing or reporting to an error service.

## True positives

```ts
try {
  await criticalOperation();
} catch (e) {
  // ← nothing here = silent failure in production
}
```

```ts
fetch("/api/save").catch(() => {});  // ← user never knows the save failed
```

## False positives to skip

- Catch blocks that genuinely just suppress an expected, non-actionable error (e.g., aborting an in-flight `fetch` on unmount). These should have a comment explaining why.
- Catches that re-throw a wrapped error after logging — that's deliberate transformation, not swallowing.

## Suggested fix

At minimum, log the error AND either rethrow or surface it to the user:

```diff
  try {
    await criticalOperation();
  } catch (e) {
-   // empty
+   console.error("criticalOperation failed:", e);
+   throw e;  // or: report to Sentry / display to user
  }
```

For async event handlers, wrap the body in try/catch and show the user a toast / inline error.
