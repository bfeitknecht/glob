# Stage 1: build the Typst bundle for the host platform. A native build is faster than
# QEMU emulation for the multi-arch linux/amd64,linux/arm64 CI builds.
# The .otf files of STIX Two and Commit Mono are in /fonts for Stage 1 only. They give the
# inline SVG diagrams exact glyph metrics. Stage 2 (`FROM scratch`) stays small.
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

# Check the web fonts against `fonts/SHA256SUMS`. Then compile `/public`.
# Typst gets `@preview/thyme:0.1.0` and `@preview/exemel:0.3.0` from Typst Universe.
RUN cd fonts && sha256sum -c SHA256SUMS && cd .. && \
    typst compile --font-path /fonts --features html,bundle --format bundle site.typ /public

# Stage 2: static-web-server (Rust, about 4 MB, static, no runtime dependencies). It goes
# into an empty filesystem. This is the same pattern as bfeitknecht/apex.
FROM joseluisq/static-web-server:2.44.1-alpine AS sws

FROM scratch

COPY --from=sws /usr/local/bin/static-web-server /static-web-server
COPY --from=builder /public /public
COPY sws.toml /sws.toml

# sws.toml sets Cache-Control: no-cache for HTML and XML, a long cache time for `css/**`
# and `fonts/**`, and text/plain and nosniff headers for `**/*.typ`.
# SERVER_ERROR_PAGE_404 is a relative path, so it points to /public/404.html.
ENV SERVER_HOST=0.0.0.0 \
    SERVER_PORT=8080 \
    SERVER_ROOT=/public \
    SERVER_ERROR_PAGE_404=./404.html \
    SERVER_CACHE_CONTROL_HEADERS=false \
    SERVER_CONFIG_FILE=/sws.toml \
    SERVER_LOG_LEVEL=info

# The container writes no files. The Deployment uses readOnlyRootFilesystem.
USER 1000:1000
EXPOSE 8080
ENTRYPOINT ["/static-web-server"]
