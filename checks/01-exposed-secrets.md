# Check 01: Exposed Secrets in Source

**Severity:** Critical
**Detection:** Scripted (`scripts/scan-secrets.sh`) + Claude judgment for generic patterns.

## What to look for

Hardcoded API keys, tokens, passwords, or other credentials in committed source files. The scanner catches common formats (OpenAI, Anthropic, GitHub, Google, Slack, AWS). Also flag:

- Generic-looking secret patterns: long random-looking strings assigned to constants named `*KEY`, `*TOKEN`, `*SECRET`, `*PASSWORD`
- Database connection strings with embedded passwords: `postgres://user:pass@host/db`
- Basic-auth credentials in URLs: `https://user:pass@api.example.com`

## True positives

```ts
const apiKey = "sk-proj-abc123...";
const DATABASE_URL = "postgres://admin:hunter2@host/db";
const token = "ghp_realactualtoken...";
```

## False positives to skip

- `process.env.OPENAI_API_KEY` — referencing env, not hardcoding.
- Strings clearly marked fake: `"sk-EXAMPLE..."`, `"<your-key-here>"`, `"YOUR_KEY"`, `"xxxxxxxx"`.
- Example/placeholder strings in `.md`, `.example`, `.sample` files.

## Suggested fix

Move the value to an env var, reference via `process.env.VAR_NAME`, and **rotate the leaked credential immediately** — assume it's compromised the moment it touched source control.

```diff
- const apiKey = "sk-proj-abc123";
+ const apiKey = process.env.OPENAI_API_KEY;
```
