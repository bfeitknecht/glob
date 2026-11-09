#import "@preview/thyme:0.1.0": *
#import blog: *

// Draft — not mounted in `site.typ` yet.
#show: post.with(
  title: [Wishlist],
  subtitle: [Things I want and will cherish],
  author: "Basil Feitknecht",
  created: datetime(year: 2026, month: 11, day: 9),
  modified: datetime(year: 2026, month: 11, day: 9),
  summary: [Draft: a list of things I want and will cherish.],
  tags: ("wishlist",),
)

#checklist[
  - [ ] Swatch (model TBD)
  // TODO: more items
]
