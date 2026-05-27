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
