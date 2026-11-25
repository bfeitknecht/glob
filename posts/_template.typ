// Template for a new post. Not published: site.typ lists posts by hand.
// To start: copy to posts/<slug>.typ, fill the fields, then add
//   #post(path("posts/<slug>.typ")) <slug>
// at the top of the post list in site.typ (newest first).
#import "@preview/thyme:0.2.0": *
#import blog: *

#show: post.with(
  title: [Title],
  subtitle: [One line that says what the post is about],
  author: "Basil Feitknecht",
  // the next free number: bkf1 to bkf7 are taken
  monograph: "bkf8",
  created: datetime(year: 2026, month: 11, day: 25),
  // shown on the cards in /posts/ and /tags/; uncomment when the post is done
  // summary: [Two sentences: what the reader learns.],
  tags: ("tag",),
)

The first paragraph says the point. Everything after it supports it.

= A section <section>

Body text. Inline `code`, *bold*, _emphasis_, a #link("https://0xbf.ch")[link], a key #kbd[Ctrl+C], and a note in the margin#sn[Sidenotes fold into the text on narrow screens.].

#note[A callout. Also `tip`, `warning`, `important`.]

```nu
ls | where size > 1mb
```

= A table <table>

#booktab[
  | *Column* | *Column* |
  | --- | --- |
  | value | value |
]

#crosstab[
  | #" " | *A* | *B* |
  | --- | --- | --- |
  | *1* | x | y |
]

= A picture <picture>

// wide is for pictures and figures: they use the sidenote margin too.
// #wide[#image("picture.png")]
