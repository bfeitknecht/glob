# glob

Personal blog at [blog.0xbf.ch](https://blog.0xbf.ch). Authored in pure [Typst](https://typst.app) (`>= 0.15.1`) using `@preview/thyme:0.1.0` (with its `blog` preset) and `@preview/exemel:0.3.0` (`sitemap-encode`, `atom-encode`, `rss-encode`). Both packages are pinned under `vendor/` (see [`vendor/README.md`](vendor/README.md)) and linked into a local `@preview` package root at compile time, because neither version is on Typst Universe yet — so the build is offline and reproducible. The site is compiled into a static HTML + MathML + CSS + Tadi Web `.typ` bundle, and shipped inside a `FROM scratch` `static-web-server` container (tier-2 app on `bfeitknecht/infra`, matching `apex`).

## Layout

```text
site.typ                             homepage (<site>), feeds, sitemap, and mounted posts
posts/                               standalone `.typ` files, or a directory when co-locating assets
├── designing-thyme.typ               Designing thyme
├── rabbit-holes.typ                 New Rabbit Holes Await (bkf6)
├── list.typ                         Feitk's List (bkf5)
├── gol/
│   ├── index.typ                    SVG runs GOL with JS (bkf4)
│   └── gol.svg                      co-located interactive Conway's Game of Life SVG
├── trigraphs.typ                    Try Some Trigraphs! (bkf3)
├── yak-shaving.typ                  Yak Shaving Utensils & Co. (bkf2)
└── impli.typ                        `impli`, My Beloved (bkf1)
fonts/                               self-hosted STIX Two + Commit Mono .woff2 files + SHA256SUMS
vendor/thyme/                        pinned `thyme` package (upstream PR #1: palette, @font-face, heading ids)
vendor/exemel/                       pinned `exemel` 0.3.0 (RSS 2.0 + sitemap support, not on Typst Universe yet)
scripts/sync-fonts.sh                fetches and verifies upstream .woff2 fonts
scripts/link-packages.sh             exposes `vendor/*` as `.tmp-pkg/preview/<name>/<version>` for `--package-path`
sws.toml                             static-web-server config (no-cache HTML, immutable css/fonts, inline .typ)
Dockerfile                           $BUILDPLATFORM typst bundle -> FROM scratch + SWS
justfile                             compile, sync-fonts, serve, dev, watch, build, preview, release
.github/workflows/publish-image.yaml calls bfeitknecht/infra reusable multi-arch build
infra/                               ready-to-copy manifests for bfeitknecht/infra
```

## Local Workflow (`just`)

- `just compile` compiles `site.typ` into `public/` after verifying `fonts/SHA256SUMS`; `compile`, `serve`, and `watch` all run `scripts/link-packages.sh` first and pass `--package-path .tmp-pkg`, so `@preview/thyme` and `@preview/exemel` resolve from `vendor/` (no network, no package downloads).
- `just link-packages` rebuilds `.tmp-pkg/` alone (`.tmp-pkg/` is git-ignored).
- `just dev` compiles `site.typ -> public/` and serves it on `http://localhost:8080` matching `sws.toml` (`404.html` + inline `text/plain; charset=utf-8` `.typ` sources).
- `just serve` runs Typst's built-in live-reloading `typst watch --features html,bundle -f bundle` server.
- `just watch posts/impli.typ` opens a live paged preview while editing a post.
- `just build` / `just preview` builds and runs `ghcr.io/bfeitknecht/glob:dev` (`http://glob-preview.orb.local:8080` on OrbStack).
- `just release v0.1.0 "initial release"` stages, commits, creates an annotated `v*` tag, and pushes to `origin`; GitHub Actions publishes `ghcr.io/bfeitknecht/glob:latest` (`linux/amd64,linux/arm64`) and Keel updates the pod in-cluster.

## Wiring into `bfeitknecht/infra` (One-Time Setup)

1. Copy `infra/glob/` into `kubernetes/applications/glob/` inside `bfeitknecht/infra`.
2. Create `kubernetes/applications/glob/ghcr.sops.yaml` from `apex/ghcr.sops.yaml` with `namespace: glob`:
   ```sh
   sops -d kubernetes/applications/apex/ghcr.sops.yaml \
     | sed 's/namespace: apex/namespace: glob/' \
     > kubernetes/applications/glob/ghcr.sops.yaml
   sops -e -i kubernetes/applications/glob/ghcr.sops.yaml
   ```
3. Append `infra/applications-entry.yaml` to `kubernetes/cluster/applications.yaml` (includes `spec.ignore` on `/spec/template/spec/containers/0/image` for Keel).
4. Commit and push a `vX.Y.Z` tag in `infra`. Wildcard DNS (`*.0xbf.ch`) and `wildcard-domain-tls` on `traefik-gateway` (`websecure`) already cover `blog.0xbf.ch` with zero DNS changes.
