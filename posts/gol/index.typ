#import "@preview/thyme:0.1.0": *
#import blog: *

#show: post.with(
  title: [SVG runs GOL with JS],
  subtitle: [Self-contained cellular automata inside a single scalable vector graphic],
  author: "Basil Feitknecht",
  monograph: "bkf4",
  created: datetime(year: 2026, month: 3, day: 16),
  modified: datetime(year: 2026, month: 10, day: 27),
  summary: [Embedding an interactive 60×30 Conway's Game of Life simulation directly inside an SVG via `<script>` and `<foreignObject>`.],
  tags: ("svg", "javascript", "automata"),
  assets: (
    (
      path: "gol.svg",
      data: read("gol.svg", encoding: none),
      label: <gol-svg>,
    ),
  ),
)

#context {
  if target() == "html" {
    html.elem(
      "figure",
      attrs: (class: "blog-diagram"),
      {
        html.elem(
          "object",
          attrs: (
            type: "image/svg+xml",
            data: "gol.svg",
            "aria-label": "Conway's Game of Life in SVG",
            style: "width: 100%; aspect-ratio: 720 / 392; display: block; border-radius: 6px; border: 1px solid var(--line);",
          ),
          [Conway's Game of Life in SVG (#link("gol.svg")[open `gol.svg`]).],
        )
        html.elem(
          "figcaption",
          [Click or drag to spawn live cells; toggle `pause`, `step`, `clear`, or `randomize` in the top bar.],
        )
      },
    )
  } else {
    example[Interactive SVG Canvas (`gol.svg`)][
      In the HTML bundle, co-located `gol.svg` runs a live $60 times 30$ toroidal Conway's Game of Life board at 10 FPS inside an `<object type="image/svg+xml">` element.
    ]
  }
}

Apparently, scalable vector graphics files can run JavaScript via `<script>` tags#sidenote[Self-hosted here on `blog.0xbf.ch`, @gol-svg[`gol.svg`] lives right inside `posts/gol/` and is mounted via `<object type="image/svg+xml" data="gol.svg">` above so its `<script>` runs live in the page.]. It probably runs Doom too, but I've never implemented Conway's Game of Life, so that's what you get instead. You need to download and open in your own browser to see it in action due to security settings from GitHub disabling these tags to run.

#zebraw(
  ```bash
  curl -LO "https://blog.0xbf.ch/posts/gol/gol.svg"
  open -a Safari.app gol.svg
  ```,
)
