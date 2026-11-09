#!/usr/bin/env sh
# Build a local `@preview` package root from `vendor/*/typst.toml` so that
# `typst compile --package-path <dir>` resolves `@preview/thyme:0.1.0` and
# `@preview/exemel:0.3.0` straight from the vendored sources — offline, and
# without patching the `#import "@preview/..."` lines in `site.typ` or `posts/`.
#
# Layout produced (same convention as thyme's own `just _link-pkg`):
#
#   <dir>/preview/<name>/<version> -> ../../vendor/<name>
#
# Usage:
#   sh ./scripts/link-packages.sh            # default output: .tmp-pkg
#   sh ./scripts/link-packages.sh .tmp-pkg   # explicit output directory
set -eu

CDPATH="" cd -- "$(dirname -- "$0")/.."

OUT="${1:-.tmp-pkg}"

case "$OUT" in
  "" | "." | ".." | "/")
    echo "link-packages: refusing to use '$OUT' as the output directory" >&2
    exit 1
    ;;
esac

[ -d vendor ] || { echo "link-packages: no vendor/ directory" >&2; exit 1; }

rm -rf "$OUT"
mkdir -p "$OUT/preview"

for manifest in vendor/*/typst.toml; do
  [ -f "$manifest" ] || continue
  pkg_dir="$(cd "$(dirname "$manifest")" && pwd)"
  pkg_name="$(sed -n 's/^name = "\(.*\)"$/\1/p' "$manifest")"
  pkg_ver="$(sed -n 's/^version = "\(.*\)"$/\1/p' "$manifest")"
  if [ -z "$pkg_name" ] || [ -z "$pkg_ver" ]; then
    echo "link-packages: $manifest has no top-level name/version" >&2
    exit 1
  fi
  mkdir -p "$OUT/preview/$pkg_name"
  ln -sfn "$pkg_dir" "$OUT/preview/$pkg_name/$pkg_ver"
  echo "link-packages: @preview/$pkg_name:$pkg_ver -> $pkg_dir"
done
