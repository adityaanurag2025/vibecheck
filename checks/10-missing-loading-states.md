# Check 10: Missing Loading States

**Severity:** Medium
**Detection:** Claude judgment + filesystem check.

## What to look for

Two patterns:

1. **No `app/loading.tsx`** at the project root — without it, Next.js shows a blank screen during navigation to async pages.
2. **Client components with bare `useEffect` fetches** where the JSX renders nothing useful while the fetch is in flight (no skeleton, no spinner, no "Loading...").

## True positives

```tsx
"use client";
const [data, setData] = useState(null);
useEffect(() => { fetch(...).then(setData); }, []);
return <ul>{data?.map(...)}</ul>;  // ← blank screen during fetch
```

App Router project missing `app/loading.tsx`.

## False positives to skip

- Components using React Query / SWR with `isLoading` / `isPending` handling.
- Components using React Suspense + a `<Suspense fallback={...}>` boundary in a parent.
- Static content (no fetching).

## Suggested fix

Add a root `loading.tsx`:

```tsx
// app/loading.tsx
export default function Loading() {
  return <div>Loading...</div>;
}
```

For client-side fetches, add explicit loading state:

```diff
+ const [loading, setLoading] = useState(true);
  useEffect(() => {
-   fetch(...).then(setData);
+   fetch(...).then(setData).finally(() => setLoading(false));
  }, []);
+ if (loading) return <div>Loading...</div>;
```
