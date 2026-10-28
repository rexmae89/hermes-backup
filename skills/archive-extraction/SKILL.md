---
name: archive-extraction
description: Use when extracting, listing, or inspecting archive files.
---

# Archive extraction

## Procedure

1. Identify the format first: `file <archive>` and `xxd <archive> | head` — check magic bytes (RAR = `Rar!`, RAR5 = `Rar!\x1a\x07\x01\x00`) and size. A few hundred bytes usually means a single small text file inside.
2. Pick the tool by format:
   - **zip / tar / gz / bz2 / xz / 7z**: `bsdtar` or `7z` if present, otherwise Python stdlib (`zipfile`, `tarfile`) — no installs needed.
   - **RAR**: no system rar/unrar on this host, and the Python `rarfile` module alone is NOT enough (it needs an external `unrar`/`unar` backend, and on encrypted-header archives it silently no-ops — empty `infolist()`, `extractall()` does nothing). Use the official static binary instead:
     ```
     curl -sL -o /tmp/rarlinux.tar.gz https://www.rarlab.com/rar/rarlinux-x64-712.tar.gz
     tar xzf /tmp/rarlinux.tar.gz -C /tmp
     /tmp/rar/unrar l <archive>                 # list
     /tmp/rar/unrar x -o+ <archive> <outdir>/   # extract
     ```
3. **Encrypted archives**: RAR5 can encrypt headers, so even `l` prompts for a password and shows nothing without one (`Details: RAR 5, encrypted headers`). Pass `-p<password>` non-interactively — there is no TTY in terminal, so the interactive prompt aborts with "Read error in the file stdin". Run `-p-` first to confirm encryption before asking the user. If no password works, stop and ask the user for it — do not brute-force or fabricate contents.
4. After extraction, `find <outdir> -type f -exec file {} \;` to see what came out, then read text files with read_file and report a concise summary. For Telegram delivery, send files with `MEDIA:/abs/path` lines and include the key contents inline so the user gets both.

## Pitfalls

- If you must install rarfile, use `uv venv /tmp/x && uv pip install --python /tmp/x/bin/python rarfile` (system pip is blocked by PEP 668 and the default python lacks it).
- rarfile's silent no-op on encrypted-header archives wastes a cycle: if `infolist()` is empty but the file has real content, it's encrypted — go straight to unrar and ask the user for the password.
