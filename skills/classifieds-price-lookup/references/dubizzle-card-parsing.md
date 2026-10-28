# Parsing dubizzle listing cards from web_extract markdown

web_extract saves the full page markdown to a file (path in the result footer). Card data lives there, but the file renders the page's escaped newlines as literal `\\\n` sequences — plain-text regexes for line breaks return zero matches.

## Working pattern

```python
import re
t = open(saved_md_path).read()
# Anchor: each card has "**<year>**!<img alt>**<km> km**"
for m in re.finditer(r'\*\*(20\d\d)\*\*!\[[^\]]*\]\([^)]{0,120}\)\*\*([\d,]+ km)\*\*', t):
    seg = t[max(0, m.start()-4000):m.start()]   # look back for price + trim
    price = re.findall(r'AED\\\\\n\\\\\n([\d,]{5,8})', seg)      # quadruple backslash
    trim  = re.findall(r'\*\*<Model>\*\* \\\\\n\\\\\n\*\*([^*]+)\*\*', seg)
    title = re.findall(r'\*\*(AED[^*\n]{0,120}|20\d\d <Make>[^*\n]{0,120})\*\*', seg)
    print(m.group(1), m.group(2), price[-1] if price else '?', trim[-1] if trim else '?', title[-1] if title else '?')
```

## Key points

- Newlines are double-escaped in the saved file: in regex write `\\\\\n` (four backslashes + n), never `\n`.
- Price and trim appear ABOVE the year/km marker, sometimes several hundred chars earlier — take the LAST match in a wide (~4000 char) lookback window.
- The `featured` marker between price and make is optional — make it optional or you lose non-promoted listings.
- Dedupe by (year, km, price): promoted/featured cards render twice.
- Year-by-year market summaries: YallaMotor search snippets and dubicars category footers ("Used Volvo S90 2023 | 72,499") carry min/average tables without any scraping.