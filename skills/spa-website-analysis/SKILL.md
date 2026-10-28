---
name: spa-website-analysis
description: "Use when analyzing a website's stack, routes, APIs, trust."
version: 1.0.0
---

# SPA Website Analysis

Procedure for a full technical + trust breakdown of an unfamiliar site, reported in the user's language.

## Procedure

1. **Load the site in the browser** (`new_tab(url)`, `wait_for_load`, `page_info`). If a SPA route throws `Inspected target navigated or closed` on first navigation, just retry with `goto_url` — first-load redirect races are common.
2. **Read what renders:** `js("document.body.innerText")` for content. Then pull `a[href]`, `script[src]`, and all `meta` tags in one `js()` call — meta often reveals og:description, robots directives, and asset hosts.
3. **Identify the stack from the JS bundle**, not from page text: `curl` the main `index-*.js` and count keyword hits (`vue`, `react`, `createApp`, `pinia`, `pinia`, `vant`, `element-plus`, `axios`, `tailwind`, `swiper`). The index HTML's asset filenames confirm the bundler (hashed names = Vite/Webpack) and libraries (e.g. `vuex-*.js`, `vue-i18n-*.js` files).
4. **Enumerate routes** with `re.findall(r'path:"(/\\w+[^"]*)"', bundle)` on the downloaded JS — SPA nav links often don't render as `<a href>` so grep the router table instead. Hash routes (`#/x`) may not navigate via `goto_url`; try history-mode URLs, then clicking the nav element via JS.
5. **Enumerate the API surface:** `re.findall(r'["\'](/api/[^"\']{2,50})["\']', bundle)` — this lists every backend endpoint the frontend knows, which maps the full feature set (wallet, KYC, referral, etc.) better than visible pages. Probe a few public GET endpoints with curl to confirm the backend framework (JSON formatting quirks hint at Java/Spring vs Node).
6. **Infrastructure:** `dig` A records (CDN?), `openssl s_client` for cert issuer/dates, `curl -sI` for server headers, and grep the bundle for external hosts (S3 buckets, API subdomains).
7. **Trust assessment** when the site is finance/investment-related: mandatory invite/referral codes, internal token with self-controlled price, task/wheel/airdrop gamification, MLM team levels, `noindex` meta, cheap TLD, unofficial APK downloads, unverifiable license claims. Any 3+ together = likely scam; say so plainly.
8. **Report** in the user's language with sections: identity, tech stack, pages/features, backend API map, infrastructure, trust verdict.

## Pitfalls

- Don't conclude "route doesn't exist" from `goto_url` showing the home page — SPA fallbacks render home for unknown paths. Verify against the router table extracted from the bundle.
- Bash-style subprocess code inside `browser_exec` must use `capture_output=True` and access `.stdout`, not `.text` (browser_exec runs full Python, not shell).
- `js()` has no `await_promise` kwarg; for fetch-inside-page use curl from the terminal instead.
- Expect one or two tool-call syntax errors per session on this workflow; fix and continue rather than abandoning the analysis.
