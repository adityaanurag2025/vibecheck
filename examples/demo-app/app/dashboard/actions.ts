// BUG: Server Action mutates data with no session check
// BUG: formData fields are not validated before use
"use server";

export async function deleteUser(formData: FormData): Promise<void> {
  const userId = formData.get("userId") as string;
  await db.users.delete(userId);
}

declare const db: { users: { delete: (id: string) => Promise<void> } };
