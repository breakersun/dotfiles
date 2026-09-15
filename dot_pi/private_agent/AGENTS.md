# Global Instructions

## Memory (brain MCP)

When the user says **"记住"、"记录"、"备忘"、"remember"、"note this"** (or similar, in any language) followed by or referring to content, immediately store it via the `brain` MCP server:

1. Call `brain_remember` with:
   - `title`: concise summary (one line, bilingual OK)
   - `content`: structured details — root cause / fix / commands / caveats, keep it self-contained for future recall
2. Reply with the stored memory ID (one line confirmation), nothing more unless asked.

Related intents:
- User asks to **recall** past knowledge ("之前记过", "recall", "think back") → use `brain_recall` with semantic search.
- User says **"补充"** to a memory → `brain_append`.

Cautions:
- Only store when clearly directed to remember/note something; ordinary conversation is NOT a memory trigger.
- **Never store secrets** (API keys, passwords, tokens) in brain.
- If the brain server is unreachable, say so briefly instead of silently failing.
