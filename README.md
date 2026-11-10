# glob

Personal blog at [blog.0xbf.ch](https://blog.0xbf.ch), written in [Typst](https://typst.app).

`site.typ` compiles with Typst `0.15.1` (`--features html,bundle --format bundle`) into one static
bundle: HTML, MathML, CSS, and the Tadi Web `.typ` sources. The
[`thyme`](https://github.com/bfeitknecht/thyme) `blog` preset supplies the monochrome theme, the
typography, the sidenotes, and the feeds. `exemel` writes the XML. Both packages come from Typst
Universe, as `@preview/thyme:0.1.0` and `@preview/exemel:0.3.0`. The version in each `#import` line
is the only dependency setting, and the repository holds no local copy of these packages.

The bundle runs inside a `FROM scratch` `static-web-server` container. It is a tier-2 app on
`bfeitknecht/infra` and uses the same pattern as `apex`.

> **Status: live and frozen.** The site is deployed. The repository accepts typo fixes in posts, and
> no other changes. Theme, layout, and CSS work belong to `thyme`: change the version in the
> `#import` lines to get such a change.

## Layout

```text
site.typ                             homepage (<site>), feeds, sitemap, robots.txt, and mounted posts
posts/                               standalone `.typ` files, or a directory when co-locating assets
├── designing-thyme.typ               Designing thyme
├── rabbit-holes.typ                  New Rabbit Holes Await (bkf6)
├── list.typ                          Feitk's List (bkf5)
├── gol/
│   ├── index.typ                     SVG runs GOL with JS (bkf4)
│   └── gol.svg                       co-located interactive Conway's Game of Life SVG
├── trigraphs.typ                     Try Some Trigraphs! (bkf3)
├── yak-shaving.typ                   Yak Shaving Utensils & Co. (bkf2)
├── impli.typ                         `impli`, My Beloved (bkf1)
├── calculator.typ                    draft (not in site.typ)
├── diagrams.typ                      draft (not in site.typ)
├── readings.typ                      draft (not in site.typ)
└── wishlist.typ                      draft (not in site.typ)
fonts/                               self-hosted STIX Two + Commit Mono .woff2 files, VERSIONS, SHA256SUMS
sws.toml                             static-web-server config (no-cache HTML, long cache for css/fonts, inline .typ)
Dockerfile                           $BUILDPLATFORM typst bundle -> FROM scratch + static-web-server
justfile                             compile, check, fmt, serve, watch, image, run, release
.github/workflows/publish-image.yaml multi-arch image build, using bfeitknecht/infra
```

The four drafts are in the repository, but `site.typ` does not mount them. You can open them by URL
only. They stay out of the index, the feeds, the sitemap, and the tag pages until they get a
`#post(...)` entry.

## Commands

- `just compile` renders `site.typ` into `public/` as a bundle. The first run downloads
  `@preview/thyme:0.1.0`, `@preview/exemel:0.3.0`, `cheq`, `showybox`, `tablem`, `zebraw`, and
  `marge` into the Typst package cache.
- `just check` checks the repository. `just check --fonts` checks only the self-hosted fonts, and
  `compile` runs that check before it starts. If a `.woff2` file does not agree with
  `fonts/SHA256SUMS`, the recipe downloads the pinned versions (`stix_version` and
  `commit_mono_version` at the top of the `justfile`), writes `fonts/VERSIONS` and
  `fonts/SHA256SUMS` again, and repeats the check. To update the fonts, change those two values. The
  download needs `fontTools` and `brotli` for the Commit Mono `.otf` to `.woff2` step, or the
  `woff2_compress` program. The recipe stops if a download has no `smcp`, `c2sc`, `onum`, or `MATH`
  table.
- `just fmt` writes the `justfile` in the standard form. `just fmt --check` only checks the form.
- `just serve` serves the bundle on `http://localhost:8080` and reloads it after each change. The
  headers in `sws.toml` (`.typ` as `text/plain`, long cache for `css/` and `fonts/`, the custom
  `404.html`) apply in the container only.
- `just watch posts/impli.typ` shows a paged preview of one post.
- `just image` builds the container image locally, with the tag `ghcr.io/bfeitknecht/glob:dev`.
  `just run` starts that image on port 8080. Use these two commands to test the `sws.toml` headers
  before a deploy.
- `just release vX.Y.Z "message"` stages all files, commits, makes the annotated `v*` tag, and
  pushes. The tag starts the image build. See [Deploy](#deploy).

## Pins

| Piece | Pin | Where |
| --- | --- | --- |
| Typst | `0.15.1` (`html` + `bundle`) | `Dockerfile` (`TYPST_VERSION`), `justfile` |
| `thyme` | `0.1.0` | Typst Universe, pinned in the `#import` lines |
| `exemel` | `0.3.0` | Typst Universe, pinned in the `#import` lines |
| static-web-server | `2.44.1` | `Dockerfile` |
| STIX Two | `v2.13b171` | `justfile` (`stix_version`), recorded in `fonts/VERSIONS` |
| Commit Mono | `1.143` | `justfile` (`commit_mono_version`), recorded in `fonts/VERSIONS` |

## Dependencies

The build needs Typst `0.15.1` and the pinned packages from Typst Universe. The repository has no
`vendor/` directory and no `--package-path` option. If a pinned version is not on Typst Universe,
`just compile` and the image build stop with a package-download error. Publish the package to
continue the build. Do not add a local copy.

## Deploy

`.github/workflows/publish-image.yaml` runs on a `v*` tag, or by hand with
`gh workflow run publish-image.yaml`. It pushes a multi-arch `ghcr.io/bfeitknecht/glob:latest`
through the reusable workflow in `bfeitknecht/infra`. Keel reads the registry and rolls the pod to
the new digest.

The cluster manifests (namespace, pull secret, Flux `Kustomization`, HTTPRoute) are in
`bfeitknecht/infra`, in `kubernetes/applications/glob/`. This repository has no manifests.
