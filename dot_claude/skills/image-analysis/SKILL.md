---
name: image-analysis
description: 当用户消息中包含图片时，自动调用 mcp-vision 工具进行分析。无文字说明时默认 analyze_image；有文字说明时按意图路由到 analyze_image / ocr_extract / ocr_precise。
---

# Image Analysis

Detect image markers in user message, auto-route to mcp-vision tools.

## Trigger

User message contains `[Image:` or `[Image #N]` markers (pasted via Alt+V or drag-drop).

## Routing Rules

1. **No text instructions** → call `analyze_image` with default prompt (detailed description).
2. **Text instructions present** → parse intent:
   - Describe, Q&A, chart/graph analysis → `analyze_image` (user text = prompt)
   - Extract/copy text, read text → `ocr_extract` (user text = prompt)
   - Need coordinates, confidence scores, structured position data → `ocr_precise`

## Parameters

- `image`: extract path from `[Image: <path>]` or `[Image #N]` marker. Pass as-is.
- `prompt`: user's text instructions, or null for default analysis.

## Examples

- User pastes screenshot, no text → `analyze_image(image="<path>")`
- User pastes screenshot + "提取图中文字" → `ocr_extract(image="<path>", prompt="提取图中文字")`
- User pastes chart + "分析趋势" → `analyze_image(image="<path>", prompt="分析趋势")`
- User pastes receipt + "精确识别金额" → `ocr_precise(image="<path>")`

## Gotchas

- Multiple images in one message → process each separately, return combined result.
- Remote URLs in markers → pass directly, mcp-vision supports both local paths and URLs.
- If mcp-vision tools unavailable, tell user immediately — do not silently skip.
