# `vendor/`

Pinned copies of the Typst packages the site compiles against, so `glob` builds offline and can run
ahead of Typst Universe. `scripts/link-packages.sh` exposes them as a local `@preview` package root
(`typst compile --package-path .tmp-pkg`), so no `#import` line in `site.typ` or `posts/` has to
change and the `Dockerfile` downloads no packages at all.

| Package | Version | Source |
| --- | --- | --- |
| `thyme` | `0.1.0` | [`bfeitknecht/thyme`](https://github.com/bfeitknecht/thyme) master `ca01807` (merged PRs #1, #2, #3) |
| `exemel` | `0.3.0` | `thyme`'s own `vendor/exemel` — RSS 2.0 + sitemap support, not on Typst Universe yet |

Both are byte-for-byte copies: `src/` plus `typst.toml` and `LICENSE`, with nothing edited by hand.
That snapshot is what gives `glob`:

- rounded `oklch` palette tokens, so the CSS matches the documented sRGB values;
- unquoted `@font-face` descriptors, so text is no longer forced bold-italic;
- heading ids without the phantom `-2` suffix;
- `<meta name="theme-color">` derived from the palette (`#f2f2f2` light, `#0f0f0f` dark) instead of
  the old pinned `#101010`, on posts, pages, and the 404 page;
- a `robots.txt` that actually lands in the bundle (`robots: auto` follows `sitemap-path`); it was
  documented and exported upstream, but nothing ever called it;
- the bundle path resolving the preset theme once (`shell-theme`), a defect only the bundle target
  could expose — page-mode checks stayed green.

## Syncing to a new upstream commit

```sh
git clone https://github.com/bfeitknecht/thyme /tmp/thyme     # or: git -C /tmp/thyme pull
git -C /tmp/thyme rev-parse --short HEAD                      # record it in the table above
rm -rf vendor/thyme && mkdir -p vendor/thyme
git -C /tmp/thyme archive HEAD src typst.toml LICENSE | tar -x -C vendor/thyme
diff -r /tmp/thyme/src vendor/thyme/src                        # expect no output
sh scripts/link-packages.sh && just compile                    # the bundle must still build
```

`vendor/exemel/` comes from the same tree (`/tmp/thyme/vendor/exemel`). Copy it only when its
contents change, and keep its vendored `typst.toml` version in sync with the `@preview/exemel:…`
import in `vendor/thyme/src/seo.typ`. If upstream bumps `thyme`'s own version, update the version in
`vendor/thyme/typst.toml` **and** every `@import "@preview/thyme:…"` line plus `vendor/README.md`.

## When this goes away

Delete `vendor/` and drop `--package-path .tmp-pkg` from the `justfile` and the `Dockerfile` once
`@preview/thyme:0.1.0` and `@preview/exemel:0.3.0` are published on Typst Universe.
