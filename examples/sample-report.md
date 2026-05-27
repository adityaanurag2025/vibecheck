# vibecheck report

**Project:** demo-app
**Scanned:** 2026-05-28 14:32
**Score:** 0.0 / 10 — Critical — Do Not Deploy

## TL;DR

- 🔴 5 Critical
- 🟠 8 High
- 🟡 5 Medium

## Top 3 things to fix first

1. Hardcoded OpenAI API key in `lib/ai.ts:2` — rotate it now, it's public.
2. `.env` and `.env.local` committed to git — secrets are in your history.
3. `DELETE /api/todos` and `Server Action deleteUser` accept any request with no auth check — anyone can delete anything.

---

## 🔴 Critical

### 1. Hardcoded OpenAI API key in `lib/ai.ts:2`

**What's wrong:** A literal `sk-proj-...` token is committed to source. Anyone with repo access — including the entire internet, if this repo is public — has your OpenAI account.

**Suggested fix:** Move to `process.env.OPENAI_API_KEY`, add to `.env.local`, and **rotate the leaked key immediately**.

```diff
- const OPENAI_KEY = "sk-proj-fake-but-realistically-formatted-1234567890abcdef";
+ const OPENAI_KEY = process.env.OPENAI_API_KEY;
```

### 2. Hardcoded GitHub token in `app/api/secret/route.ts:5`

**What's wrong:** A `ghp_...` token is hardcoded AND returned to anyone who hits the endpoint. Rotate it and remove the endpoint.

**Suggested fix:** Move to env, add auth, and stop returning admin tokens via public APIs.

### 3. `.env` not in `.gitignore`

**What's wrong:** The `.env` file exists and is tracked by git. Anything you put in it gets committed.

**Suggested fix:** Add `.env` and `.env.*` to `.gitignore`, then `git rm --cached .env`, then rotate every secret it contained.

### 4. `.env.local` not in `.gitignore`

**What's wrong:** Same as above — `.env.local` is also being tracked.

**Suggested fix:** Same fix. Both files should be ignored.

### 5. `dangerouslySetInnerHTML` with network-fetched content in `app/dashboard/page.tsx:16`

**What's wrong:** The component fetches HTML from `/api/content` and renders it directly. If that endpoint ever returns user-controlled content, this is an XSS vulnerability.

**Suggested fix:** Sanitize with DOMPurify before rendering, or render as text / markdown.

---

## 🟠 High

### 6. Missing auth on `DELETE /api/todos` in `app/api/todos/route.ts:15`

**What's wrong:** The DELETE handler accepts any request and deletes whatever `id` is in the body. No session check, no rate limit.

**Suggested fix:** Call `await auth()` at the top of the handler, return 401 if no session.

### 7. Missing auth on `POST /api/todos` in `app/api/todos/route.ts:9`

**What's wrong:** Same as above for the POST handler — anyone can create todos for anyone.

### 8. Missing auth on Server Action `deleteUser` in `app/dashboard/actions.ts:5`

**What's wrong:** `"use server"` Server Action deletes users with no session check. Server Actions are callable from anywhere a CSRF token can be obtained.

### 9. Missing input validation on `POST /api/todos` in `app/api/todos/route.ts:10`

**What's wrong:** `await req.json()` returns `unknown`, but the result is passed directly to `saveToDb()`. A malformed body will cause DB errors at best, injection at worst.

**Suggested fix:** Validate with `zod.parse()` before using.

### 10. Missing input validation in Server Action `deleteUser` in `app/dashboard/actions.ts:6`

**What's wrong:** `formData.get("userId") as string` is a cast, not a check. The value can be `null`, a `File`, or any string — including SQL injection attempts.

### 11. `NEXT_PUBLIC_DB_PASSWORD` in `.env.local:1`

**What's wrong:** Names starting with `NEXT_PUBLIC_` are bundled into the browser JavaScript. Any password / secret with this prefix is published to every visitor of your site.

**Suggested fix:** Rename to `DB_PASSWORD` and read it only from server code.

### 12. `NEXT_PUBLIC_API_SECRET` in `.env.local:2`

**What's wrong:** Same as above.

### 13. Hardcoded `http://localhost:5432` in `lib/db.ts:2`

**What's wrong:** This URL points at nothing in production.

**Suggested fix:** Replace with `process.env.DATABASE_URL`.

---

## 🟡 Medium

### 14. Empty catch in `lib/auth.ts:9`

**What's wrong:** `catch (e) {}` silently swallows authentication failures. If auth breaks in prod, you'll never know.

### 15. Swallowed promise rejection in `lib/auth.ts:16`

**What's wrong:** `.catch(() => {})` means logout failures are invisible.

### 16. `console.log` in `lib/auth.ts:5`

**What's wrong:** Logs the auth token to the browser console. Anyone with devtools can copy it.

### 17. Missing `app/error.tsx`

**What's wrong:** Thrown errors in Server Components will render the default Next.js error page instead of a branded fallback.

### 18. Missing `app/loading.tsx` and `app/not-found.tsx`

**What's wrong:** Navigations to slow async pages show a blank screen. Unmatched routes show Next.js' generic 404.

---

## What vibecheck did NOT check

vibecheck v1 audits 12 specific production-readiness issues common in AI-generated Next.js apps. It does NOT check for: test coverage, performance, accessibility, SEO, migrations, race conditions, or business-logic correctness.

A clean vibecheck report means you've cleared the most common landmines, NOT that your app is production-perfect.

---

*Generated by [vibecheck](https://github.com/YOUR_USERNAME/vibecheck).*
