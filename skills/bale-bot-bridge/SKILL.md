---
name: bale-bot-bridge
description: Use when connecting to the Bale messenger via its Bot API.
---

# Bale Bot API (بله)

Bale exposes a Telegram-Bot-API clone at `https://tapi.bale.ai`. Bot creation is via @BotFather in Bale; the user supplies the token.

## Procedure

1. Verify the token before anything else:
   `curl -s https://tapi.bale.ai/bot<token>/getMe` — expect `"ok":true` with the bot username.
2. Read updates with long polling: `curl -s 'https://tapi.bale.ai/bot<token>/getUpdates'` (supports `offset` like Telegram; `update_id` starts at 1).
3. Send with JSON POST: `POST /bot<token>/sendMessage` `{"chat_id": <int>, "text": "..."}`. The first successful reply's `chat.id` in getUpdates is the user's private chat id — save it; it stays valid.
4. For a persistent bridge, a systemd-timer design is proven (see references/bridge.md — teardown/restore recipe there; the files are not currently installed).

## Pitfalls

- Do NOT promise reliable inbound delivery on Bale. Even after a bot works initially (user /starts, a couple of messages arrive), Bale has been observed silently cutting off inbound for unsigned/new bots — getUpdates stays empty (even with `offset=0`, even during a 30-40s long poll) while sendMessage keeps succeeding, with no error. A brand-new bot only delayed this, not fixed it. Treat receive as unreliable until proven over a longer window; sending always works.

- getUpdates returns an empty result until the user has sent the bot at least one message (/start) — don't conclude the token is broken before checking that.
- A user-facing assistant can only be a BOT on Bale, never a personal account; frame the deliverable as a bot the user talks to, not a DM from the agent.
- The runtime agent does not self-notify on new Bale messages — a polling bridge is pull-based: the user (or a cron) must trigger the agent to read the queue. Set this expectation up front instead of promising real-time replies. Mitigation: have poll.py forward each new message to the agent's primary chat (e.g. Telegram sendMessage using the token from ~/.hermes/.env) so the user only needs ONE reachable platform, not both.
- Send and receive are independent paths: if sendMessage succeeds but getUpdates stays empty even with `offset=0` right after the user says they sent a message, the bot's inbound is restricted platform-side — no code fix helps. Diagnose with `getWebhookInfo` (url must be empty) and `getChat?chat_id=<id>`; if both are clean and updates are still empty, the fix is a NEW bot (@BotFather) the user /starts, not debugging the API.
- A brand-new bot gets 403 "bot can't initiate conversation" on sendMessage — the user must /start it first; don't read that error as a broken token.
- The receive-cutoff recurs even on a fresh replacement bot after a handful of messages — replacing the bot mitigates but does not permanently fix inbound; treat Bale inbound as unreliable for unsigned bots and say so when delivering the bridge.
- A user's private chat_id is NOT constant across bots: each bot sees its own id for the same person, so re-capture chat_id from the new bot's first getUpdates rather than reusing the old one.
