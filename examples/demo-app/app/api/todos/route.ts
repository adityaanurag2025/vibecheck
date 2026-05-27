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
