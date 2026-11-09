#import "@preview/thyme:0.1.0": *
#import blog: *

#let _font-ver = (
  read("fonts/VERSIONS")
    .split("\n")
    .find(l => l.starts-with("FONT_CACHE_TAG="))
    .trim("FONT_CACHE_TAG=", at: start)
)

// Strictly achromatic `blog` palette: every token has zero OKLCH chroma and hue
// `0`, so it resolves to R = G = B in sRGB (the hex values in the comments).
// `@preview/thyme:0.1.0`'s built-in default palette is a *warm* off-monochrome
// (non-zero chroma at a yellow-green hue: the `#f4f3ef` / `#1d1d1b` / `#6d6b66`
// family), which tints every surface, hairline, and text tone. The lightness
// ladder below is upstream's own — only chroma is zeroed, so the site keeps its
// contrast while losing every trace of hue; spelling it out locally also means
// the palette stays grey no matter which release is pinned.
#let _mono-theme = (
  paper-light: oklch(99%, 0, 0deg), // #fcfcfc
  text-light: oklch(18%, 0, 0deg), // #121212
  muted-light: oklch(52%, 0, 0deg), // #696969
  border-light: oklch(89%, 0, 0deg), // #dbdbdb
  frame-light: oklch(20%, 0, 0deg), // #161616
  surface-1-light: oklch(96.5%, 0, 0deg), // #f3f3f3
  surface-2-light: oklch(93.5%, 0, 0deg), // #e9e9e9
  paper-dark: oklch(18%, 0, 0deg), // #121212
  text-dark: oklch(93%, 0, 0deg), // #e8e8e8
  muted-dark: oklch(65%, 0, 0deg), // #8f8f8f
  border-dark: oklch(29%, 0, 0deg), // #2b2b2b
  frame-dark: oklch(84%, 0, 0deg), // #cacaca
  surface-1-dark: oklch(22%, 0, 0deg), // #1b1b1b
  surface-2-dark: oklch(26%, 0, 0deg), // #242424
)

// Typst's built-in syntax-highlighting theme is polychrome, and `zebraw` copies
// those token fills verbatim into the HTML bundle as `style="color:#…"` spans —
// the one remaining source of hue inside `<pre>` blocks. Turning the raw theme
// off makes code inherit the surrounding `--fg` grey instead.
#show raw: set raw(theme: none)

#show: site.with(
  description: "Notes on programming languages, formal methods, systems, and sidequests.",
  url: "https://blog.0xbf.ch",
  author: "Basil Feitknecht",
  src: path("site.typ"),
  theme: (font-base: "/fonts/", font-version: _font-ver, .._mono-theme),
  stylesheets: (path("assets/mono.css"),),
  assets: default-woff2-files.map(f => (
    path: "fonts/" + f,
    data: read("fonts/" + f, encoding: none),
  )),
)

= `*glob?`

Notes on programming languages, formal methods, computer systems, and miscellaneous rabbit holes.

#links-row(
  link("https://0xbf.ch")[0xbf.ch],
  link("https://github.com/bfeitknecht")[github],
  [@rss[rss]],
  [@atom[atom]],
)

== Posts

#post(path("posts/designing-thyme.typ")) <designing-thyme>
#post(path("posts/rabbit-holes.typ")) <rabbit-holes>
#post(path("posts/list.typ")) <list>
#post(path("posts/gol/index.typ")) <gol>
#post(path("posts/trigraphs.typ")) <trigraphs>
#post(path("posts/yak-shaving.typ")) <yak-shaving>
#post(path("posts/impli.typ")) <impli>
