---
name: encrypted-archive-extraction
description: Use when extracting RAR or password-protected archives.
---

# Extracting RAR (incl. password-protected) archives

## Environment facts (verify, don't assume)

- This host ships with NO rar tooling: no unrar/7z/bsdtar, and the `rarfile` Python module is absent.
- RAR5 archives with encrypted headers show an EMPTY file listing until the correct password is supplied — "empty archive" means password, not corruption.

## Working method

1. Identify the archive: `xxd file.rar | head` — `Rar!` magic; version byte tells RAR4 vs RAR5.
2. Install the real unrar (static, no root needed):
   ```
   curl -sL -o /tmp/rarlinux.tar.gz https://www.rarlab.com/rar/rarlinux-x64-712.tar.gz
   tar xzf /tmp/rarlinux.tar.gz -C /tmp && /tmp/rar/unrar
   ```
3. List/test first: `/tmp/rar/unrar lt archive.rar -p-` → confirms encryption and header health without extracting.
4. Extract non-interactively: `/tmp/rar/unrar x -o+ -p"<password>" archive.rar /tmp/out/` (unrar prompts on the TTY and dies without a PTY — always pass `-p`).
5. Verify contents actually landed: `find /tmp/out -type f | xargs file`, then read and deliver the extracted files.

## Pitfalls

- The Python `rarfile` module reports `EXTRACTED OK` and extracts NOTHING when no backend unrar binary is on PATH. Never trust its success return; check the output directory. Prefer rarlab's unrar directly.
- If the user has given a password in chat earlier in the session, reuse it — do not re-ask.
