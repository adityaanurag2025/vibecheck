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
