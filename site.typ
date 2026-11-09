#import "@preview/thyme:0.1.0": *
#import blog: *

#let _font-ver = (
  read("fonts/VERSIONS")
    .split("\n")
    .find(l => l.starts-with("FONT_CACHE_TAG="))
    .trim("FONT_CACHE_TAG=", at: start)
)

#show: site.with(
  description: "Notes on programming languages, formal methods, systems, and sidequests.",
  url: "https://blog.0xbf.ch",
  author: "Basil Feitknecht",
  src: path("site.typ"),
  theme: (font-base: "/fonts/", font-version: _font-ver),
  assets: default-woff2-files.map(f => (
    path: "fonts/" + f,
    data: read("fonts/" + f, encoding: none),
  )),
)

= `*glob?`

Notes on programming languages, formal methods, computer systems, and miscellaneous rabbit holes.

#links-row(
  link("https://0xbf.ch")[0xbf.ch],
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
