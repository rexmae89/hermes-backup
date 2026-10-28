---
name: video-content-analysis
description: "Use when a user sends a video or reel to summarize."
version: 1.0.0
---

# Video / Reel Content Analysis

Use when the user sends a video file (Instagram reel, YouTube short, screen recording, tutorial clip) or a link to one and asks for a summary, a transcript, "what does it say", or the list of tools/products shown in it. Also covers the follow-up "find the links" for items named in the clip.

**Read the media, never ask the user to describe it.** A forwarded video is already on disk; the attachment notice gives the absolute path, so inspect it directly.

## Output rules (user preference)

- Answer in the user's language (Persian for Noyan), short and direct: verdict first, then bullets/labeled lines — never a wall of transcript.
- Lead with what the clip is and who made it, then the items in the order they appear.
- Do not narrate the frame-extraction work or dump tool logs. One clause on how it was read is enough.

## Procedure

1. **Probe duration** — sets the sampling budget.
   `ffprobe -v error -show_entries format=duration -of csv=p=0 FILE`
2. **Sample frames at ≥1 fps into the scratch dir** (never /tmp; use `~/.hermes/cache/scratch/<name>/`).
   `mkdir -p frames && ffmpeg -y -v error -i FILE -vf "fps=1,scale=720:-1" frames/f_%03d.jpg`
   Sub-second title cards and list overlays are why this rate matters: sampling one frame every 2-4 s silently drops whole numbered items, and the omission is invisible afterwards (you will report "this item was never shown").
3. **Read frames with `vision_analyze`, four or more calls batched in one turn.** Per frame ask for *all* on-screen text, any numbered title cards in order, and any burned-in subtitles. Feed each answered frame back as context for the next batch when a numbered list is half-found.
4. **Tile frames into montage sheets** to read many frames per vision call.
   `ffmpeg -y -v error -i frames/f_%03d.jpg -vf "scale=560:-1,tile=4x3:margin=6:padding=4" -frames:v 1 -q:v 3 sheet_%d.jpg`
   ffmpeg numbers the sheets sequentially; to cover frames past the first sheet, re-run with `-start_number N` (e.g. `-start_number 9` for sheet 2 of 12-frame grids).
5. **Crop the text bands** when text lives in a fixed strip (top title card, bottom subtitle):
   `-vf "crop=iw:ih*0.30:0:0,scale=600:-1,tile=4x2:..."` for the top band, `crop=iw:ih*0.35:0:ih*0.55` for the bottom.
6. **Assemble the answer**: numbered items in display order, each with one line of what it does, plus a one-line takeaway. Keep the sampled frames if the user may want a follow-up (links, deeper detail).

### Pitfalls that cost time

- **Coarse fps sampling loses list items.** Hit ≥1 fps for anything with a numbered countdown. If the user's count ("5 plugins") exceeds what you found, resample denser rather than concluding the rest were cut.
- **Montage tiles shrunk too far make non-Latin script unreadable.** A vision call on an unreadable sheet does not say "too small" — it says the premise is wrong and the content is unrelated (e.g. "this is a florist website, not a plugin reel"). Treat that answer as a resolution problem: re-crop the region at full resolution and re-read that frame alone before doubting the source.
- **Burned-in subtitles in the clip are the cheapest transcript.** When narration carries the substance, subtitle frames give the wording without any speech model.
- **A URL extraction is not the video.** `web_extract` on a reel URL returns the post caption, hashtags, and comments only — useful context (it names the topic and may list the creator), but the on-screen content only exists in the file. When both are available, read the file and use the caption to title the creator and topic.
- **Optional, check availability first:** if a local transcription CLI (`whisper`, `faster-whisper`, `whisper.cpp`) is installed, `ffmpeg -i FILE -vn audio.wav` plus that CLI gives exact quoted wording cheaply. Do not assume it is present; frame reading is the always-available path.

## Helper

`scripts/frame_sheet.sh <video> [outdir] [fps] [tile]` probes duration, samples frames, and writes full-frame, top-band, and bottom-band montage sheets in one shot. Read the sheets, then read individual frames for anything still unclear.

