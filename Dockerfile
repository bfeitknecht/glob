# Stage 1: Compile the Typst HTML bundle on the host build platform (native speed,
# zero QEMU emulation overhead during multi-arch linux/amd64,linux/arm64 CI builds).
# Pinned STIX Two + Commit Mono .otf fonts live only in /fonts during Stage 1 so
# inline SVG diagrams shape with exact glyph metrics while Stage 2 (`FROM scratch`) stays compact.
FROM --platform=$BUILDPLATFORM alpine:3.21 AS builder
ARG BUILDARCH
ARG TYPST_VERSION=0.15.1
ARG STIX_VERSION=v2.13b171
ARG COMMIT_MONO_VERSION=1.143

RUN apk add --no-cache ca-certificates curl unzip xz && \
    case "${BUILDARCH}" in \
      amd64) ARCH="x86_64-unknown-linux-musl" ;; \
      arm64) ARCH="aarch64-unknown-linux-musl" ;; \
      *) echo "unsupported BUILDARCH: ${BUILDARCH}" >&2; exit 1 ;; \
    esac && \
    curl -fsSL "https://github.com/typst/typst/releases/download/v${TYPST_VERSION}/typst-${ARCH}.tar.xz" \
      | tar -xJ -C /usr/local/bin --strip-components=1 "typst-${ARCH}/typst" && \
    mkdir -p /fonts && \
    for f in STIXTwoText-Regular.otf STIXTwoText-Italic.otf STIXTwoText-SemiBold.otf STIXTwoText-SemiBoldItalic.otf STIXTwoText-Bold.otf STIXTwoText-BoldItalic.otf STIXTwoMath-Regular.otf; do \
      curl -fsSL "https://cdn.jsdelivr.net/gh/stipub/stixfonts@${STIX_VERSION}/fonts/static_otf/${f}" -o "/fonts/${f}"; \
    done && \
    curl -fsSL "https://github.com/eigilnikolajsen/commit-mono/releases/download/v${COMMIT_MONO_VERSION}/CommitMono-${COMMIT_MONO_VERSION}.zip" -o /tmp/cm.zip && \
    unzip -j -q /tmp/cm.zip "*.otf" -d /fonts && \
    rm -f /tmp/cm.zip

WORKDIR /build
COPY . .

# Verify SHA-256 checksums of self-hosted web fonts in `fonts/` and compile `/public`
# (`@preview/thyme:0.1.0` and `@preview/exemel:0.3.0` are fetched directly from Typst Universe).
RUN sh ./scripts/sync-fonts.sh --check && \
    typst compile --font-path /fonts --features html,bundle --format bundle site.typ /public

# Stage 2: static-web-server (Rust, ~4 MB, musl-static, no runtime dependencies)
# copied into an empty filesystem — same pattern as bfeitknecht/apex.
FROM joseluisq/static-web-server:2.44.1-alpine AS sws

FROM scratch

COPY --from=sws /usr/local/bin/static-web-server /static-web-server
COPY --from=builder /public /public
COPY sws.toml /sws.toml

# sws.toml sets Cache-Control: no-cache (immutable on content-hashed css/** and fonts/**)
# + inline nosniff text/plain headers for `**/*.typ`.
# SERVER_ERROR_PAGE_404 is relative, so it resolves under SERVER_ROOT (/public/404.html).
ENV SERVER_HOST=0.0.0.0 \
    SERVER_PORT=8080 \
    SERVER_ROOT=/public \
    SERVER_ERROR_PAGE_404=./404.html \
    SERVER_CACHE_CONTROL_HEADERS=false \
    SERVER_CONFIG_FILE=/sws.toml \
    SERVER_LOG_LEVEL=info

# Nothing is ever written: the Deployment's readOnlyRootFilesystem holds.
USER 1000:1000
EXPOSE 8080
ENTRYPOINT ["/static-web-server"]
