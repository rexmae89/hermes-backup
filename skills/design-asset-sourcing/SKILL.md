---
name: design-asset-sourcing
version: 1.0
author: Jarvis (curator-managed)
license: internal
description: Use when sourcing 3D icons/design assets; free alternatives.
metadata:
  hermes:
    tags: [design, assets, 3d-icons, licensing]
---

# Design Asset Sourcing

## When to Use

The user wants 3D icons/illustrations/design assets, sends a paid asset-store listing, or asks to obtain a paid asset.

## Licensing gate (always)

- Never bypass paid/subscription assets (Craftwork, IconScout premium, etc.) — no scraping paywalled download links. State the refusal in Persian, briefly, then immediately offer a free licensed alternative. The expected move is refusal + instant workaround, not a lecture.
- Prefer sources with explicit free licenses, no attribution required, and no account needed (free3dicons.com, poly.pizza, Sketchfab CC0).

## Free 3D icons via free3dicons.com CDN (proven workflow)

1. Fetch the icon page with curl: `https://free3dicons.com/icon/<slug>` and grep the HTML for `cdn.free3dicons.com` URLs.
2. Download the full-size file directly: `https://cdn.free3dicons.com/icons/<slug>/master.webp` — no login, no watermark, ~1500×1500, transparent background. Try common food/object slugs (burger, pizza, fries, taco...); batch-probe with `curl -f` — 200 or 404 per slug.
3. Convert webp→PNG with PIL (`Image.open(...).convert('RGBA').save(..., 'PNG')`) — Telegram sends PNG as photo; keep webp originals for web use (smaller).
4. Build the deliverable ZIP with Python `zipfile` — the `zip` binary is NOT installed on this host; do not shell out to it.
5. Make a white-background contact sheet preview (PIL, 5 icons per row, 256px thumbs) so the user sees the set before opening the zip. Deliver preview.jpg + zip via MEDIA: lines.

Pitfall: download links live in the raw HTML (master.webp/preview.webp); a normal web_extract strips them, so use curl + grep for the discovery step.

See references/free-asset-sources.md for the source catalog.