# vibecheck v1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship vibecheck v1 — a Claude Code skill that audits AI-generated Next.js App Router projects against a curated checklist of 12 production-readiness issues, producing a severity-tiered markdown report.

**Architecture:** Pure markdown skill (no Node deps). `SKILL.md` orchestrates Claude. ~6 bash helper scripts in `scripts/` handle mechanically-detectable patterns. 12 markdown files in `checks/` define judgment-based checks. A deliberately-broken Next.js demo in `examples/demo-app/` exercises every check and is shipped with the repo for testing + README screenshots.

**Tech Stack:** Bash (POSIX + bash 3.2 compatible for macOS), Markdown, Next.js 14 App Router (demo only). No npm install required for the skill itself.

---

## File Inventory

The plan creates the following files under `/Users/adityaanurag/projects/vibecheck/`:

**Root:**
- `LICENSE` — MIT
- `.gitignore` — node_modules/, vibecheck-report.md (don't commit user reports)
- `README.md` — marketing-facing, install, demo, founder note
- `install.sh` — one-line installer
- `SKILL.md` — orchestration brain

**`checks/` (12 files):**
- `01-exposed-secrets.md`, `02-env-not-gitignored.md`, `03-missing-auth.md`, `04-dangerous-html.md`
- `05-missing-input-validation.md`, `06-leaked-server-secrets.md`, `07-swallowed-errors.md`, `08-hardcoded-localhost.md`
- `09-missing-error-boundary.md`, `10-missing-loading-states.md`, `11-console-log-in-prod.md`, `12-missing-not-found.md`

**`scripts/` (6 files):**
- `scan-secrets.sh`, `scan-env-files.sh`, `scan-dangerous-html.sh`
- `scan-console-logs.sh`, `scan-localhost-urls.sh`, `scan-public-env-leaks.sh`

**`templates/`:**
- `report-template.md`

**`examples/demo-app/`** (deliberately-broken Next.js project):
- `package.json`, `tsconfig.json`, `next.config.js`, `.gitignore` (deliberately missing `.env*`)
- `.env`, `.env.local` (deliberately committed, deliberately contain secrets)
- `app/layout.tsx`, `app/page.tsx`
- `app/api/todos/route.ts`, `app/api/secret/route.ts`
- `app/dashboard/page.tsx`, `app/dashboard/actions.ts`
- `lib/ai.ts`, `lib/db.ts`, `lib/auth.ts`
- `components/PublicConfig.tsx`
- `README.md` (warns "do not deploy")
- **Intentionally absent**: `app/error.tsx`, `app/loading.tsx`, `app/not-found.tsx`

**`examples/`:**
- `sample-report.md` — output of running vibecheck on `demo-app/`

---

## Task 1: Project foundation

**Files:**
- Create: `/Users/adityaanurag/projects/vibecheck/LICENSE`
- Create: `/Users/adityaanurag/projects/vibecheck/.gitignore`
- Create: `/Users/adityaanurag/projects/vibecheck/README.md` (skeleton — full README later)

- [ ] **Step 1: Create LICENSE (MIT)**

Create `/Users/adityaanurag/projects/vibecheck/LICENSE`:

```
MIT License

Copyright (c) 2026 Aditya Anurag

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

- [ ] **Step 2: Create .gitignore**

Create `/Users/adityaanurag/projects/vibecheck/.gitignore`:

```
# Node (in case anyone adds it later)
node_modules/

# vibecheck output — users shouldn't commit their own audit reports into our repo
vibecheck-report.md

# OS
.DS_Store
Thumbs.db

# Editors
.vscode/
.idea/
*.swp
```

- [ ] **Step 3: Create README skeleton**

Create `/Users/adityaanurag/projects/vibecheck/README.md`:

```markdown
# vibecheck

> Find out what'll break in production, before production does.

A Claude Code skill that audits AI-generated Next.js apps for the 12 things that always go wrong.

**Status:** Under construction. Full README + demo coming soon.
```

This is a placeholder — Task 19 replaces it with the full marketing README.

- [ ] **Step 4: Commit**

```bash
cd /Users/adityaanurag/projects/vibecheck
git add LICENSE .gitignore README.md
git commit -m "chore: project foundation (license, gitignore, readme skeleton)"
```

---

## Task 2: Demo app — shell

**Files:**
- Create: `examples/demo-app/package.json`
- Create: `examples/demo-app/tsconfig.json`
- Create: `examples/demo-app/next.config.js`
- Create: `examples/demo-app/.gitignore` (deliberately missing `.env*`)
- Create: `examples/demo-app/app/layout.tsx`
- Create: `examples/demo-app/app/page.tsx`
- Create: `examples/demo-app/README.md`

- [ ] **Step 1: Create package.json**

Create `examples/demo-app/package.json`:

```json
{
  "name": "demo-app",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start"
  },
  "dependencies": {
    "next": "14.2.0",
    "react": "^18",
    "react-dom": "^18"
  },
  "devDependencies": {
    "typescript": "^5",
    "@types/react": "^18",
    "@types/node": "^20"
  }
}
```

- [ ] **Step 2: Create tsconfig.json**

Create `examples/demo-app/tsconfig.json`:

```json
{
  "compilerOptions": {
    "target": "ES2017",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [{ "name": "next" }],
    "paths": { "@/*": ["./*"] }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
```

- [ ] **Step 3: Create next.config.js**

Create `examples/demo-app/next.config.js`:

```js
/** @type {import('next').NextConfig} */
module.exports = {};
```

- [ ] **Step 4: Create demo-app .gitignore (deliberately incomplete)**

Create `examples/demo-app/.gitignore`:

```
# Deliberately INCOMPLETE — vibecheck should flag missing .env* entries.
node_modules/
.next/
```

- [ ] **Step 5: Create app/layout.tsx**

Create `examples/demo-app/app/layout.tsx`:

```tsx
export const metadata = {
  title: "Demo App",
  description: "Deliberately broken Next.js app for vibecheck testing",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
```

- [ ] **Step 6: Create app/page.tsx**

Create `examples/demo-app/app/page.tsx`:

```tsx
export default function HomePage() {
  return (
    <main>
      <h1>Demo App — riddled with bugs on purpose</h1>
      <p>This app is a test fixture for vibecheck. Do not deploy.</p>
    </main>
  );
}
```

- [ ] **Step 7: Create demo-app README**

Create `examples/demo-app/README.md`:

```markdown
# Demo App for vibecheck

This is a deliberately-broken Next.js App Router project used to demonstrate vibecheck's audit capabilities. It contains true-positive instances of every check vibecheck runs.

**Do not deploy this app. Do not use any of the code as-is.**

Each bug is tagged with a `// BUG:` comment in source so you can see what each one demonstrates.

Run `vibecheck` from this directory to see all 12 checks fire.
```

- [ ] **Step 8: Commit**

```bash
cd /Users/adityaanurag/projects/vibecheck
git add examples/demo-app/
git commit -m "demo: scaffold demo Next.js app shell"
```

---

## Task 3: Demo app — Critical-tier bugs

**Files:**
- Create: `examples/demo-app/.env`
- Create: `examples/demo-app/.env.local`
- Create: `examples/demo-app/lib/ai.ts`
- Create: `examples/demo-app/app/api/secret/route.ts`

These files trigger checks 01 (exposed secrets), 02 (env not gitignored), and 04 (dangerous-html — added in Task 5).

- [ ] **Step 1: Create .env (committed on purpose, contains "secrets")**

Create `examples/demo-app/.env`:

```
DATABASE_URL=postgres://admin:hunter2@localhost:5432/db
INTERNAL_SLACK_TOKEN=xoxb-DEMO-NOT-A-REAL-SLACK-TOKEN
```

- [ ] **Step 2: Create .env.local (also committed on purpose)**

Create `examples/demo-app/.env.local`:

```
NEXT_PUBLIC_DB_PASSWORD=hunter2
NEXT_PUBLIC_API_SECRET=secret123abc
OPENAI_API_KEY=sk-proj-fake-but-realistic-1234567890abcdefghijklmnop
```

- [ ] **Step 3: Create lib/ai.ts (hardcoded OpenAI key)**

Create `examples/demo-app/lib/ai.ts`:

```ts
// BUG: hardcoded OpenAI API key
const OPENAI_KEY = "sk-proj-fake-but-realistically-formatted-1234567890abcdef";

export async function callLLM(prompt: string): Promise<unknown> {
  const res = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: { Authorization: `Bearer ${OPENAI_KEY}` },
    body: JSON.stringify({ prompt }),
  });
  return res.json();
}
```

- [ ] **Step 4: Create app/api/secret/route.ts (hardcoded GitHub token + no auth)**

Create `examples/demo-app/app/api/secret/route.ts`:

```ts
// BUG: hardcoded GitHub token
// BUG: returns admin credentials with no auth
import { NextResponse } from "next/server";

const ADMIN_TOKEN = "ghp_realfakelookinggithubtoken123456789012345678901";

export async function GET() {
  return NextResponse.json({ admin: ADMIN_TOKEN });
}
```

- [ ] **Step 5: Commit**

```bash
cd /Users/adityaanurag/projects/vibecheck
git add examples/demo-app/
git commit -m "demo: critical-tier bugs (exposed secrets, env files)"
```

---

## Task 4: Demo app — High-tier bugs

**Files:**
- Create: `examples/demo-app/lib/db.ts`
- Create: `examples/demo-app/lib/auth.ts`
- Create: `examples/demo-app/components/PublicConfig.tsx`
- Create: `examples/demo-app/app/api/todos/route.ts`
- Create: `examples/demo-app/app/dashboard/actions.ts`

- [ ] **Step 1: Create lib/db.ts (hardcoded localhost)**

Create `examples/demo-app/lib/db.ts`:

```ts
// BUG: hardcoded localhost in production code
export const DB_URL = "http://localhost:5432/mydb";

export async function getTodos(): Promise<unknown> {
  const res = await fetch(`${DB_URL}/todos`);
  return res.json();
}
```

- [ ] **Step 2: Create lib/auth.ts (swallowed errors + console.log)**

Create `examples/demo-app/lib/auth.ts`:

```ts
// BUG: console.log in production code
// BUG: swallowed errors via empty catch + .catch(() => {})

export async function authenticate(token: string): Promise<unknown> {
  console.log("Authenticating user with token:", token);
  try {
    const res = await fetch("/api/auth/verify", { headers: { Authorization: token } });
    return res.json();
  } catch (e) {
    // BUG: empty catch swallows the error
  }
  return null;
}

export function logout(): void {
  fetch("/api/auth/logout").catch(() => {}); // BUG: swallowed promise rejection
  console.log("Logged out");
}
```

- [ ] **Step 3: Create components/PublicConfig.tsx (leaks NEXT_PUBLIC_ secret)**

Create `examples/demo-app/components/PublicConfig.tsx`:

```tsx
// BUG: reading NEXT_PUBLIC_*PASSWORD on the client (it's bundled into the browser)
"use client";

export function PublicConfig() {
  const password = process.env.NEXT_PUBLIC_DB_PASSWORD;
  const secret = process.env.NEXT_PUBLIC_API_SECRET;
  return (
    <div>
      <p>Password: {password}</p>
      <p>Secret: {secret}</p>
    </div>
  );
}
```

- [ ] **Step 4: Create app/api/todos/route.ts (no auth + no validation)**

Create `examples/demo-app/app/api/todos/route.ts`:

```ts
// BUG: POST and DELETE mutate data with no auth check
// BUG: no input validation — body goes straight into "DB" calls
import { NextRequest, NextResponse } from "next/server";

export async function GET(): Promise<NextResponse> {
  return NextResponse.json({ todos: [] });
}

export async function POST(req: NextRequest): Promise<NextResponse> {
  const body = await req.json();
  const result = await saveToDb(body);
  return NextResponse.json(result);
}

export async function DELETE(req: NextRequest): Promise<NextResponse> {
  const { id } = await req.json();
  await deleteFromDb(id);
  return NextResponse.json({ ok: true });
}

declare function saveToDb(data: unknown): Promise<unknown>;
declare function deleteFromDb(id: unknown): Promise<void>;
```

- [ ] **Step 5: Create app/dashboard/actions.ts (Server Action without auth or validation)**

Create `examples/demo-app/app/dashboard/actions.ts`:

```ts
// BUG: Server Action mutates data with no session check
// BUG: formData fields are not validated before use
"use server";

export async function deleteUser(formData: FormData): Promise<void> {
  const userId = formData.get("userId") as string;
  await db.users.delete(userId);
}

declare const db: { users: { delete: (id: string) => Promise<void> } };
```

- [ ] **Step 6: Commit**

```bash
cd /Users/adityaanurag/projects/vibecheck
git add examples/demo-app/
git commit -m "demo: high-tier bugs (no auth, no validation, swallowed errors)"
```

---

## Task 5: Demo app — Medium-tier bugs

**Files:**
- Create: `examples/demo-app/app/dashboard/page.tsx`
- **Deliberately do NOT create:** `app/error.tsx`, `app/loading.tsx`, `app/not-found.tsx`

- [ ] **Step 1: Create app/dashboard/page.tsx (dangerouslySetInnerHTML + missing loading state)**

Create `examples/demo-app/app/dashboard/page.tsx`:

```tsx
// BUG: dangerouslySetInnerHTML with untrusted (network-fetched) content → XSS
// BUG: async fetch with no loading state — user sees blank screen
"use client";

import { useEffect, useState } from "react";

export default function Dashboard() {
  const [html, setHtml] = useState<string>("");

  useEffect(() => {
    fetch("/api/content")
      .then((r) => r.text())
      .then(setHtml);
  }, []);

  return <div dangerouslySetInnerHTML={{ __html: html }} />;
}
```

- [ ] **Step 2: Verify the App Router is missing error.tsx, loading.tsx, not-found.tsx**

```bash
cd /Users/adityaanurag/projects/vibecheck/examples/demo-app
ls app/
```

Expected output: should show `layout.tsx`, `page.tsx`, `api/`, `dashboard/` — but NOT `error.tsx`, `loading.tsx`, or `not-found.tsx`. Their absence is what vibecheck checks 09, 10, and 12 will catch.

- [ ] **Step 3: Commit**

```bash
cd /Users/adityaanurag/projects/vibecheck
git add examples/demo-app/
git commit -m "demo: medium-tier bugs (dangerous html, missing error/loading/not-found)"
```

---

## Task 6: Scanner — scan-secrets.sh

**Files:**
- Create: `scripts/scan-secrets.sh`

- [ ] **Step 1: Create scan-secrets.sh**

Create `/Users/adityaanurag/projects/vibecheck/scripts/scan-secrets.sh`:

```bash
#!/usr/bin/env bash
# scan-secrets.sh — find hardcoded API keys/tokens in source files.
# Output format: [SEVERITY] check-name: file:line — message
set -euo pipefail

scan() {
  local name="$1"
  local pattern="$2"
  grep -rEn \
    --include='*.ts' --include='*.tsx' --include='*.js' --include='*.jsx' --include='*.json' \
    --exclude-dir=node_modules --exclude-dir=.next --exclude-dir=.git --exclude-dir=dist --exclude-dir=build \
    --exclude='*.test.*' --exclude='*.spec.*' \
    "$pattern" . 2>/dev/null \
    | while IFS=: read -r file line _; do
        printf '[CRITICAL] exposed-secrets: %s:%s — Hardcoded %s pattern detected\n' "${file#./}" "$line" "$name"
      done || true
}

scan 'OpenAI key'      'sk-[a-zA-Z0-9_-]{20,}'
scan 'Anthropic key'   'sk-ant-[a-zA-Z0-9_-]{20,}'
scan 'GitHub token'    'gh[ps]_[a-zA-Z0-9]{36}'
scan 'Google API key'  'AIza[0-9A-Za-z_-]{35}'
scan 'Slack token'     'xox[bpoa]-[0-9a-zA-Z-]+'
scan 'AWS access key'  'AKIA[0-9A-Z]{16}'
```

- [ ] **Step 2: Make it executable**

```bash
cd /Users/adityaanurag/projects/vibecheck
chmod +x scripts/scan-secrets.sh
```

- [ ] **Step 3: Run it against demo-app and verify expected findings**

```bash
cd /Users/adityaanurag/projects/vibecheck/examples/demo-app
bash ../../scripts/scan-secrets.sh
```

Expected: at least 2 findings — one OpenAI key (`lib/ai.ts`) and one GitHub token (`app/api/secret/route.ts`). Output should look like:

```
[CRITICAL] exposed-secrets: lib/ai.ts:2 — Hardcoded OpenAI key pattern detected
[CRITICAL] exposed-secrets: app/api/secret/route.ts:5 — Hardcoded GitHub token pattern detected
```

If you get zero findings, the scanner regex or the demo fixtures are wrong — debug before continuing.

- [ ] **Step 4: Commit**

```bash
cd /Users/adityaanurag/projects/vibecheck
git add scripts/scan-secrets.sh
git commit -m "scanner: detect hardcoded API keys (OpenAI, Anthropic, GitHub, Google, Slack, AWS)"
```

---

## Task 7: Scanner — scan-env-files.sh

**Files:**
- Create: `scripts/scan-env-files.sh`

- [ ] **Step 1: Create scan-env-files.sh**

Create `/Users/adityaanurag/projects/vibecheck/scripts/scan-env-files.sh`:

```bash
#!/usr/bin/env bash
# scan-env-files.sh — find .env* files that aren't in .gitignore.
set -euo pipefail

GITIGNORE_CONTENT=""
[[ -f .gitignore ]] && GITIGNORE_CONTENT=$(cat .gitignore)

ENV_FILES=(.env .env.local .env.development .env.production .env.development.local .env.production.local .env.test .env.test.local)

for file in "${ENV_FILES[@]}"; do
  [[ -f "$file" ]] || continue
  # Check if file (or a glob covering it) is in .gitignore.
  if ! printf '%s\n' "$GITIGNORE_CONTENT" | grep -qE "^${file}$|^\.env\*?$|^\.env\.\*$|^\*\.env$"; then
    printf '[CRITICAL] env-not-gitignored: %s — Environment file is tracked by git (or not gitignored). Secrets inside will be committed.\n' "$file"
  fi
done
```

- [ ] **Step 2: Make it executable**

```bash
chmod +x /Users/adityaanurag/projects/vibecheck/scripts/scan-env-files.sh
```

- [ ] **Step 3: Verify against demo-app**

```bash
cd /Users/adityaanurag/projects/vibecheck/examples/demo-app
bash ../../scripts/scan-env-files.sh
```

Expected: 2 findings (`.env` and `.env.local`), each printed once.

```
[CRITICAL] env-not-gitignored: .env — Environment file is tracked by git ...
[CRITICAL] env-not-gitignored: .env.local — Environment file is tracked by git ...
```

- [ ] **Step 4: Commit**

```bash
cd /Users/adityaanurag/projects/vibecheck
git add scripts/scan-env-files.sh
git commit -m "scanner: detect .env files missing from .gitignore"
```

---

## Task 8: Scanner — scan-dangerous-html.sh

**Files:**
- Create: `scripts/scan-dangerous-html.sh`

- [ ] **Step 1: Create scan-dangerous-html.sh**

Create `/Users/adityaanurag/projects/vibecheck/scripts/scan-dangerous-html.sh`:

```bash
#!/usr/bin/env bash
# scan-dangerous-html.sh — find dangerouslySetInnerHTML usage.
set -euo pipefail

grep -rEn \
  --include='*.tsx' --include='*.jsx' \
  --exclude-dir=node_modules --exclude-dir=.next --exclude-dir=.git --exclude-dir=dist --exclude-dir=build \
  --exclude='*.test.*' --exclude='*.spec.*' \
  'dangerouslySetInnerHTML' . 2>/dev/null \
  | while IFS=: read -r file line _; do
      printf '[CRITICAL] dangerous-html: %s:%s — dangerouslySetInnerHTML used. Ensure content is sanitized (DOMPurify or equivalent) before rendering, especially if sourced from user input or network.\n' "${file#./}" "$line"
    done || true
```

- [ ] **Step 2: Make executable + verify**

```bash
chmod +x /Users/adityaanurag/projects/vibecheck/scripts/scan-dangerous-html.sh
cd /Users/adityaanurag/projects/vibecheck/examples/demo-app
bash ../../scripts/scan-dangerous-html.sh
```

Expected: 1 finding in `app/dashboard/page.tsx`.

- [ ] **Step 3: Commit**

```bash
cd /Users/adityaanurag/projects/vibecheck
git add scripts/scan-dangerous-html.sh
git commit -m "scanner: detect dangerouslySetInnerHTML usage"
```

---

## Task 9: Scanner — scan-console-logs.sh

**Files:**
- Create: `scripts/scan-console-logs.sh`

- [ ] **Step 1: Create scan-console-logs.sh**

Create `/Users/adityaanurag/projects/vibecheck/scripts/scan-console-logs.sh`:

```bash
#!/usr/bin/env bash
# scan-console-logs.sh — find console.log/debug/info in source (not test) files.
set -euo pipefail

grep -rEn \
  --include='*.ts' --include='*.tsx' --include='*.js' --include='*.jsx' \
  --exclude-dir=node_modules --exclude-dir=.next --exclude-dir=.git --exclude-dir=dist --exclude-dir=build --exclude-dir=tests --exclude-dir=__tests__ \
  --exclude='*.test.*' --exclude='*.spec.*' \
  'console\.(log|debug|info)\s*\(' . 2>/dev/null \
  | while IFS=: read -r file line _; do
      printf '[MEDIUM] console-log-in-prod: %s:%s — console.log/debug/info call in source. Remove or guard with `if (process.env.NODE_ENV !== "production")` before deploying.\n' "${file#./}" "$line"
    done || true
```

- [ ] **Step 2: Make executable + verify**

```bash
chmod +x /Users/adityaanurag/projects/vibecheck/scripts/scan-console-logs.sh
cd /Users/adityaanurag/projects/vibecheck/examples/demo-app
bash ../../scripts/scan-console-logs.sh
```

Expected: 2 findings in `lib/auth.ts` (both `console.log` calls).

- [ ] **Step 3: Commit**

```bash
cd /Users/adityaanurag/projects/vibecheck
git add scripts/scan-console-logs.sh
git commit -m "scanner: detect console.log/debug/info in production code"
```

---

## Task 10: Scanner — scan-localhost-urls.sh

**Files:**
- Create: `scripts/scan-localhost-urls.sh`

- [ ] **Step 1: Create scan-localhost-urls.sh**

Create `/Users/adityaanurag/projects/vibecheck/scripts/scan-localhost-urls.sh`:

```bash
#!/usr/bin/env bash
# scan-localhost-urls.sh — find hardcoded localhost / 127.0.0.1 URLs.
set -euo pipefail

grep -rEn \
  --include='*.ts' --include='*.tsx' --include='*.js' --include='*.jsx' --include='*.json' \
  --exclude-dir=node_modules --exclude-dir=.next --exclude-dir=.git --exclude-dir=dist --exclude-dir=build --exclude-dir=tests --exclude-dir=__tests__ \
  --exclude='*.test.*' --exclude='*.spec.*' \
  'https?://(localhost|127\.0\.0\.1)' . 2>/dev/null \
  | while IFS=: read -r file line _; do
      printf '[HIGH] hardcoded-localhost: %s:%s — Hardcoded localhost/127.0.0.1 URL in source. Replace with `process.env.NEXT_PUBLIC_API_URL` (or server-only env var) so it works in production.\n' "${file#./}" "$line"
    done || true
```

- [ ] **Step 2: Make executable + verify**

```bash
chmod +x /Users/adityaanurag/projects/vibecheck/scripts/scan-localhost-urls.sh
cd /Users/adityaanurag/projects/vibecheck/examples/demo-app
bash ../../scripts/scan-localhost-urls.sh
```

Expected: 1 finding in `lib/db.ts`.

- [ ] **Step 3: Commit**

```bash
cd /Users/adityaanurag/projects/vibecheck
git add scripts/scan-localhost-urls.sh
git commit -m "scanner: detect hardcoded localhost/127.0.0.1 URLs"
```

---

## Task 11: Scanner — scan-public-env-leaks.sh

**Files:**
- Create: `scripts/scan-public-env-leaks.sh`

- [ ] **Step 1: Create scan-public-env-leaks.sh**

Create `/Users/adityaanurag/projects/vibecheck/scripts/scan-public-env-leaks.sh`:

```bash
#!/usr/bin/env bash
# scan-public-env-leaks.sh — flag NEXT_PUBLIC_* vars whose name suggests they contain secrets.
set -euo pipefail

# Scan .env* files for suspicious NEXT_PUBLIC_ var declarations.
for envfile in .env .env.local .env.development .env.production .env.development.local .env.production.local; do
  [[ -f "$envfile" ]] || continue
  grep -nE '^NEXT_PUBLIC_[A-Z_]*(SECRET|KEY|TOKEN|PASSWORD|PRIVATE)' "$envfile" 2>/dev/null \
    | while IFS=: read -r line content; do
        var_name=$(printf '%s' "$content" | sed -E 's/=.*//')
        printf '[HIGH] leaked-server-secret: %s:%s — %s is exposed to the browser via the NEXT_PUBLIC_ prefix. Variables that look like secrets (KEY/TOKEN/SECRET/PASSWORD) should be server-only.\n' "$envfile" "$line" "$var_name"
      done || true
done

# Scan source code for process.env.NEXT_PUBLIC_*SECRET-ish reads.
grep -rEn \
  --include='*.ts' --include='*.tsx' --include='*.js' --include='*.jsx' \
  --exclude-dir=node_modules --exclude-dir=.next --exclude-dir=.git --exclude-dir=dist --exclude-dir=build \
  --exclude='*.test.*' --exclude='*.spec.*' \
  'process\.env\.NEXT_PUBLIC_[A-Z_]*(SECRET|KEY|TOKEN|PASSWORD|PRIVATE)' . 2>/dev/null \
  | while IFS=: read -r file line _; do
      printf '[HIGH] leaked-server-secret: %s:%s — Reading NEXT_PUBLIC_*SECRET/KEY/TOKEN/PASSWORD from code. The value ships in the browser bundle.\n' "${file#./}" "$line"
    done || true
```

- [ ] **Step 2: Make executable + verify**

```bash
chmod +x /Users/adityaanurag/projects/vibecheck/scripts/scan-public-env-leaks.sh
cd /Users/adityaanurag/projects/vibecheck/examples/demo-app
bash ../../scripts/scan-public-env-leaks.sh
```

Expected: at least 4 findings total — 2 from `.env.local` (`NEXT_PUBLIC_DB_PASSWORD`, `NEXT_PUBLIC_API_SECRET`) and 2 from `components/PublicConfig.tsx` (both reads).

- [ ] **Step 3: Commit**

```bash
cd /Users/adityaanurag/projects/vibecheck
git add scripts/scan-public-env-leaks.sh
git commit -m "scanner: detect NEXT_PUBLIC_ vars that leak server secrets"
```

---

## Task 12: Check definitions — Critical tier

**Files:**
- Create: `checks/01-exposed-secrets.md`
- Create: `checks/02-env-not-gitignored.md`
- Create: `checks/03-missing-auth.md`
- Create: `checks/04-dangerous-html.md`

Each check file is a self-contained instruction set Claude reads when running the skill — what to look for, what to ignore, how to suggest a fix.

- [ ] **Step 1: Create 01-exposed-secrets.md**

Create `/Users/adityaanurag/projects/vibecheck/checks/01-exposed-secrets.md`:

```markdown
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
```

- [ ] **Step 2: Create 02-env-not-gitignored.md**

Create `/Users/adityaanurag/projects/vibecheck/checks/02-env-not-gitignored.md`:

```markdown
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
```

- [ ] **Step 3: Create 03-missing-auth.md**

Create `/Users/adityaanurag/projects/vibecheck/checks/03-missing-auth.md`:

```markdown
# Check 03: Missing Auth on Protected Endpoints

**Severity:** Critical
**Detection:** Claude judgment. No scanner — auth patterns vary too much.

## What to look for

API Route handlers (`app/api/**/route.ts`) and Server Actions (`"use server"` exports) that **mutate data** or **return sensitive data** without a session/auth check.

For each route handler or Server Action:
1. Identify the HTTP method (GET / POST / PUT / DELETE) or whether it's a Server Action.
2. Identify whether the function mutates data, returns sensitive data, or only reads public data.
3. Identify whether the function checks auth — looks for calls like `getServerSession()`, `auth()`, `requireUser()`, `cookies().get("session")` followed by validation, or middleware that runs first.

Flag if: it mutates or returns sensitive data AND has no visible auth check.

## True positives

```ts
// app/api/users/route.ts
export async function DELETE(req: Request) {
  const { id } = await req.json();
  await db.users.delete(id);  // ← no auth check before destructive mutation
  return Response.json({ ok: true });
}
```

```ts
// app/actions.ts
"use server";
export async function deleteUser(formData: FormData) {
  await db.users.delete(formData.get("id") as string);  // ← no session check
}
```

## False positives to skip

- GET endpoints that return clearly public data (e.g., public blog posts, marketing content).
- Routes where auth is enforced by `middleware.ts` at the project root — verify middleware coverage before flagging.
- Routes that explicitly comment-document being public.

## Suggested fix

Add an auth check at the top of the handler:

```ts
import { auth } from "@/lib/auth";

export async function DELETE(req: Request) {
  const session = await auth();
  if (!session?.user) {
    return Response.json({ error: "Unauthorized" }, { status: 401 });
  }
  // ... rest of handler
}
```

For Server Actions, the pattern is identical — call `auth()` first, return early if no session.
```

- [ ] **Step 4: Create 04-dangerous-html.md**

Create `/Users/adityaanurag/projects/vibecheck/checks/04-dangerous-html.md`:

```markdown
# Check 04: dangerouslySetInnerHTML Without Sanitization

**Severity:** Critical
**Detection:** Scripted (`scripts/scan-dangerous-html.sh`) + Claude judgment to check for sanitization in surrounding code.

## What to look for

Any use of `dangerouslySetInnerHTML={{ __html: ... }}` in `.tsx` / `.jsx` files. For each occurrence, check whether the HTML content has been passed through a sanitizer (`DOMPurify.sanitize`, `sanitize-html`, etc.) before being rendered.

## True positives

```tsx
const [html, setHtml] = useState("");
useEffect(() => { fetch("/api/content").then(r => r.text()).then(setHtml); }, []);
return <div dangerouslySetInnerHTML={{ __html: html }} />;  // ← XSS risk
```

```tsx
return <div dangerouslySetInnerHTML={{ __html: userBio }} />;  // ← XSS if userBio comes from user input
```

## False positives to skip

- Content is sanitized first: `dangerouslySetInnerHTML={{ __html: DOMPurify.sanitize(html) }}`.
- Content is a hard-coded constant string defined in the same file (not from user input or network).
- Use in `<script>` tags for structured data (JSON-LD) — this is a recognized Next.js pattern.

## Suggested fix

Install and use a sanitizer:

```bash
npm install isomorphic-dompurify
```

```diff
+ import DOMPurify from "isomorphic-dompurify";
- <div dangerouslySetInnerHTML={{ __html: html }} />
+ <div dangerouslySetInnerHTML={{ __html: DOMPurify.sanitize(html) }} />
```

Better alternative when possible: render content as text (`<div>{text}</div>`) or as Markdown via `react-markdown`, which doesn't allow raw HTML by default.
```

- [ ] **Step 5: Commit**

```bash
cd /Users/adityaanurag/projects/vibecheck
git add checks/
git commit -m "checks: critical-tier definitions (secrets, env, auth, dangerous-html)"
```

---

## Task 13: Check definitions — High tier

**Files:**
- Create: `checks/05-missing-input-validation.md`
- Create: `checks/06-leaked-server-secrets.md`
- Create: `checks/07-swallowed-errors.md`
- Create: `checks/08-hardcoded-localhost.md`

- [ ] **Step 1: Create 05-missing-input-validation.md**

Create `/Users/adityaanurag/projects/vibecheck/checks/05-missing-input-validation.md`:

```markdown
# Check 05: Missing Input Validation on Server Actions / API Routes

**Severity:** High
**Detection:** Claude judgment.

## What to look for

API Route handlers and Server Actions that read request bodies, query params, or `formData` and pass values into database calls, external API calls, or filesystem operations **without validating** the shape and content of those values first.

Look for:
- `await req.json()` whose result is destructured and used directly.
- `formData.get(...)` cast directly to a type and used.
- Query params (`searchParams.get(...)`) inserted into queries without checks.

The presence of a validation library (`zod`, `yup`, `valibot`, `joi`, `ajv`) or explicit manual checks (`typeof`, `instanceof`, length checks) is enough to NOT flag.

## True positives

```ts
export async function POST(req: NextRequest) {
  const body = await req.json();
  await saveToDb(body);  // ← body shape unknown, fed directly to DB
}
```

```ts
"use server";
export async function deleteUser(formData: FormData) {
  const userId = formData.get("userId") as string;  // ← may be null, may be a File, not validated
  await db.users.delete(userId);
}
```

## False positives to skip

- Body is validated with `zod.parse(...)`, `safeParse`, similar.
- Manual checks: `if (typeof body.id !== "string") return error(400);`.
- The endpoint only reads (no mutation) and the unvalidated value is just echoed back.

## Suggested fix

Add a schema with `zod`:

```ts
import { z } from "zod";

const Todo = z.object({
  title: z.string().min(1).max(200),
  done: z.boolean().optional(),
});

export async function POST(req: NextRequest) {
  const parsed = Todo.safeParse(await req.json());
  if (!parsed.success) {
    return NextResponse.json({ error: parsed.error.flatten() }, { status: 400 });
  }
  await saveToDb(parsed.data);
}
```
```

- [ ] **Step 2: Create 06-leaked-server-secrets.md**

Create `/Users/adityaanurag/projects/vibecheck/checks/06-leaked-server-secrets.md`:

```markdown
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
```

- [ ] **Step 3: Create 07-swallowed-errors.md**

Create `/Users/adityaanurag/projects/vibecheck/checks/07-swallowed-errors.md`:

```markdown
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
```

- [ ] **Step 4: Create 08-hardcoded-localhost.md**

Create `/Users/adityaanurag/projects/vibecheck/checks/08-hardcoded-localhost.md`:

```markdown
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
```

- [ ] **Step 5: Commit**

```bash
cd /Users/adityaanurag/projects/vibecheck
git add checks/
git commit -m "checks: high-tier definitions (validation, public-secrets, errors, localhost)"
```

---

## Task 14: Check definitions — Medium tier

**Files:**
- Create: `checks/09-missing-error-boundary.md`
- Create: `checks/10-missing-loading-states.md`
- Create: `checks/11-console-log-in-prod.md`
- Create: `checks/12-missing-not-found.md`

- [ ] **Step 1: Create 09-missing-error-boundary.md**

Create `/Users/adityaanurag/projects/vibecheck/checks/09-missing-error-boundary.md`:

```markdown
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
```

- [ ] **Step 2: Create 10-missing-loading-states.md**

Create `/Users/adityaanurag/projects/vibecheck/checks/10-missing-loading-states.md`:

```markdown
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
```

- [ ] **Step 3: Create 11-console-log-in-prod.md**

Create `/Users/adityaanurag/projects/vibecheck/checks/11-console-log-in-prod.md`:

```markdown
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
```

- [ ] **Step 4: Create 12-missing-not-found.md**

Create `/Users/adityaanurag/projects/vibecheck/checks/12-missing-not-found.md`:

```markdown
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
```

- [ ] **Step 5: Commit**

```bash
cd /Users/adityaanurag/projects/vibecheck
git add checks/
git commit -m "checks: medium-tier definitions (error boundary, loading, console.log, 404)"
```

---

## Task 15: Report template

**Files:**
- Create: `templates/report-template.md`

- [ ] **Step 1: Create report-template.md**

Create `/Users/adityaanurag/projects/vibecheck/templates/report-template.md`:

```markdown
# vibecheck report

**Project:** {{PROJECT_NAME}}
**Scanned:** {{DATE}} {{TIME}}
**Score:** {{SCORE}} / 10 — {{SCORE_LABEL}}

## TL;DR

- 🔴 {{CRITICAL_COUNT}} Critical
- 🟠 {{HIGH_COUNT}} High
- 🟡 {{MEDIUM_COUNT}} Medium

## Top 3 things to fix first

1. {{TOP_FIX_1}}
2. {{TOP_FIX_2}}
3. {{TOP_FIX_3}}

---

## 🔴 Critical

{{CRITICAL_FINDINGS}}

---

## 🟠 High

{{HIGH_FINDINGS}}

---

## 🟡 Medium

{{MEDIUM_FINDINGS}}

---

## What vibecheck did NOT check

vibecheck v1 audits 12 specific production-readiness issues common in AI-generated Next.js apps. It does NOT check for:

- Test coverage or test quality
- Performance / bundle size
- Accessibility (a11y)
- SEO completeness
- Database migrations / data integrity
- Race conditions / concurrency bugs
- Business-logic correctness

A clean vibecheck report means you've cleared the most common landmines, NOT that your app is production-perfect. Use it as a floor, not a ceiling.

---

*Generated by [vibecheck](https://github.com/YOUR_USERNAME/vibecheck) on {{DATE}}.*
```

Each `{{PLACEHOLDER}}` will be substituted by Claude when filling the template. For each finding, the format is:

```markdown
### {{N}}. {{TITLE}} in `{{FILE}}:{{LINE}}`

**What's wrong:** {{EXPLANATION}}

**Suggested fix:** {{FIX_EXPLANATION}}

```{{LANG}}
{{CODE_SNIPPET}}
```
```

- [ ] **Step 2: Commit**

```bash
cd /Users/adityaanurag/projects/vibecheck
git add templates/
git commit -m "templates: add report template"
```

---

## Task 16: SKILL.md — the orchestration brain

**Files:**
- Create: `SKILL.md`

This is the entry point Claude reads when the skill is invoked. It instructs Claude on the full workflow.

- [ ] **Step 1: Create SKILL.md**

Create `/Users/adityaanurag/projects/vibecheck/SKILL.md`:

````markdown
---
name: vibecheck
description: Audits an AI-generated Next.js App Router project for the 12 most common production-readiness issues and produces a severity-tiered markdown report. Trigger when the user asks to "vibecheck", "audit my Next.js app", or wants a production-readiness check.
---

# vibecheck

When invoked, run a production-readiness audit on the current Next.js App Router project and produce a markdown report.

## Step 1: Verify this is a Next.js App Router project

Check, in order:

1. `package.json` exists and includes `"next"` in `dependencies` or `devDependencies`.
2. An `app/` directory exists at the project root.

If either check fails, stop and tell the user:

> vibecheck v1 only audits Next.js App Router projects. I couldn't find a `package.json` with Next.js as a dependency, or an `app/` directory at the project root. If your project uses the older Pages Router (`pages/` directory), Pages Router support is on the roadmap but not in v1.

If both checks pass, continue.

## Step 2: Run the bash scanners

Run each of these scripts from the user's project root and collect their output. Each emits zero or more lines in the format `[SEVERITY] check-name: file:line — message`.

```bash
bash ~/.claude/skills/vibecheck/scripts/scan-secrets.sh
bash ~/.claude/skills/vibecheck/scripts/scan-env-files.sh
bash ~/.claude/skills/vibecheck/scripts/scan-dangerous-html.sh
bash ~/.claude/skills/vibecheck/scripts/scan-console-logs.sh
bash ~/.claude/skills/vibecheck/scripts/scan-localhost-urls.sh
bash ~/.claude/skills/vibecheck/scripts/scan-public-env-leaks.sh
```

Run each from the user's current working directory (the project being audited), not from inside the skill directory. The scanners scan `.` (the cwd), which is exactly what we want.

If any scanner exits non-zero or produces no output when it should have, note it but continue with the rest. Never crash the whole audit on a single scanner failure.

## Step 3: Run the judgment-based checks

For checks where pattern-matching isn't reliable, read the relevant files yourself and apply the check definition. Each definition lives in `~/.claude/skills/vibecheck/checks/`. Read the definitions before running these checks:

- **Check 03 (Missing auth):** Read each `app/api/**/route.ts` and each file containing `"use server"`. Apply `checks/03-missing-auth.md`.
- **Check 05 (Missing input validation):** Same set of files. Apply `checks/05-missing-input-validation.md`.
- **Check 06 (Leaked server secrets, code-side):** The scanner catches obvious cases; you also check for less-obvious naming patterns. Apply `checks/06-leaked-server-secrets.md`.
- **Check 07 (Swallowed errors):** Read files that contain `try {` or `.catch(`. Apply `checks/07-swallowed-errors.md`.
- **Check 09 (Missing error.tsx):** Check filesystem: is there an `app/error.tsx`? For routes with async data fetching, is there a sibling `error.tsx` in the segment?
- **Check 10 (Missing loading states):** Is there an `app/loading.tsx`? For client components with bare `useEffect` fetches, do they render any loading UI?
- **Check 12 (Missing not-found.tsx):** Is there an `app/not-found.tsx`?

For each finding, capture: severity, check name, file path, line number (if applicable), and a short specific explanation.

## Step 4: Aggregate and score

Score formula: `10 - (criticals * 2) - (highs * 1) - (mediums * 0.3)`, clamped to `[0, 10]`. Round to one decimal.

Score labels:
- `8.0+` → "Almost Ready to Ship"
- `5.0–7.9` → "Needs Work"
- `2.0–4.9` → "Not Ready to Ship"
- `< 2.0` → "Critical — Do Not Deploy"

## Step 5: Write the report

Read `~/.claude/skills/vibecheck/templates/report-template.md`. Substitute placeholders with the gathered findings. Write the filled template to `vibecheck-report.md` in the user's project root.

The `Top 3 things to fix first` should be the three highest-impact specific findings (not generic advice). Pick the ones with the highest blast radius if exploited.

## Step 6: Summarize in chat

Print a short summary to the chat:

```
🔍 vibecheck complete

Score: 3.4 / 10 — Not Ready to Ship
  🔴 4 Critical
  🟠 3 High
  🟡 2 Medium

Top 3 to fix first:
1. <first specific finding>
2. <second specific finding>
3. <third specific finding>

Full report written to vibecheck-report.md
```

## Notes on tone

- Direct, no condescension. The user is a developer who built something real. Treat findings as a code review from a friend, not an inspection from a regulator.
- Be specific. "Missing auth" is bad; "DELETE /api/todos accepts any request without checking the session" is good.
- Don't pad. Zero findings is fine. Don't invent issues to hit a quota.

## What NOT to do

- Don't auto-fix anything in v1.
- Don't `npm install` or modify the project's files.
- Don't run the project's tests, build, or dev server.
- Don't scan `node_modules/`, `.next/`, or any `.test.` / `.spec.` files.
- Don't include findings in `vibecheck/examples/demo-app/` itself if the user happens to be inside this repo — that demo is deliberately broken on purpose.
````

- [ ] **Step 2: Commit**

```bash
cd /Users/adityaanurag/projects/vibecheck
git add SKILL.md
git commit -m "skill: SKILL.md orchestration brain"
```

---

## Task 17: Generate examples/sample-report.md

**Files:**
- Create: `examples/sample-report.md`

This is the "what does the output look like?" artifact that anchors the README. We generate it by manually walking through the skill on the demo app.

- [ ] **Step 1: Run all scanners against demo-app and collect output**

```bash
cd /Users/adityaanurag/projects/vibecheck/examples/demo-app
bash ../../scripts/scan-secrets.sh > /tmp/vc-out.txt
bash ../../scripts/scan-env-files.sh >> /tmp/vc-out.txt
bash ../../scripts/scan-dangerous-html.sh >> /tmp/vc-out.txt
bash ../../scripts/scan-console-logs.sh >> /tmp/vc-out.txt
bash ../../scripts/scan-localhost-urls.sh >> /tmp/vc-out.txt
bash ../../scripts/scan-public-env-leaks.sh >> /tmp/vc-out.txt
cat /tmp/vc-out.txt
```

Save this raw output — you'll fold it into the report.

- [ ] **Step 2: Manually identify judgment-based findings**

Inspect:
- `app/api/todos/route.ts` → check 03 (no auth on POST + DELETE), check 05 (no validation on POST + DELETE)
- `app/dashboard/actions.ts` → check 03 (no auth), check 05 (no validation)
- `app/api/secret/route.ts` → check 03 (no auth)
- `lib/auth.ts` → check 07 (empty catch + `.catch(() => {})`)
- `app/` → check 09 (no `error.tsx`), check 10 (no `loading.tsx`), check 12 (no `not-found.tsx`)
- `app/dashboard/page.tsx` → check 10 (client fetch with no loading state)

Total expected: roughly 15-18 findings.

- [ ] **Step 3: Compute score**

Approximate counts: 5 Critical, 8 High, 5 Medium → score = `10 - (5*2) - (8*1) - (5*0.3) = 10 - 10 - 8 - 1.5 = -9.5` → clamped to `0.0` → "Critical — Do Not Deploy"

Use this as the demo app's official score.

- [ ] **Step 4: Write examples/sample-report.md**

Create `/Users/adityaanurag/projects/vibecheck/examples/sample-report.md`:

````markdown
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

### 5. `dangerouslySetInnerHTML` with network-fetched content in `app/dashboard/page.tsx:13`

**What's wrong:** The component fetches HTML from `/api/content` and renders it directly. If that endpoint ever returns user-controlled content, this is an XSS vulnerability.

**Suggested fix:** Sanitize with DOMPurify before rendering, or render as text / markdown.

---

## 🟠 High

### 6. Missing auth on `DELETE /api/todos` in `app/api/todos/route.ts:18`

**What's wrong:** The DELETE handler accepts any request and deletes whatever `id` is in the body. No session check, no rate limit.

**Suggested fix:** Call `await auth()` at the top of the handler, return 401 if no session.

### 7. Missing auth on `POST /api/todos` in `app/api/todos/route.ts:11`

**What's wrong:** Same as above for the POST handler — anyone can create todos for anyone.

### 8. Missing auth on Server Action `deleteUser` in `app/dashboard/actions.ts:5`

**What's wrong:** `"use server"` Server Action deletes users with no session check. Server Actions are callable from anywhere a CSRF token can be obtained.

### 9. Missing input validation on `POST /api/todos` in `app/api/todos/route.ts:11`

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

### 14. Empty catch in `lib/auth.ts:8`

**What's wrong:** `catch (e) {}` silently swallows authentication failures. If auth breaks in prod, you'll never know.

### 15. Swallowed promise rejection in `lib/auth.ts:14`

**What's wrong:** `.catch(() => {})` means logout failures are invisible.

### 16. `console.log` in `lib/auth.ts:4`

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
````

- [ ] **Step 5: Commit**

```bash
cd /Users/adityaanurag/projects/vibecheck
git add examples/sample-report.md
git commit -m "examples: sample report generated from demo-app"
```

---

## Task 18: install.sh

**Files:**
- Create: `install.sh`

- [ ] **Step 1: Create install.sh**

Create `/Users/adityaanurag/projects/vibecheck/install.sh`:

```bash
#!/usr/bin/env bash
# install.sh — install vibecheck into ~/.claude/skills/vibecheck/
set -euo pipefail

INSTALL_DIR="${HOME}/.claude/skills/vibecheck"
REPO_URL="${VIBECHECK_REPO_URL:-https://github.com/YOUR_USERNAME/vibecheck.git}"
TMP_DIR="$(mktemp -d)"

echo "vibecheck installer"
echo "==================="

# Check prerequisites.
for cmd in git bash grep; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "error: '$cmd' is required but not installed." >&2
    exit 1
  fi
done

# Clone (or update) the skill.
if [[ -d "$INSTALL_DIR" ]]; then
  echo "Existing install detected at $INSTALL_DIR — updating."
  git -C "$INSTALL_DIR" fetch --quiet origin
  git -C "$INSTALL_DIR" reset --hard origin/main --quiet
else
  echo "Installing to $INSTALL_DIR ..."
  mkdir -p "$(dirname "$INSTALL_DIR")"
  git clone --quiet --depth=1 "$REPO_URL" "$INSTALL_DIR"
fi

# Ensure scripts are executable.
chmod +x "$INSTALL_DIR"/scripts/*.sh "$INSTALL_DIR"/install.sh 2>/dev/null || true

echo ""
echo "✓ vibecheck installed to $INSTALL_DIR"
echo ""
echo "To use it:"
echo "  1. Open Claude Code in any Next.js App Router project."
echo "  2. Ask Claude to 'vibecheck this project' (or type /vibecheck if you've enabled slash-command resolution)."
echo ""
echo "Demo: run vibecheck on the included broken demo app to see what it does:"
echo "  cd $INSTALL_DIR/examples/demo-app"
echo "  # then ask Claude Code to vibecheck"
echo ""

rm -rf "$TMP_DIR"
```

- [ ] **Step 2: Make executable**

```bash
chmod +x /Users/adityaanurag/projects/vibecheck/install.sh
```

- [ ] **Step 3: Note the placeholder**

`YOUR_USERNAME` in `REPO_URL` is intentional — it's resolved when the user confirms their GitHub username (one of the open questions in the spec). The plan does NOT replace it; that happens just before the first GitHub push.

- [ ] **Step 4: Commit**

```bash
cd /Users/adityaanurag/projects/vibecheck
git add install.sh
git commit -m "install: one-command installer (clone + chmod)"
```

---

## Task 19: Full README

**Files:**
- Modify: `README.md` (replace skeleton from Task 1)

- [ ] **Step 1: Read current README to confirm it's the skeleton**

```bash
cat /Users/adityaanurag/projects/vibecheck/README.md
```

Expected: the short placeholder created in Task 1.

- [ ] **Step 2: Replace with full README**

Overwrite `/Users/adityaanurag/projects/vibecheck/README.md` with:

```markdown
# vibecheck

> Find out what'll break in production, before production does.

A Claude Code skill that audits AI-generated Next.js apps for the 12 things that always go wrong.

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

---

## What it does

You vibe-coded an app. It runs on localhost. Now what?

vibecheck audits your Next.js project against a curated checklist of the 12 production-readiness issues that AI-assisted codebases consistently get wrong: exposed secrets, missing auth, no input validation, swallowed errors, hardcoded URLs.

Run once. Get a severity-tiered report in 30 seconds. Decide what to fix.

[See a sample report](examples/sample-report.md) — generated from the broken demo app in this repo.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/vibecheck/main/install.sh | bash
```

That installs the skill into `~/.claude/skills/vibecheck/`. No npm, no Node deps, nothing to configure.

## Run it

Open Claude Code in any Next.js App Router project and ask:

> vibecheck this project

Claude reads the skill, runs the scanners, applies the judgment-based checks, and writes a report to `vibecheck-report.md` in your project root. A summary prints to chat.

## What it checks

**🔴 Critical — security or data loss**
1. Exposed secrets in source (API keys, tokens, DB passwords)
2. `.env*` files not in `.gitignore`
3. Missing auth on API routes / Server Actions that mutate data
4. `dangerouslySetInnerHTML` without sanitization

**🟠 High — production failure or silent breakage**
5. Missing input validation on Server Actions / API routes
6. Server secrets leaked via `NEXT_PUBLIC_` prefix
7. Swallowed errors (empty catches, no-op `.catch()`)
8. Hardcoded `localhost` / dev URLs

**🟡 Medium — operational pain, bad UX**
9. Missing error boundaries (`error.tsx`)
10. Missing loading states (`loading.tsx`, bare `useEffect` fetches)
11. `console.log` left in production code
12. Missing `not-found.tsx` (404)

Each check has a dedicated [definition file](checks/) explaining what it looks for, what it ignores, and how to fix it.

## Try it on the demo app

This repo includes [a deliberately-broken Next.js app](examples/demo-app/) you can audit immediately:

```bash
cd ~/.claude/skills/vibecheck/examples/demo-app
# then ask Claude Code to vibecheck this project
```

It contains a true-positive instance of every check vibecheck runs.

## Founder note

I'm not a traditional software engineer. I worked in supply chain (Blue Yonder, TCS) for years before AI coding tools made it possible for someone like me to actually build things. I built three apps with Claude and Cursor before realizing they all had the same set of problems: secrets in source, no input validation, hardcoded localhost URLs that worked perfectly until they didn't.

vibecheck is the audit I wish I'd had on day one — the friend who quietly tells you what's wrong before your launch tweet goes out.

If you're in the same boat: I made this for us.

— Aditya

## FAQ

**Does this replace tests?**
No. vibecheck catches structural issues with how AI-assisted code is typically written. It doesn't verify your business logic. You still need tests.

**Does it support Pages Router?**
Not in v1. Next.js App Router only. Pages Router is on the roadmap.

**Python? FastAPI?**
Not in v1. Roadmap.

**Will it modify my code?**
No. v1 is audit-only — it writes a single report file (`vibecheck-report.md`) and that's it. v2 will add an opt-in "guide me through fixes" mode.

**Does it run npm install / build / tests?**
No. It only reads files.

## Contributing

PRs welcome — especially new checks. Each check is one self-contained file in [`checks/`](checks/) plus an optional scanner script in [`scripts/`](scripts/). See [CONTRIBUTING.md](CONTRIBUTING.md) (coming soon).

## Roadmap

- **v2:** Interactive triage — walk through findings, apply safe fixes with consent.
- **v3:** Python support (FastAPI, Streamlit).
- **v4:** CI integration (GitHub Action wrapper).

## License

[MIT](LICENSE)
```

- [ ] **Step 3: Commit**

```bash
cd /Users/adityaanurag/projects/vibecheck
git add README.md
git commit -m "docs: full README with install, checks, demo, founder note"
```

---

## Task 20: End-to-end verification

**Files:** none changed — this task is a manual run-through.

- [ ] **Step 1: Run every scanner against the demo app from a clean shell**

```bash
cd /Users/adityaanurag/projects/vibecheck/examples/demo-app
echo "--- scan-secrets ---"        ; bash ../../scripts/scan-secrets.sh
echo "--- scan-env-files ---"      ; bash ../../scripts/scan-env-files.sh
echo "--- scan-dangerous-html ---" ; bash ../../scripts/scan-dangerous-html.sh
echo "--- scan-console-logs ---"   ; bash ../../scripts/scan-console-logs.sh
echo "--- scan-localhost-urls ---" ; bash ../../scripts/scan-localhost-urls.sh
echo "--- scan-public-env-leaks ---"; bash ../../scripts/scan-public-env-leaks.sh
```

Expected total: ~12+ findings across the six scanners. Confirm each scanner's expected outputs from Tasks 6–11 actually appear.

- [ ] **Step 2: Run scanners on a clean directory and confirm zero findings**

```bash
TMP=$(mktemp -d)
cd "$TMP"
echo '{"name":"clean","dependencies":{"next":"14.2.0"}}' > package.json
mkdir app
echo 'export default function Page() { return null; }' > app/page.tsx
bash /Users/adityaanurag/projects/vibecheck/scripts/scan-secrets.sh
bash /Users/adityaanurag/projects/vibecheck/scripts/scan-env-files.sh
bash /Users/adityaanurag/projects/vibecheck/scripts/scan-dangerous-html.sh
bash /Users/adityaanurag/projects/vibecheck/scripts/scan-console-logs.sh
bash /Users/adityaanurag/projects/vibecheck/scripts/scan-localhost-urls.sh
bash /Users/adityaanurag/projects/vibecheck/scripts/scan-public-env-leaks.sh
rm -rf "$TMP"
```

Expected: each scanner produces no output (clean project = no findings).

- [ ] **Step 3: Verify SKILL.md and all check files are syntactically valid Markdown**

```bash
cd /Users/adityaanurag/projects/vibecheck
ls SKILL.md checks/*.md scripts/*.sh templates/*.md examples/sample-report.md README.md LICENSE
wc -l SKILL.md checks/*.md
```

Expected: every file present, none empty.

- [ ] **Step 4: Manually invoke the skill on the demo app to confirm the end-to-end UX**

Outside the plan execution (since this requires running Claude Code interactively against the demo app), prompt:
> "vibecheck the project at /Users/adityaanurag/projects/vibecheck/examples/demo-app"

Confirm Claude:
- Detects it as a Next.js App Router project.
- Runs the scanners.
- Performs judgment-based checks.
- Writes a `vibecheck-report.md` to `examples/demo-app/`.
- Prints a summary matching the structure in `examples/sample-report.md`.

After verifying, delete the just-written `vibecheck-report.md` (it's gitignored, but clean up anyway):

```bash
rm -f /Users/adityaanurag/projects/vibecheck/examples/demo-app/vibecheck-report.md
```

- [ ] **Step 5: Final commit + git log review**

```bash
cd /Users/adityaanurag/projects/vibecheck
git status
git log --oneline
```

Expected: 20+ clean commits, no uncommitted changes. Ready to push to GitHub once the user confirms the GitHub username.

---

## Out-of-Plan: Pushing to GitHub

Not part of this plan (it's a manual step the user takes when they're ready):

1. Confirm `vibecheck` repo name available on GitHub (or pick fallback).
2. Replace `YOUR_USERNAME` in `install.sh` and `README.md` with actual GitHub username.
3. Create the repo on GitHub.
4. `git remote add origin git@github.com:USERNAME/vibecheck.git && git push -u origin main`.
5. Test the install one-liner from a fresh machine / shell to confirm it works.
6. Tag v0.1.0.
