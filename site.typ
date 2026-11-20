#import "@preview/thyme:0.1.2": *
#import blog: *

// `just check --fonts` writes `fonts/SHA256SUMS`. The bundle gets exactly the files in it.
#let _font-files = (
  read("fonts/SHA256SUMS").split("\n").map(l => l.split(" ").last()).filter(f => f.ends-with(".woff2"))
)

#let _font-ver = (
  read("fonts/VERSIONS").split("\n").find(l => l.starts-with("FONT_CACHE_TAG=")).trim("FONT_CACHE_TAG=", at: start)
)

#show: site.with(
  description: "Notes on programming languages, formal methods, systems, and sidequests.",
  url: "https://blog.0xbf.ch",
  author: "Basil Feitknecht",
  src: path("site.typ"),
  // Reading-time estimate (`· <n> min`) beside the date on the entry cards.
  show-reading: true,
  // The mark from apex (ssg/favicon.typ there). Copy it again when it changes.
  favicon: path("favicon.svg"),
  robots: path("robots.txt"),
  llms: path("llms.txt"),
  theme: (font-base: "/fonts/", font-version: _font-ver),
  assets: _font-files.map(f => (
    path: "fonts/" + f,
    data: read("fonts/" + f, encoding: none),
  )),
)

= `*glob?`

Notes on programming languages, formal methods, computer systems, and miscellaneous rabbit holes.

== Posts

#post(path("posts/designing-thyme.typ")) <designing-thyme>
#post(path("posts/rabbit-holes.typ")) <rabbit-holes>
#post(path("posts/list.typ")) <list>
#post(path("posts/gol/index.typ")) <gol>
#post(path("posts/trigraphs.typ")) <trigraphs>
#post(path("posts/yak-shaving.typ")) <yak-shaving>
#post(path("posts/impli.typ")) <impli>

#html.footer(links(
  link("https://0xbf.ch")[0xbf.ch],
  [@rss[rss]],
  [@atom[atom]],
))

// Root fallbacks: Safari, iOS and tools ask for these without a <link>.
// Rendered from favicon.svg (the round mark).
#file("favicon.ico", path("favicon.ico"))
#file("apple-touch-icon.png", path("apple-touch-icon.png"))
