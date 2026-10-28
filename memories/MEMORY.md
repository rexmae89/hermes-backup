User's custom LLM router "9router": base https://9router-production-7a08.up.railway.app/v1 — key lives in the Hermes env file as NINE_ROUTER_API_KEY, registered in config.yaml as providers.9router (chat_completions, ~563 models). Aliases: 9gpt=cl/openai/gpt-5.1, 9claude=cl/anthropic/claude-sonnet-4.5, 9free=Free, 9gemini=Gemini. Panel combo models (Test/Cloud) can 503/410 — upstream-dependent; gpt-5.1/claude-sonnet-4.5/Free verified working.
§
Hermes gotcha: the /model picker lists models from `providers:` entries in config.yaml, NOT from `model_aliases` — aliases only resolve for direct `/model <name>` switching and never appear in the picker list. To expose a custom endpoint in the picker, register it under `providers.<name>` (name, base_url, key_env, api_mode). After config.yaml changes the running gateway must be restarted (/restart) to pick up new aliases/providers.
§
TheBurger 3D site: cloned github.com/saurrabhs/theburger to ~/.hermes/cache/scratch/theburger (Next.js + React Three Fiber, Lenis + GSAP scroll-driven 3D burger). npm build OK; runs with `npm run start -- -p 3010`. It's a dynamic Next.js app — NOT deployable on static Vela hosting; needs Vercel or own server w/ nginx.
§
Server/projects: burger 3D sites running on server 161.120.186.93 (SSH/external ports blocked by upstream firewall; outbound works). Local: theburger (Next.js, option #4) on port 3010 via `npm run start` in ~/.hermes/cache/scratch/theburger; hamburger-decomp (vanilla JS, option #5) on port 3020 via python http.server. Public links via `cloudflared tunnel --url http://localhost:PORT` (quick tunnels, temporary, new URL each restart). Vercel CLI installed at ~/.local/bin/vercel (npm -g needs --prefix ~/.local); login was pending device-code auth (user declined). Next.js apps can't go on Vela static hosting.
§
User (Noyan) is building a burger-shop website. Design preference: scroll-animated UI (objects animate on scroll) BUT short/concise — hates long scroll-jacking; wants burger explode animation confined to ~1 hero screen, menu reachable fast with stacked cards, light fade/parallax elsewhere, persistent Order button. References liked: saurrabhs/theburger (3D GLB layers), smford/hamburger-decomp, burgerfuel.com ticker style. Awaiting his own site's HTML to integrate.
§
Keratin Darya project: Static Persian salon site (Darya Sajjadi, keratin artist) located at ~/keratin-darya-site-contact-updated (earlier iterations in ~/keratin-darya-site and ~/keratin-darya-site-royal). Served on port 3060 via python3 -m http.server and exposed via cloudflared quick tunnels. Config.yaml has 9router models registered under providers (16 curated + 30 prefixed with r9-).
§
Local projects on server:
- Burger Guys: `/home/agentuser/burgerguys` (React + Vite, port 5173 with allowedHosts: true in vite.config.js).
- Keratin Darya: `/home/agentuser/keratin-darya-site-ready-to-publish` (static, port 3090).
9router models: 30+ models configured under `providers.` in `~/.hermes/config.yaml` (`9gpt51`, `9opus45`, `r9-*`) so they populate the `/model` picker.
Divar scraper: Divar blocks raw API/curl with 503; use `browser_exec` navigating to `https://divar.ir/s/<city>/...` and read cards via DOM.
§
Burger Guys site: repo github.com/rexmae89/burgerguys cloned to /home/agentuser/burgerguys (React+Vite). Run: npm run dev on port 5173 with allowedHosts:true in vite.config.js (REQUIRED or Cloudflare tunnel shows 'Blocked request'). Public link via `cloudflared tunnel --url http://localhost:5173` quick tunnel — NEW URL every restart, tunnels die within a day or so; check `pgrep -x cloudflared` before quoting an old link. Old pre-git copy kept at /home/agentuser/burgerguys.bak.
§
Instagram downloads: yt-dlp handles reel thumbnails/videos only; image posts/slideshows need the browser workflow (documented in video-content-analysis skill). Real slides = img elements with naturalWidth>=800; never modify CDN URL query params (signature 403s).