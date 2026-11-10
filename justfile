# Build, fonts, preview, and release — every command this repository has.

# List the recipes
default:
    @just --list

# Compile site.typ into public/ (verifies fonts/SHA256SUMS first)
compile: (check "--fonts")
    rm -rf public
    typst compile --features html,bundle --format bundle site.typ public

# Verify the repository — `just check --fonts` limits it to fonts/SHA256SUMS
check *flags:
    #!/usr/bin/env sh
    # `just` interpolates recipe arguments here rather than passing them on the command
    # line, so the flag list comes in as plain space-separated text.
    set -eu

    flags="{{ flags }}"
    fonts=false
    [ -n "${flags}" ] || fonts=true
    for flag in ${flags}; do
        case "${flag}" in
            --fonts) fonts=true ;;
            *) echo "check: unknown flag '${flag}' (known: --fonts)" >&2; exit 1 ;;
        esac
    done

    if [ "${fonts}" = true ]; then
        echo "==> fonts/SHA256SUMS"
        ( cd fonts && sha256sum -c SHA256SUMS )
    fi

# Format the justfile — `just fmt --check` verifies without writing
fmt *args:
    @just --fmt {{ args }}

# Re-fetch the upstream fonts and rewrite fonts/VERSIONS + fonts/SHA256SUMS
sync-fonts stix="v2.13b171" commit-mono="1.143":
    #!/usr/bin/env sh
    # Both fonts come from their canonical upstream releases, never from a CDN subsetter
    # that strips `smcp`, `c2sc`, `onum`, or `MATH`. STIX Two ships .woff2; Commit Mono
    # ships .otf only, so it is converted with `woff2_compress` when available, else with
    # fontTools (`pip install fonttools brotli`).
    set -eu

    stix="{{ stix }}"
    commit_mono="{{ commit-mono }}"
    font_dir="fonts"
    tmp_dir="$(mktemp -d)"
    trap 'rm -rf "${tmp_dir}"' EXIT
    mkdir -p "${font_dir}"

    echo "==> STIX Two ${stix} (stipub/stixfonts)"
    stix_base="https://raw.githubusercontent.com/stipub/stixfonts/${stix}"
    for f in \
        STIXTwoText-Regular.woff2 \
        STIXTwoText-Italic.woff2 \
        STIXTwoText-SemiBold.woff2 \
        STIXTwoText-SemiBoldItalic.woff2 \
        STIXTwoText-Bold.woff2 \
        STIXTwoText-BoldItalic.woff2 \
        STIXTwoMath-Regular.woff2
    do
        curl -fsSL "${stix_base}/fonts/static_otf_woff2/${f}" -o "${font_dir}/${f}"
    done
    curl -fsSL "${stix_base}/OFL.txt" -o "${font_dir}/OFL-STIXTwo.txt"

    echo "==> Commit Mono v${commit_mono} (eigilnikolajsen/commit-mono)"
    curl -fsSL \
        "https://github.com/eigilnikolajsen/commit-mono/releases/download/v${commit_mono}/CommitMono-${commit_mono}.zip" \
        -o "${tmp_dir}/cm.zip"
    unzip -j -q "${tmp_dir}/cm.zip" "*/CommitMono-*.otf" "*/license.txt" -d "${tmp_dir}/cm"
    cp "${tmp_dir}/cm/license.txt" "${font_dir}/OFL-CommitMono.txt"

    if command -v woff2_compress >/dev/null 2>&1; then
        for otf in "${tmp_dir}"/cm/CommitMono-*.otf; do
            woff2_compress "${otf}" >/dev/null
            mv "${otf%.otf}.woff2" "${font_dir}/"
        done
    else
        python3 - "${tmp_dir}/cm" "${font_dir}" <<'PY'
    import glob, os, sys
    from fontTools.ttLib import TTFont

    src_dir, dst_dir = sys.argv[1], sys.argv[2]
    for otf in sorted(glob.glob(os.path.join(src_dir, "CommitMono-*.otf"))):
        ft = TTFont(otf)
        ft.flavor = "woff2"
        ft.save(os.path.join(dst_dir, os.path.basename(otf)[:-4] + ".woff2"))
    PY
    fi

    # Guard against a silently subsetted download: these tables are the whole reason the
    # fonts are self-hosted instead of pulled from Google Fonts.
    if python3 -c "import fontTools, brotli" >/dev/null 2>&1; then
        python3 - "${font_dir}" <<'PY'
    import glob, os, sys
    from fontTools.ttLib import TTFont

    fdir = sys.argv[1]
    for p in sorted(glob.glob(os.path.join(fdir, "STIXTwoText-*.woff2"))):
        feats = {r.FeatureTag for r in TTFont(p)["GSUB"].table.FeatureList.FeatureRecord}
        assert {"smcp", "c2sc", "onum"} <= feats, f"{p} missing smcp/c2sc/onum: {feats}"
    assert "MATH" in TTFont(os.path.join(fdir, "STIXTwoMath-Regular.woff2")), "no MATH table"
    for p in sorted(glob.glob(os.path.join(fdir, "CommitMono-*.woff2"))):
        ft = TTFont(p)
        feats = {r.FeatureTag for r in ft["GSUB"].table.FeatureList.FeatureRecord}
        assert "calt" in feats and len(ft.getGlyphOrder()) >= 1900, f"{p} appears subsetted"
    print("verified OpenType tables (STIX Two smcp/c2sc/onum + MATH) and full Commit Mono")
    PY
    fi

    cat > "${font_dir}/VERSIONS" <<EOF
    STIX_VERSION=${stix}
    COMMIT_MONO_VERSION=${commit_mono}
    FONT_CACHE_TAG=${stix#v}-${commit_mono}
    EOF

    ( cd "${font_dir}" && LC_ALL=C sha256sum *.woff2 > SHA256SUMS )
    echo "==> wrote ${font_dir}/VERSIONS and ${font_dir}/SHA256SUMS"

# Live-reloading bundle server (typst watch)
serve port="8080":
    typst watch --features html,bundle --format bundle --port "{{ port }}" site.typ public

# Live paged preview of one post while writing
watch target="site.typ":
    typst watch "{{ target }}"

# Build the production image locally
build:
    docker build -t ghcr.io/bfeitknecht/glob:dev .

# Run the image built by `just build`
preview:
    # OrbStack: the published-port proxy is unreliable for scratch images, so use the
    # container DNS name instead. Plain Docker/Linux: http://localhost:8080.
    docker rm -f glob-preview >/dev/null 2>&1 || true
    docker run -d --rm --name glob-preview -p 8080:8080 ghcr.io/bfeitknecht/glob:dev
    @echo "→ http://glob-preview.orb.local:8080 (OrbStack) or http://localhost:8080 (Linux)"

# Commit, create the annotated `v*` tag, and push — the tag publishes the image
release $tag="" $message="":
    #!/usr/bin/env sh
    # Stages everything first, so a clean tree just tags HEAD. A missing TAG or MESSAGE is
    # prompted for.
    set -eu

    tag="${tag:-}"
    message="${message:-}"

    [ -n "$tag" ] || { printf 'release tag: '; read -r tag || tag=""; }
    [ -n "$message" ] || { printf 'release message: '; read -r message || message=""; }
    [ -n "$tag" ] || { echo "release: no tag given" >&2; exit 1; }
    [ -n "$message" ] || { echo "release: no message given" >&2; exit 1; }
    git check-ref-format "refs/tags/$tag" >/dev/null 2>&1 \
        || { echo "release: '$tag' is not a valid tag name" >&2; exit 1; }
    ! git rev-parse -q --verify "refs/tags/$tag" >/dev/null \
        || { echo "release: tag $tag already exists" >&2; exit 1; }
    git remote get-url origin >/dev/null 2>&1 \
        || { echo "release: no 'origin' remote configured" >&2; exit 1; }

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
