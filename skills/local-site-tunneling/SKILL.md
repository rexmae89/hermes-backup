---
name: local-site-tunneling
description: Use when exposing a locally running website via a public URL
---

# Local site preview + public tunneling

## When to Use
Use when the user wants to SEE a site you built or cloned on the server — there is no browser to hand them.

## Procedure

1. **Get the app running locally first.**
   - Cloned repos: `npm install && npm run build` to prove it builds, then run the server.
   - Next.js: `npm run start -- -p <port>` (requires a prior build). Dev fallback: `npm run dev`.
   - Vite: `npm run dev` (default port 5173). Static folder: `python3 -m http.server <port>` from the directory containing `index.html`.
2. **Start the server as a background terminal process**, never foreground — a foreground call that starts a long-lived server is rejected. For Next.js/Vite pass a notify pattern (`Ready in`, `Local:`); for plain static servers omit notify.
3. **Health-check in a SEPARATE foreground call**: `curl -s -o /dev/null -w "%{http_code}" http://localhost:<port>/` must return 200 before tunneling.
4. **Expose it with a cloudflared quick tunnel (no account, no firewall changes):**
   ```
   cloudflared tunnel --url http://localhost:<port> 2>&1 | tee <scratch_path>/cf_<port>.log
   ```
   Start it with `background=true` **without** `notify` (omit notify) — wait ~5–6s and grep the URL from the log file or read it with `process_manage(action='log')`. Do NOT use `notify: ['trycloudflare.com']` because banner output and reconnection logs match repeatedly and spam the chat with out-of-band alerts.
   If cloudflared is missing: download the static binary from cloudflare's GitHub releases (`cloudflared-linux-amd64`) to `/usr/local/bin`.
5. **Verify the tunnel from your own browser tools** (open the URL, check title/canvas), then report the URL to the user.
6. **Fallback when cloudflared quick tunnels fail: `npx -y localtunnel --port <port>`** (background process, URL printed to its log as `your url is: https://<words>.loca.lt`). Quick-tunnel provisioning can keep returning `quick tunnel provisioning failed with status 429` for many minutes even with clean retries, backoff sleeps, and `--no-autoupdate` — check the cloudflared log for 429 once, and if it repeats, switch to localtunnel immediately instead of burning turns on retries. Verify with `curl -s https://<url>` before sending; localtunnel may show an interstitial "Click to Continue" page to some users — mention it.

## Pitfalls
- **Do not use `nohup`, `&`, `disown`, or `setsid` in foreground terminal commands:** Hermes runtime actively blocks shell-level background wrappers and rejects foreground commands with an error. Always launch background tasks using the native tool parameter `terminal(command=..., background=true)`.
- **Capture quick tunnel URLs via `2>&1 | tee <log_path>`:** Cloudflared outputs its human-readable banner containing `https://*.trycloudflare.com` to stderr, not standard stdout, and `--logfile` switches to structured format where grepping can lag or fail. Running `cloudflared tunnel --url http://localhost:<port> 2>&1 | tee <log_path>` in a background process allows reliable grepping of the URL after ~5s.
- **Do not use `notify: ['trycloudflare.com']` when starting cloudflared in the background:** The cloudflared startup banner and reconnect logs match that string repeatedly, generating multiple disruptive out-of-band notifications mid-turn. Always launch cloudflared silently (`background=true` without notify), wait 4–6s, and read the URL via `process_manage(action='log')`.
- **Quick-tunnel URLs are temporary and change on every server restart.** When all links die after a restart, re-launch servers AND tunnels, re-read each new URL from the tunnel logs, and re-verify with curl before sending them. For a permanent address the user needs a named tunnel + domain — say so, don't retry quick tunnels expecting stability.
- **Vite rejects unknown Host headers** ("Blocked request. This host is not allowed") when accessed through a tunnel domain. Fix in `vite.config.js`: add `allowedHosts: true` to `server`. Restart the dev server after editing the config — verify with curl before claiming the fix worked. (Same class of issue: a Vite dev server also 200s on localhost but blocks on the tunnel host until this is set.)
- **Run the tunnel and the server as separate background processes**; a tunnel started in the same foreground call as the server hangs the call.
- Tunnel log noise like "stream canceled by remote" while large assets (GLB, video) load is a browser aborting mid-download, not an outage — confirm with a curl of the exact asset URL before investigating.
- Always verify externally-visible behavior yourself (browser tool or curl through the public URL) before telling the user it works.

## Updating a cloned repo (git) that is live
- Local copy may not be a git repo (unzipped/older import). If `git pull` fails with "not a git repository", move the old dir aside (`mv <dir> <dir>.bak`) and `git clone` fresh into `~/<project-name>`, then re-apply any local config patches (e.g. `allowedHosts`) that were hand-made earlier — a fresh clone loses them.
- When pulling into a repo with local edits, `git stash` first, pull, then `git stash pop` to restore the local patches; Vite dev server auto-restarts on config/file changes — verify with curl rather than restarting manually.

## Ports
Use distinct stable ports per concurrent site (e.g. 3010, 3020, 5173). Several tunnels may run in parallel, one per port.

## Multi-site sessions

- **Track each site's triple (repo dir, port, tunnel session) and re-verify all of them after any downtime.** When the user reports links are down, curl each port first, restart the dead servers with the same notify patterns, then start fresh tunnels and re-read every new URL from the logs — never resend old URLs.
- **Tunnel URLs change every restart; old links in the chat are stale by definition.** Re-read each URL from its tunnel log and re-verify with curl through the public URL before telling the user which link is live.
- **Keep persistent projects in `~/<project-name>`, not in `/tmp` or `~/.hermes/cache/scratch/`:** The scratch dir prunes entries idle for 24 hours and `/tmp` is wiped on reboot or system cleanup.
- **Missing native binaries when unpacking archives with existing `node_modules`:** Projects created or zipped on Windows often fail on Linux with errors like `Cannot find module @rollup/rollup-linux-x64-gnu`. Run `npm install --no-audit --no-fund` to pull the host platform's native optional dependencies before running build/dev.
- **Terminate previous tunnels when replacing or refreshing a site version:** When the user uploads an updated site zip or asks to refresh/relaunch, kill the old web server and its associated `cloudflared` process (e.g. `pkill -f "cloudflared tunnel --url http://localhost:<old_port>"`). An orphaned cloudflared tunnel remains connected to Cloudflare Edge, and when users click older links in the chat history, it emits loud `connection refused` error logs mid-turn.
- **A `pkill -f vite` to restart one server kills EVERY Vite dev server on the host** (multi-site sessions run several). Scope kills by port or PID (`fuser -k <port>/tcp` or kill the specific PID), and re-verify ALL sites' ports with curl after any kill — the other site's server dies silently and the user notices before you do.
- **Rate-limit caveat for quick tunnels on a shared IP: provisioning returns `429` repeatedly when another tunnel was just torn down.** Backoff ~60s, then retry once; if the second attempt also 429s, fall through to the localtunnel fallback instead of looping.
- When relaunching several servers/tunnels at once, start them in one batched turn (parallel background calls), then verify all ports with a single curl loop.