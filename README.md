# glob

Personal blog at [blog.0xbf.ch](https://blog.0xbf.ch), authored in pure [Typst](https://typst.app).

`site.typ` compiles with Typst `0.15.1` (`--features html,bundle --format bundle`) into one static
HTML + MathML + CSS + Tadi Web `.typ` bundle. The [`thyme`](https://github.com/bfeitknecht/thyme)
`blog` preset supplies the monochrome theme, typography, sidenotes, and feeds; `exemel` writes the
XML. Both come straight from Typst Universe as `@preview/thyme:0.1.0` and
`@preview/exemel:0.3.0` — the version pins in the `#import` lines are the whole dependency story, and
there is deliberately no local fallback. The bundle ships inside a `FROM scratch`
`static-web-server` container as a tier-2 app on `bfeitknecht/infra` (same pattern as `apex`).

> **Status: live and frozen.** The site is deployed. Only typo fixes inside posts are in scope now.
> No new features, and no theme, layout, or CSS work here — the monochrome palette, the `@font-face`
> descriptors, and the heading-id logic live upstream in `thyme`, so a change there is a version bump
> in the `#import` lines, not an edit in this repository.

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
├── calculator.typ                    draft — not mounted in site.typ
├── diagrams.typ                      draft — not mounted in site.typ
├── readings.typ                      draft — not mounted in site.typ
└── wishlist.typ                      draft — not mounted in site.typ
fonts/                               self-hosted STIX Two + Commit Mono .woff2 files, VERSIONS, SHA256SUMS
sws.toml                             static-web-server config (no-cache HTML, immutable css/fonts, inline .typ)
Dockerfile                           $BUILDPLATFORM typst bundle -> FROM scratch + static-web-server
justfile                             compile, check, fmt, sync-fonts, serve, watch, build, preview, release
.github/workflows/publish-image.yaml multi-arch image build, reusing bfeitknecht/infra
```

The four `draft` posts are committed but deliberately **not** mounted in `site.typ`: they are
reachable by URL only and stay out of the index, feeds, sitemap, and tag pages until they get a
`#post(...)` entry.

## Local workflow (`just`)

- `just compile` compiles `site.typ` into `public/` as a Bundle. It depends on
  `just check --fonts`, so the font checksums are verified on every build. The first run downloads
  `@preview/thyme:0.1.0`, `@preview/exemel:0.3.0`, `cheq`, `showybox`, `tablem`, `zebraw`, and
  `marge` into Typst's package cache.
- `just check` runs the repository checks — today that is `fonts/SHA256SUMS`, and `--fonts` limits
  it to exactly that. `compile` depends on it, so a bad font never reaches a build.
- `just fmt` rewrites the `justfile` in canonical form; `just fmt --check` only verifies it.
- `just sync-fonts` re-fetches the upstream `.woff2` files and rewrites `fonts/VERSIONS` and
  `fonts/SHA256SUMS`. It takes the versions as arguments (`just sync-fonts v2.14 1.144`), needs
  `fontTools` + `brotli` for the Commit Mono `.otf` → `.woff2` step (or `woff2_compress`), and
  refuses to finish if a download came back subsetted (no `smcp`/`c2sc`/`onum`/`MATH`).
- `just serve` runs Typst's own live-reloading bundle server on `http://localhost:8080`. That is
  the local preview; the production-only behaviour in `sws.toml` (`.typ` as `text/plain`, immutable
  caching for `css/` and `fonts/`, the custom `404.html`) comes from the container, via
  `just build && just preview`.
- `just watch posts/impli.typ` gives a paged preview while writing a post.
- `just build` / `just preview` build and run `ghcr.io/bfeitknecht/glob:dev` locally.
- `just release vX.Y.Z "message"` stages everything, commits, creates the annotated `v*` tag, and
  pushes. The tag is what publishes the image — see [Deploy](#deploy).

## Pins

| Piece | Pin | Where |
| --- | --- | --- |
| Typst | `0.15.1` (`html` + `bundle`) | `Dockerfile` (`TYPST_VERSION`), `justfile` |
| `thyme` | `0.1.0` | Typst Universe, pinned in the `#import` lines |
| `exemel` | `0.3.0` | Typst Universe, pinned in the `#import` lines |
| static-web-server | `2.44.1` | `Dockerfile` |
| STIX Two | `v2.13b171` | `fonts/VERSIONS`, `fonts/SHA256SUMS` |
| Commit Mono | `1.143` | `fonts/VERSIONS`, `fonts/SHA256SUMS` |

## Dependencies

The tree compiles with nothing but Typst `0.15.1` and whatever Typst Universe serves for the pins
above; there is no `vendor/` directory and no `--package-path` override. If a pinned version is not
on Typst Universe yet, `just compile` and the image build stop with a package-download error — that
is the intended signal, and the fix is to publish the package, not to re-introduce a local copy.

## Deploy

The image is the only artifact: `.github/workflows/publish-image.yaml` runs on a `v*` tag (or by
hand with `gh workflow run publish-image.yaml`) and pushes a multi-arch
`ghcr.io/bfeitknecht/glob:latest` through the reusable workflow in `bfeitknecht/infra`. Keel polls
the registry and rolls the pod on the new digest.

The cluster wiring — namespace, pull secret, Flux `Kustomization`, HTTPRoute — lives in
`bfeitknecht/infra` under `kubernetes/applications/glob/`; this repository holds no manifests for it.
