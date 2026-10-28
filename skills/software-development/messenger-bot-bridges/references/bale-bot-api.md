# Bale Bot API quick reference

- Base: `https://tapi.bale.ai/bot<TOKEN>/<METHOD>` — Telegram Bot API clone; bot token from @BotFather **inside Bale** (not Telegram's).
- Methods verified working: `getMe`, `getUpdates` (long-poll via `timeout` param), `sendMessage`, `editMessageText`, `deleteMessage`, `setWebhook`.
- `sendMessage`: POST JSON `{"chat_id": <int>, "text": "..."}` with `Content-Type: application/json`.
- Errors: 401 bad token, 420 flood (space out bulk sends), 404 wrong chat_id.
- Docs: https://docs.bale.ai and OpenAPI spec at https://tapi.bale.ai/docs
- Python SDK alternative: `python-bale-bot` — but stdlib urllib + the two-script pattern is lighter and sufficient for bridges.
- **Unverified/new Bale bots can silently drop INCOMING messages**: sending works fine (sendMessage 200s) while getUpdates stays empty even with the user actively messaging — no error, no rate-limit code. When this pattern appears, test with a freshly created bot before debugging the poller; if the second bot works, the first is platform-restricted. Note the failure can recur on the replacement bot after a few messages too — Bale restricts unverified bots' receive path; user must verify the bot via dev.bale.ai/BotFather support.
- A bot cannot initiate conversation: `sendMessage` to a user who never /started it returns 403 `bot can't initiate conversation with a user`.