## Finding links for the items named in the clip

- One `web_search` per item name, all issued in parallel from a single `execute_code` call.
- Anything unresolved gets a second, narrower round with the vendor or product qualifier ("<product> plugin <vendor>", "<product> official claude code plugin") — generic names like "Taste Skill" or "Awesome Design" will not resolve on the first query.
- Verify on the authoritative page (official plugin/marketplace page or the GitHub repo) before presenting, and prefer the official listing over an aggregator blog.
- Deliver per item: one-line what it does, the link, and the install command when the source publishes one.

## Downloading Instagram thumbnails, photos, and slideshows (yt-dlp + browser)

- Install once per machine: `uv tool install yt-dlp` (binary lands in `~/.local/bin/yt-dlp`).
- **Reel/video thumbnail** (highest quality, no download of the video): `yt-dlp --write-thumbnail --skip-download --no-playlist '<post-url>'` — works anonymously.
- **Image posts and slideshows are NOT supported by yt-dlp** — it errors "There is no video in this post" / "No video formats found". Do not retry yt-dlp variants; go straight to the browser path.
- **Photo posts via browser** (the working anonymous path):
  1. `browser_exec`: `new_tab('<post-url>')`, wait ~4 s.
  2. Extract candidate images with `naturalWidth` filtering — the sidebar/recommended thumbnails are always small, so `w>=800` separates real slides from junk: `Array.from(document.querySelectorAll('img')).map(i=>({src:i.src,w:i.naturalWidth})).filter(o=>o.src.includes('scontent') && o.w>=800)`.
  3. Dedupe by URL base (`split('?')[0]`) — Instagram renders the same slide several times.
  4. Download each URL with plain `curl` — the signed CDN URLs work from curl as long as you do not modify ANY query param (changing or removing `stp=` breaks the signature → 403).
  5. Full-res slides come out at 1440px+ (sometimes 4032px). Verify with PIL before delivering.
- **If the main image never renders in the DOM** (only ~640px sidebar-quality imgs appear even after reload): the post exists (check `og:title`/`og:description` meta) but its full-res version is login-gated. Fetch the exact `og:image` URL via in-page `fetch()` (browser cookies make it 200) as a 640px fallback, and tell the user the resolution limit — logging in would unlock full quality.
- **Deliver as a zip**: Python `zipfile` (the `zip` CLI is often not installed), `ZIP_STORED` since JPEGs are already compressed, then one `MEDIA:` line with the absolute zip path.

## Delivering media files to the user (Telegram)

- Send a video file by writing `MEDIA:/absolute/path.mp4` on its own line in the reply. Build outputs in `/tmp`, then copy to a stable path (e.g. `~/.hermes/media_out/`) before referencing it — `/tmp` paths referenced directly can be pruned before the platform picks the file up.
- An image URL renders as a photo via `![alt](url)`; a local `.mp4` with the MEDIA: line plays inline.

## Building short animation videos from stills

When the user hands you two keyframe images (e.g. product assembled + exploded) and asks for an animation, ffmpeg + PIL is enough — no motion library needed:

1. Pre-render each keyframe onto a fixed canvas (PIL: resize to cover height, paste centered on a studio-dark or brand-colored background) so the two frames share geometry; add a soft vignette for a commercial look.
2. Generate frames for a ~6 s clip at 30 fps: hold keyframe A with a slow push-in (scale 1.0→1.04), crossfade A→B over ~2.5 s with a smooth ease (`t*t*(3-2t)`), hold B with a gentle drift, then fade back to A for a loop feel. Drive per-frame opacity/zoom from one progress value.
3. Encode: `ffmpeg -y -framerate 30 -i f_%04d.jpg -c:v libx264 -pix_fmt yuv420p -crf 20 -movflags +faststart out.mp4`.
4. Check both source images share background/lighting before blending — mismatched backbones make the crossfade look broken; if backgrounds differ, composite both onto a common background first.
5. Confirm duration and size with `ffprobe`/`search_files` before sending, then deliver via the MEDIA: rule above.
