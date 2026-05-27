# Check 12: Missing not-found.tsx (404 Page)

**Severity:** Medium
**Detection:** Claude — check filesystem for `app/not-found.tsx`.

## What to look for

App Router projects without an `app/not-found.tsx`. Without it, unmatched routes render Next.js' default 404 — functional but unbranded, often confusing for users.

## True positives

- Project has `app/` directory but no `app/not-found.tsx`.

## False positives to skip

- Single-page apps where every URL resolves to the same `page.tsx` (rare in App Router).
- Projects that customize 404 via middleware redirects.

## Suggested fix

Add a basic `not-found.tsx`:

```tsx
// app/not-found.tsx
import Link from "next/link";

export default function NotFound() {
  return (
    <div>
      <h2>Page not found</h2>
      <p>The page you're looking for doesn't exist.</p>
      <Link href="/">Go home</Link>
    </div>
  );
}
```
