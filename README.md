# glob

Personal blog at [blog.0xbf.ch](https://blog.0xbf.ch), authored in pure [Typst](https://typst.app).

`site.typ` compiles with Typst `0.15.1` (`--features html,bundle --format bundle`) into one static
HTML + MathML + CSS + Tadi Web `.typ` bundle. The [`thyme`](https://github.com/bfeitknecht/thyme)
`blog` preset supplies the monochrome theme, typography, sidenotes, and feeds; `exemel` writes the
XML. Both packages are pinned under [`vendor/`](vendor/README.md) and linked into a local `@preview`
package root at compile time — neither version is on Typst Universe yet, so the build needs no
network and stays reproducible. The bundle ships inside a `FROM scratch` `static-web-server`
container as a tier-2 app on `bfeitknecht/infra` (same pattern as `apex`).

> **Status: frozen.** Content and code are complete. Only these changes are in scope now:
> syncing `vendor/thyme` to a new upstream commit, typo fixes inside posts, and the go-live steps in
> [`infra/README.md`](infra/README.md). No new features, and no theme, layout, or CSS work here —
> the monochrome palette, the `@font-face` descriptors, and the heading-id logic live upstream in
> `thyme`.

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
fonts/                               self-hosted STIX Two + Commit Mono .woff2 files + SHA256SUMS
vendor/thyme/                        pinned `thyme` 0.1.0 (upstream master, see vendor/README.md)
vendor/exemel/                       pinned `exemel` 0.3.0 (RSS 2.0 + sitemap; also unpublished)
scripts/sync-fonts.sh                fetches and verifies the upstream .woff2 fonts
scripts/link-packages.sh             exposes `vendor/*` as `.tmp-pkg/preview/<name>/<version>`
sws.toml                             static-web-server config (no-cache HTML, immutable css/fonts, inline .typ)
Dockerfile                           $BUILDPLATFORM typst bundle -> FROM scratch + static-web-server
justfile                             compile, sync-fonts, link-packages, serve, dev, watch, build, preview, release
infra/                               go-live manifests + runbook (delete after go-live)
.github/workflows/publish-image.yaml multi-arch image build, reusing bfeitknecht/infra
```

The four `draft` posts are committed but deliberately **not** mounted in `site.typ`: they are
reachable by URL only and stay out of the index, feeds, sitemap, and tag pages until they get a
`#post(...)` entry.

## Local workflow (`just`)

- `just compile` verifies `fonts/SHA256SUMS`, links `vendor/*` into `.tmp-pkg/`, and compiles
  `site.typ` into `public/` as a Bundle. `serve` and `watch` link the packages the same way, so
  `@preview/thyme` and `@preview/exemel` resolve from `vendor/` instead of the network.
- `just dev` compiles and serves `public/` on `http://localhost:8080`, mirroring `sws.toml`
  (`404.html`, inline `text/plain; charset=utf-8` for `.typ`, immutable caching for `css/`,`fonts/`).
- `just serve` runs Typst's own live-reloading bundle server.
- `just watch posts/impli.typ` gives a paged preview while writing a post.
- `just link-packages` rebuilds `.tmp-pkg/` alone (git-ignored; `vendor/README.md` has the details).
- `just build` / `just preview` build and run `ghcr.io/bfeitknecht/glob:dev` locally.
- `just release vX.Y.Z "message"` stages everything, commits, creates the annotated `v*` tag, and
  pushes. The tag is what publishes the image — see [Deploy](#deploy).

## Pins

| Piece | Pin | Where |
| --- | --- | --- |
| Typst | `0.15.1` (`html` + `bundle`) | `Dockerfile` (`TYPST_VERSION`), `justfile` |
| `thyme` | `0.1.0`, upstream master `ca01807` | `vendor/thyme/` |
| `exemel` | `0.3.0` | `vendor/exemel/` |
| static-web-server | `2.44.1` | `Dockerfile` |
| STIX Two | `v2.13b171` | `fonts/VERSIONS`, `fonts/SHA256SUMS` |
| Commit Mono | `1.143` | `fonts/VERSIONS`, `fonts/SHA256SUMS` |

## Deploy

The image is the only artifact: `.github/workflows/publish-image.yaml` runs on a `v*` tag (or by
hand with `gh workflow run publish-image.yaml`) and pushes a multi-arch
`ghcr.io/bfeitknecht/glob:latest` through the reusable workflow in `bfeitknecht/infra`. Keel polls
the registry and rolls the pod on the new digest.

The one-time cluster wiring — namespace, `ghcr.sops.yaml`, Flux `Kustomization` entry, and the
verification steps — is in [`infra/README.md`](infra/README.md). That whole directory is disposable
once the site is live.
