---
name: messenger-bot-bridges
description: Use when building a chat bot or message bridge on a bot API.
version: 1.0
---

# Messenger Bot Bridges

## When to Use
Load when connecting a bot or bridge to a messaging platform (Bale, Telegram, any Telegram-compatible Bot API): sending/receiving messages from a server, long-polling, systemd scheduling.

## Procedure
1. Verify credentials before building anything: `curl -s https://<api>/bot<TOKEN>/getMe` — confirms token validity and bot identity in one call.
2. Get the user's numeric chat_id: have them send `/start` to the bot, then read it from `getUpdates` (field `message.chat.id`). No chat_id, no sending.
3. Write two small scripts (stdlib `urllib` is enough; no SDK needed):
   - `poll.py` — one-shot `getUpdates` with `offset = last_update_id + 1` and long-poll `timeout=25`; persist the highest seen update_id to a state file; append new messages to a JSONL queue.
   - `send.py <chat_id> <text>` — POST `sendMessage` with JSON body.
4. Schedule with a systemd **timer** (OnUnitActiveSec=15) running poll.py as a oneshot service, not a daemon — simpler to debug, survives crashes trivially.
5. For a two-way bridge to another platform (e.g. Bale → Telegram), have poll.py also POST each new message to the destination platform's API and include the sender name, so the receiving agent can see who wrote it.

## Pitfalls
- Always persist `last_update_id` to state BEFORE or atomically with processing — re-reading the same updates on every poll is the classic failure.
- Telegram-compatible APIs (Bale is a near-clone): same method names and shapes; Bale base is `tapi.bale.ai`, Telegram is `api.telegram.org`.
- When reading a bot token from an env file in scripts, parse the exact `KEY=value` prefix — files contain commented example lines with the same key names.
- To find a user's Telegram chat_id without access to gateway logs: search the agent's session store for `"chat_id": "<digits>` — a prior conversation records it.
- System-level `systemctl` timers installed to `/etc/systemd/system` need `sudo`; restart the timer (not just the service) after editing the poll script.

## References
- `references/bale-bot-api.md` — Bale API endpoints, errors, SDK note.
