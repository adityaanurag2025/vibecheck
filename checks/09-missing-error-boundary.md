# Check 09: Missing Error Boundaries (error.tsx)

**Severity:** Medium
**Detection:** Claude — check filesystem for `app/**/error.tsx`.

## What to look for

In Next.js App Router, `error.tsx` files create per-segment error boundaries. Without them, a thrown error in a Server Component shows a blank screen or a generic Next.js error page in production.

Check:
- Project has at least one `app/error.tsx` (the root error boundary).
- Routes that fetch data or run risky logic (anything with `await`) have their own `error.tsx` siblings in their segment.

## True positives

- App Router project (`app/` directory exists) with no `app/error.tsx`.
- A route segment that fetches data (`app/dashboard/page.tsx`) without an `app/dashboard/error.tsx`.

## False positives to skip

- Static pages (no data fetching, no `async` work) — error.tsx is overkill.
- Server-action-only routes — error handling happens at the action level.

## Suggested fix

Add at least a root `error.tsx`:

```tsx
// app/error.tsx
"use client";

export default function Error({ error, reset }: { error: Error; reset: () => void }) {
  return (
    <div>
      <h2>Something went wrong</h2>
      <p>{error.message}</p>
      <button onClick={reset}>Try again</button>
    </div>
  );
}
```
