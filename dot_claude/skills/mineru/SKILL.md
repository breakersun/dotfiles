---
name: MinerU
description: Convert PDFs, images, Office docs to Markdown/HTML/LaTeX/DOCX with OCR (80+ languages).
disable-model-invocation: true
allowed-tools: Bash(mineru-open-api:*)
---

## Modes

| Mode | Token | Formats | Limits | Speed |
|------|-------|---------|--------|-------|
| flash-extract | none | Markdown only | 10 MB / 20 pg | fast |
| extract | required | Multi-format (MD/HTML/LaTeX/DOCX), VLM/pipeline, batch | — | slower |

# MinerU — Document OCR & Conversion

## Install

```bash
npm install -g mineru-open-api
```

Verify: `mineru-open-api version`

## flash-extract (no token needed)

Fast, zero-setup. Markdown output only. Limit: 10 MB / 20 pages per file.

```bash
mineru-open-api flash-extract <file_or_url>                # → stdout
mineru-open-api flash-extract <file> -o ./out/             # → file
mineru-open-api flash-extract <file> --language en         # language hint
mineru-open-api flash-extract <file> --pages 1-10          # page range
```

Flags: `-o` output path, `--language` (default `ch`), `--pages`, `--timeout` (default 900s).

When flash-extract hits 429 or file limit → switch to `extract`.

## extract (token required)

Multi-format, VLM/pipeline model, batch processing.

```bash
mineru-open-api auth                                       # interactive token setup
mineru-open-api extract <file_or_url>                      # → stdout md
mineru-open-api extract <file> -f html                     # html output
mineru-open-api extract <file> -o ./out/ -f md,docx        # multi-format
mineru-open-api extract <file> --model vlm                 # VLM — higher accuracy, rare hallucination risk
mineru-open-api extract <file> --model pipeline            # pipeline — no hallucination, reliable
mineru-open-api extract *.pdf -o ./results/                # batch
```

Flags: `-o`, `-f` (md/json/html/latex/docx), `--model` (vlm/pipeline/html), `--ocr`, `--formula`, `--table`, `--language`, `--pages`, `--timeout`, `--concurrency`.

Token resolution: `--token` flag > `MINERU_TOKEN` env > `~/.mineru/config.yaml`.

## crawl (token required)

```bash
mineru-open-api crawl <url> -o ./out/                      # web page → markdown
mineru-open-api crawl url1 url2 -o ./pages/                # batch crawl
```

Flags: `-o`, `-f` (md/json/html), `--timeout`, `--concurrency`.

## Notes

- Quote file paths with spaces: `mineru-open-api extract "my report.pdf"`
- Without `-o`: result → stdout, progress → stderr
- Batch mode and binary formats (docx) require `-o`
- Upgrade: `npm install -g mineru-open-api`
