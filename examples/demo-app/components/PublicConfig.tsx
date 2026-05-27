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
