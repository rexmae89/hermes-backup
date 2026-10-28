# Bale bridge on this server

**Status: TORN DOWN** (inbound was unreliable platform-side; user abandoned it). Restore recipe:

Recreate these at `~/.hermes/bale_bridge/`:

- `poll.py` — one-shot long-poll (25s) of getUpdates; appends unseen messages as JSONL `{update_id, chat_id, sender, text}` to `queue.jsonl`, tracks `last_update_id` in `state.json`.
- `bale_send.py <chat_id> <text>` — sends one message.
- `bale-poll.service` + `bale-poll.timer` in /etc/systemd/system — runs poll.py every 15s.

## Operating

- Check messages: `cat ~/.hermes/bale_bridge/queue.jsonl` (delete consumed lines or drain by update_id offset).
- Reply: `python3 ~/.hermes/bale_bridge/bale_send.py <chat_id> '<text>'`.
- Logs: `systemctl status bale-poll.service`.
- Reinstall after server migration: copy the unit files back, `sudo systemctl daemon-reload && sudo systemctl enable --now bale-poll.timer`.
