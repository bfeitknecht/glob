default:
    @just --list

# Compile site.typ -> public/ HTML bundle (after verifying fonts/SHA256SUMS)
compile:
    #!/usr/bin/env sh
    set -eu
    sh ./scripts/sync-fonts.sh --check >/dev/null
    sh ./scripts/link-packages.sh >/dev/null
    rm -rf public
    typst compile --package-path .tmp-pkg --features html,bundle --format bundle site.typ public

# Fetch/update upstream STIX Two + Commit Mono .woff2 web fonts and regenerate SHA256SUMS
sync-fonts:
    sh ./scripts/sync-fonts.sh

# Live-reloading bundle server via Typst 0.15's built-in `typst watch -f bundle`
serve port="8080":
    #!/usr/bin/env sh
    set -eu
    sh ./scripts/link-packages.sh >/dev/null
    typst watch --package-path .tmp-pkg --features html,bundle --format bundle --port "{{port}}" site.typ public

# Compile and serve public/ straight from disk matching static-web-server (`sws.toml` .typ headers + 404.html)
dev: compile
    #!/usr/bin/env python3
    """Dev server for public/ matching static-web-server (`sws.toml`)."""
    import functools
    import http.server
    import pathlib

    root = pathlib.Path("public").resolve()
    if not root.is_dir():
        raise SystemExit(f"no public/ in {pathlib.Path.cwd()} — run just from the repo root")

    not_found = root / "404.html"

    class Handler(http.server.SimpleHTTPRequestHandler):
        extensions_map = {
            **http.server.SimpleHTTPRequestHandler.extensions_map,
            ".typ": "text/plain; charset=utf-8",
            ".xml": "application/xml; charset=utf-8",
            ".woff2": "font/woff2",
        }

        def end_headers(self):
            clean = self.path.split("?", 1)[0]
            if clean.startswith(("/css/", "/fonts/")):
                self.send_header("Cache-Control", "public, max-age=31536000, immutable")
            else:
                self.send_header("Cache-Control", "no-cache")
            if clean.endswith(".typ"):
                self.send_header("Content-Disposition", "inline")
                self.send_header("X-Content-Type-Options", "nosniff")
            super().end_headers()

        def send_error(self, code, message=None, explain=None):
            if code == 404 and not_found.is_file():
                body = not_found.read_bytes()
                self.send_response(404)
                self.send_header("Content-Type", "text/html; charset=utf-8")
                self.send_header("Content-Length", str(len(body)))
                self.end_headers()
                if self.command != "HEAD":
                    self.wfile.write(body)
                return
            super().send_error(code, message, explain)

    handler = functools.partial(Handler, directory=str(root))
    with http.server.ThreadingHTTPServer(("", 8080), handler) as httpd:
        print(f"serving {root} on http://localhost:8080")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nstopped")

# Live-preview a post (or site.typ) in paged mode while writing
watch target="site.typ":
    #!/usr/bin/env sh
    set -eu
    sh ./scripts/link-packages.sh >/dev/null
    typst watch --package-path .tmp-pkg "{{target}}"

# Expose vendor/* as a local @preview package root in .tmp-pkg (see vendor/README.md)
link-packages:
    sh ./scripts/link-packages.sh

# Build the production image (same build as CI)
build:
    docker build -t ghcr.io/bfeitknecht/glob:dev .

# Run the production image locally
# OrbStack: published-port proxy is unreliable for scratch images — use the
# container DNS name it provides. Plain Docker/Linux: localhost:8080 works.
preview:
    docker rm -f glob-preview >/dev/null 2>&1 || true
    docker run -d --rm --name glob-preview -p 8080:8080 ghcr.io/bfeitknecht/glob:dev
    @echo "→ http://glob-preview.orb.local:8080 (OrbStack) or http://localhost:8080 (Linux)"

# Commit, tag and push. TAG is the git tag; MESSAGE is the commit message and
# the tag annotation. Either one is prompted for when empty. Everything is
# staged first, so a clean tree just tags HEAD.
release $tag="" $message="":
    #!/usr/bin/env sh
    set -eu

    tag="${tag:-}"
    message="${message:-}"

    if [ -z "$tag" ]; then
        printf 'release tag: '
        read -r tag || tag=""
    fi
    if [ -z "$message" ]; then
        printf 'release message: '
        read -r message || message=""
    fi

    if [ -z "$tag" ]; then
        echo "release: no tag given" >&2
        exit 1
    fi
    if [ -z "$message" ]; then
        echo "release: no message given" >&2
        exit 1
    fi
    if ! git check-ref-format "refs/tags/$tag" >/dev/null 2>&1; then
        echo "release: '$tag' is not a valid tag name" >&2
        exit 1
    fi
    if git rev-parse -q --verify "refs/tags/$tag" >/dev/null; then
        echo "release: tag $tag already exists" >&2
        exit 1
    fi
    if ! git remote get-url origin >/dev/null 2>&1; then
        echo "release: no 'origin' remote configured" >&2
        exit 1
    fi

    git add -A
    if ! git diff --cached --quiet; then
        git commit -m "$message"
    elif git rev-parse -q --verify HEAD >/dev/null; then
        echo "release: nothing to commit, tagging HEAD"
    else
        echo "release: nothing to commit and no commits yet" >&2
        exit 1
    fi

    git tag -a "$tag" -m "$message"
    git push origin HEAD
    git push origin "$tag"
    echo "release: pushed $tag"
