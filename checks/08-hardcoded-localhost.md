# Check 08: Hardcoded localhost / Dev URLs

**Severity:** High
**Detection:** Scripted (`scripts/scan-localhost-urls.sh`).

## What to look for

URLs hard-coded as `http://localhost:*` or `http://127.0.0.1:*` in source files. In production these point at nothing, causing requests to fail silently or hang.

## True positives

```ts
const API = "http://localhost:3001";
fetch(`${API}/data`);
```

```ts
const DB_URL = "http://localhost:5432/mydb";
```

## False positives to skip

- Test files (`*.test.*`, `*.spec.*`, `__tests__/`) — the scanner already excludes these.
- Storybook config, jest config, similar local-dev configs.
- Strings that are clearly fallbacks: `process.env.API_URL ?? "http://localhost:3000"`.

## Suggested fix

Move to env var with a sensible local default:

```diff
- const API = "http://localhost:3001";
+ const API = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:3001";
```

For server-only URLs (database, internal services), omit the `NEXT_PUBLIC_` prefix and read it server-side.
