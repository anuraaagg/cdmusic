# Bundled Google Fonts (Latin subsets)

Binary `.ttf` files here are produced by tooling, not hand-edited.

- **Licenses**: OFL — see respective families on [Google Fonts](https://fonts.google.com).
- **Fetch / convert** (requires `npm`, Python `fonttools` + `brotli`):

  ```bash
  python3 scripts/fetch_google_fonts.py
  ```

PostScript names used in Swift are listed in `GoogleFontNames.swift`. After fetching, confirm them against `scripts/google_font_postscript_names.json`.

- **Doto** is built from the variable Latin file (`@fontsource-variable/doto`, `doto-latin-full-normal`) with `fontTools.varLib.instancer` at **`wght=400`** and **`ROND=0`** (square-dot matrix). Bump `ROND` toward `100` for a more rounded look.
