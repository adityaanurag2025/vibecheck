// BUG: hardcoded GitHub token
// BUG: returns admin credentials with no auth
import { NextResponse } from "next/server";

const ADMIN_TOKEN = "ghp_realfakelookinggithubtoken123456789012345678901";

export async function GET() {
  return NextResponse.json({ admin: ADMIN_TOKEN });
}
