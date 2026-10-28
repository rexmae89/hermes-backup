---
name: image-qr-ocr-extraction
description: Use when decoding QR codes or OCR-ing text from chat images.
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [QR, OCR, tesseract, image-text]
    related_skills: []
---

# Image QR & OCR Extraction

## When to Use

- User sends a photo/screenshot of a QR code, proxy link, code, or any text-in-image and wants the content extracted exactly.

## QR decode procedure

1. Install once: `sudo apt-get update && sudo apt-get install -y libzbar0 zbar-tools`; OpenCV via a uv venv (`uv venv /tmp/qrenv && uv pip install --python /tmp/qrenv/bin/python opencv-python-headless`) if image needs preprocessing.
2. Try `zbarimg --raw <image>` first.
3. **If nothing decodes, check for inverted colors**: screenshots with black backgrounds store the QR white-on-black; invert first (`255 - gray` in cv2, save PNG) and rescan — zbar/OpenCV both miss inverted codes silently.
4. Other preprocessing fallbacks: crop margins, upscale 4x cubic, Otsu threshold. OpenCV `QRCodeDetector().detectAndDecode()` on each variant.

## OCR (tesseract) procedure

1. `tesseract <img> stdout --psm 6` — for small text on colored backgrounds upscale 3x + Otsu binarize first (cv2), then try psm 4/6/11/12 and compare.
2. For structured strings (base64 proxy links, codes): know the expected format first — decode the known prefix (`vmess://` + b64 of `{"add":"...`) to anchor reconstruction, and validate a reconstructed string by decoding it back to valid JSON.
3. **If the image itself contains a literal `...` truncation**, the full string is unrecoverable — say so instead of presenting a guessed reconstruction as exact. Reconstructed-from-OCR strings with UUIDs/ids are never trustworthy; flag them as unusable for import.
4. **Screenshots are often downscaled by the chat app** (e.g. 1280px-wide Telegram screenshots) — long strings may be OCR-able only after strip-cropping the image into horizontal bands and upscaling 5x (LANCZOS4); a single whole-image pass can miss entire text blocks. Do NOT upscale beyond ~5x — 8x makes tesseract worse.
5. **For subscription/share URLs extracted from screenshots, verify usability immediately**: `curl` the URL (with client-like User-Agent) and report the HTTP status + body size. Iterate ambiguous-character substitutions (O↔0, l↔1/I, S↔5, B↔8, Z↔2) via parallel curl variants (single AND double substitutions) when the server 404s. If the server answers `200` with an empty body across ALL variants, the token is dead/expired — report that instead of continuing to guess.
6. vision_analyze on screenshots can time out repeatedly — fall back to local tesseract immediately instead of retrying the remote call.
