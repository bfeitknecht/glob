# vendor/

Pinned copies of the Typst packages the site compiles against, so `glob` builds
offline and previews unfinished upstream work. `scripts/link-packages.sh` exposes
them as a local `@preview` package root (`typst compile --package-path .tmp-pkg`),
so no `#import` line in `site.typ` or `posts/` has to change.

| Package | Version | Source |
| --- | --- | --- |
| `thyme` | `0.1.0` | [`bfeitknecht/thyme`](https://github.com/bfeitknecht/thyme) PR #1 (`1187b2d`) |
| `exemel` | `0.3.0` | `thyme`'s own `vendor/exemel` (RSS 2.0 + sitemap support, not yet on Typst Universe) |

The vendored `thyme` is a byte-for-byte copy of `src/` plus `typst.toml` and
`LICENSE` at that commit: the cleanup pass that rounds the palette tokens,
unquotes the `@font-face` descriptors, and fixes the phantom `-2` heading ids.
`vendor/` is never edited by hand — re-copy it from upstream instead:

```sh
rm -rf vendor/thyme && mkdir -p vendor/thyme
git -C ../thyme archive pr1 src typst.toml LICENSE | tar -x -C vendor/thyme
```

Delete `vendor/` and drop `--package-path .tmp-pkg` from `justfile`/`Dockerfile`
once `@preview/thyme:0.1.0` and `@preview/exemel:0.3.0` are published on Typst
Universe.
