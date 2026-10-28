---
name: instagram-media-download
description: Use when downloading Instagram posts, reels, or thumbnails.
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [Instagram, media, download, yt-dlp, images]
    related_skills: []
---

# Instagram Media Download

## When to Use

- User sends one or many Instagram post/reel URLs and wants the media, thumbnails, or max-quality images saved/forwarded.

## Procedure

1. **Try yt-dlp first for VIDEO/reel content** (install: `uv tool install yt-dlp`):
   ```bash
   yt-dlp --write-thumbnail --skip-download '<post-url>'   # thumbnail only
   yt-dlp '<post-url>'                                     # full video
   ```
2. **For IMAGE posts yt-dlp fails** (`No video formats found` / `There is no video in this post`) — it does not support image posts. Do not retry variations; go straight to browser extraction:
   - `browser_exec`: `new_tab(post_url)`, wait ~3-5s, then extract:
     ```js
     JSON.stringify(Array.from(document.querySelectorAll('img'))
       .map(i=>({src:i.src, w:i.naturalWidth, h:i.naturalHeight}))
       .filter(o=>o.src.includes('scontent') && o.w>=800))
     ```
   - Download each URL with plain `curl -o file.jpg '<url>'` — the signed CDN URLs work from curl.
3. **Full quality**: use the DOM src as-is; the in-page src has no size suffix (`stp=dst-jpg_e35_tt6`) = full res (typically 1440px). Do NOT modify `stp=`/resize params in a signed URL — the signature binds exact params and any edit returns 403. The `og:image` meta tag is only 640x640 (login-wall quality).
4. **Filter junk**: the page also renders sidebar/thumbnail images (150px, same URLs recurring across different posts). Keep only `naturalWidth>=800` and dedupe by base URL (everything before `?`).
5. **If a post's main image never renders in the DOM** (only sidebar thumbs appear): fall back to `curl` the post URL with a browser User-Agent, take `og:image`, and fetch it — accept 640px as the anonymous ceiling.
6. Batch jobs: open each post URL in turn inside ONE `browser_exec` call (loops fine), but catch connection errors (`no close frame received or sent` = browser session dropped; reopen tab and retry that post).

## QR codes / on-image URLs
- Screenshots sometimes contain QR codes or small text URLs instead of links. Decode QR with OpenCV's `QRCodeDetector` in a throwaway uv venv (`uv venv /tmp/qrenv && uv pip install --python /tmp/qrenv/bin/python opencv-python-headless`); if it decodes empty, the QR is white-on-black — try the inverted grayscale (`255 - gray`) before concluding it's unreadable. For small text screenshots, `tesseract --psm 6` on a 5x Lanczos upscale of the exact text strip beats full-image OCR.

## Pitfalls

- `og:image` is always 640px — never present it as highest quality.
- Signed CDN URLs reject ANY parameter edit (403). Get the URL from the rendered DOM, don't hand-modify it.
- `zip` binary is often missing; use Python `zipfile` instead.
- Slideshows: only the currently-rendered slides appear in the DOM without login; additional slides require a logged-in session.
