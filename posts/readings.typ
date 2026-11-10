#import "@preview/thyme:0.1.0": *
#import blog: *

// Draft. This post is not in `site.typ` yet.
#show: post.with(
  title: [Readings],
  subtitle: [Good things I have read lately],
  author: "Basil Feitknecht",
  created: datetime(year: 2026, month: 11, day: 9),
  modified: datetime(year: 2026, month: 11, day: 9),
  summary: [Draft: a list of recent readings that I update. These are good articles that I found and want to share.],
  tags: ("readings", "links"),
)

// Continually updated. Newest first.
//
// Entry format:
//
// - #link("https://example.com")[Title of the piece]. Author, year.
//   One line on why it is worth reading.
//
// TODO: add the first entries.
