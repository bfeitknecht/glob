# The commands for this repository.

# Pinned font versions. To update the fonts, change these two values.
# `just check --fonts` downloads them and writes fonts/VERSIONS and fonts/SHA256SUMS.
stix_version := "v2.13b171"
commit_mono_version := "1.143"

# List the recipes
default:
    @just --list

# Compile site.typ into public/. The fonts are checked first.
compile: (check "--fonts")
    rm -rf public
    typst compile --features html,bundle --format bundle site.typ public

# Check the repository. `--fonts` checks and updates the fonts only.
check *flags:
    #!/usr/bin/env sh
    # `just` writes the recipe arguments here as text. It does not send them on the command
    # line. Separate the flags with spaces.
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
        echo "==> fonts"
        if ( cd fonts && sha256sum -c SHA256SUMS >/dev/null 2>&1 ); then
            echo "fonts agree with fonts/SHA256SUMS"
        else
            echo "fonts do not agree with fonts/SHA256SUMS. Downloading {{ stix_version }} and {{ commit_mono_version }}"
            just fetch-fonts
        fi
    fi

# Write the justfile in the standard form. `just fmt --check` only checks it.
fmt *args:
    @just --fmt {{ args }}

# Download the pinned fonts and write fonts/VERSIONS and fonts/SHA256SUMS. `check` calls it.
[private]
fetch-fonts:
    #!/usr/bin/env sh
    # Use the upstream releases. A CDN subset removes the `smcp`, `c2sc`, `onum`, and
    # `MATH` tables. STIX Two has `.woff2` files. Commit Mono has only `.otf` files, so the
    # recipe converts them with `woff2_compress` if that program is available, or with
    # fontTools (`pip install fonttools brotli`).
    set -eu

    stix="{{ stix_version }}"
    commit_mono="{{ commit_mono_version }}"
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

    # Stop if a download is a subset. These tables are the reason to host the fonts here
    # and not get them from Google Fonts.
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

    ( cd "${font_dir}" && LC_ALL=C sha256sum *.woff2 > SHA256SUMS && sha256sum -c SHA256SUMS >/dev/null )
    echo "==> wrote ${font_dir}/VERSIONS and ${font_dir}/SHA256SUMS"

# Serve the bundle with live reload (typst watch)
serve port="8080":
    typst watch --features html,bundle --format bundle --port "{{ port }}" site.typ public

# Show a paged preview of one post while you write
watch target="site.typ":
    typst watch "{{ target }}"

# Build the container image locally
image:
    docker build -t ghcr.io/bfeitknecht/glob:dev .

# Run the image built by `just image`
run:
    # OrbStack: the port proxy does not work for scratch images. Use the container DNS
    # name. Docker and Linux: http://localhost:8080.
    docker rm -f glob-preview >/dev/null 2>&1 || true
    docker run -d --rm --name glob-preview -p 8080:8080 ghcr.io/bfeitknecht/glob:dev
    @echo "→ http://glob-preview.orb.local:8080 (OrbStack) or http://localhost:8080 (Linux)"

# Commit, tag with `v*`, and push. The tag starts the image build.
release $tag="" $message="":
    #!/usr/bin/env sh
    # The recipe stages all files first. If the tree is clean, it only tags HEAD. If TAG or
    # MESSAGE is empty, the recipe asks for it.
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
