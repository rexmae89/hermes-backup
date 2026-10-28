---
name: classifieds-price-lookup
description: "Use when checking current prices on classifieds sites."
version: 0.1.0
metadata:
  hermes:
    tags: [Prices, Shopping, Cars, Scraping]
---

# Classifieds Price Lookup

## When to Use

One-off "what does X cost right now" research across marketplace sites (used cars is the common case: dubizzle, dubicars, YallaMotor, Auto Trader UAE).

## Procedure

1. **Search snippets first.** `web_search` with `<make> <model> <year> price used <city> <sitename>`. YallaMotor and dubicars snippets often carry per-year min/max/average tables — these alone may answer the question.
2. **Extract category pages.** `web_extract` the site's category URL (e.g. `uae.dubizzle.com/motors/used-cars/volvo/s90/`). dubizzle is JS-heavy, but the extracted markdown contains every listing card's data — parse the saved file offline instead of loading a browser.
3. **Parse cards with execute_code.** See `references/dubizzle-card-parsing.md` for the exact regex recipe (dubizzle markdown double-escapes newlines; naive patterns silently return zero matches).
4. **Present grouped by year**, price + mileage + trim per listing, note regional spec (GCC-spec cars price above imports), give an approximate currency conversion, and end with the source category-page links.

## Pitfalls

- Don't hand-parse dubizzle markdown in your head — the escape sequences guarantee wrong matches; extract with regex in a scripted pass and dedupe by year+km+price (promoted cards repeat).
- Don't launch the browser tool for these sites: web_extract's saved markdown holds the full card data for dubizzle, and dubicars/YallaMotor are server-rendered.
- No model existed before its production launch year — sanity-check the requested year range against that before reporting "no listings".
