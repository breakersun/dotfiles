---
name: pdf2md
description: Convert PDF files to clean Markdown using markitdown CLI, then verify completeness against the original. Use when user wants to convert PDF to markdown, extract text from PDF, or says /pdf2md.
disable-model-invocation: true
argument-hint: <path-to-pdf>
---

# PDF → Markdown Conversion

Convert a PDF to Markdown using `markitdown`, verify fidelity, and commit.

## Workflow

### Phase 1: Convert

1. Run `markitdown <pdf-path>` via **PowerShell** (Bash tool breaks python -c).
2. Write output to `<same-dir>/<stem>.md` using the Write tool.
3. If markitdown output is empty or near-empty, warn user — likely a scanned/image-only PDF with no text layer.

### Phase 2: Verify

1. **Ask user** which model the verification sub-agent should use (3rd-party APIs may lack image/PDF reading support).
2. Spawn a verification sub-agent with the user-chosen model:
   - Agent reads the **original PDF** (Read tool with `pages` param) and the **generated .md**.
   - Cross-check:
     - All headings present
     - Numerical values and parameters match
     - Formulas intact
     - List items complete (no dropped sub-items)
   - Figures/images → confirm `[Figure: description]` placeholders exist; describe what each figure showed in the PDF.
   - Report: **"Zero content loss"** or list specific gaps.
3. If gaps found, manually patch the .md file.

### Phase 3: Commit

1. Stage the .md file.
2. Commit message: `docs: convert <stem>.pdf to markdown`
3. If not in a git repo, skip commit.

## Gotchas

- **PowerShell only** for `markitdown` invocation — Bash tool mangles python -c.
- **Scanned PDFs** (image-only pages) → markitdown returns empty. Warn user; OCR not in scope.
- **Large PDFs** (>20 pages) → read pages in batches (max 20 per Read call) during verification.
- **Figures** → raster/vector art cannot convert to markdown. Insert `[Figure: brief description of what the figure shows]`.
