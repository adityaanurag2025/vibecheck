// BUG: hardcoded localhost in production code
export const DB_URL = "http://localhost:5432/mydb";

export async function getTodos(): Promise<unknown> {
  const res = await fetch(`${DB_URL}/todos`);
  return res.json();
}
