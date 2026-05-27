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
