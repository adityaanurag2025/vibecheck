# Check 04: dangerouslySetInnerHTML Without Sanitization

**Severity:** Critical
**Detection:** Scripted (`scripts/scan-dangerous-html.sh`) + Claude judgment to check for sanitization in surrounding code.

## What to look for

Any use of `dangerouslySetInnerHTML={{ __html: ... }}` in `.tsx` / `.jsx` files. For each occurrence, check whether the HTML content has been passed through a sanitizer (`DOMPurify.sanitize`, `sanitize-html`, etc.) before being rendered.

## True positives

```tsx
const [html, setHtml] = useState("");
useEffect(() => { fetch("/api/content").then(r => r.text()).then(setHtml); }, []);
return <div dangerouslySetInnerHTML={{ __html: html }} />;  // ← XSS risk
```

```tsx
return <div dangerouslySetInnerHTML={{ __html: userBio }} />;  // ← XSS if userBio comes from user input
```

## False positives to skip

- Content is sanitized first: `dangerouslySetInnerHTML={{ __html: DOMPurify.sanitize(html) }}`.
- Content is a hard-coded constant string defined in the same file (not from user input or network).
- Use in `<script>` tags for structured data (JSON-LD) — this is a recognized Next.js pattern.

## Suggested fix

Install and use a sanitizer:

```bash
npm install isomorphic-dompurify
```

```diff
+ import DOMPurify from "isomorphic-dompurify";
- <div dangerouslySetInnerHTML={{ __html: html }} />
+ <div dangerouslySetInnerHTML={{ __html: DOMPurify.sanitize(html) }} />
```

Better alternative when possible: render content as text (`<div>{text}</div>`) or as Markdown via `react-markdown`, which doesn't allow raw HTML by default.
