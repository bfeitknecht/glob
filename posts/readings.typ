#import "@preview/thyme:0.1.0": *
#import blog: *

// Draft — not mounted in `site.typ` yet.
#show: post.with(
  title: [Readings],
  subtitle: [Good things I have read lately],
  author: "Basil Feitknecht",
  created: datetime(year: 2026, month: 11, day: 9),
  modified: datetime(year: 2026, month: 11, day: 9),
  summary: [Draft: a continually updated list of recent readings — good articles I have come across and want to share.],
  tags: ("readings", "links"),
)

// Continually updated. Newest first.
//
// Entry format:
//
// - #link("https://example.com")[Title of the piece] — Author, year.
//   One line on why it is worth reading.
//
// TODO: add the first entries.
