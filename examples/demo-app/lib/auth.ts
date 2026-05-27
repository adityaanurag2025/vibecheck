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
