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
