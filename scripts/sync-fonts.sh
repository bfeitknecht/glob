#!/usr/bin/env sh
# Fetch, convert, and cryptographically lock upstream STIX Two + Commit Mono web fonts
# into `fonts/` directly from their canonical upstream GitHub releases (no Google Fonts
# or third-party subsetters that strip OpenType `smcp`, `c2sc`, `onum`, or `MATH` tables).
#
# Usage:
#   sh ./scripts/sync-fonts.sh           # fetch/update `fonts/*.woff2` + `SHA256SUMS`
#   sh ./scripts/sync-fonts.sh --check   # verify existing `fonts/*.woff2` against `SHA256SUMS`
#   STIX_VERSION=v2.14 COMMIT_MONO_VERSION=1.144 sh ./scripts/sync-fonts.sh
set -eu

CDPATH="" cd -- "$(dirname -- "$0")/.."
FONT_DIR="fonts"

if [ "${1:-}" = "--check" ]; then
  [ -f "${FONT_DIR}/SHA256SUMS" ] || { echo "missing ${FONT_DIR}/SHA256SUMS" >&2; exit 1; }
  (cd "${FONT_DIR}" && sha256sum -c SHA256SUMS)
  exit 0
fi

STIX_VERSION="${STIX_VERSION:-v2.13b171}"
COMMIT_MONO_VERSION="${COMMIT_MONO_VERSION:-1.143}"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT
mkdir -p "${FONT_DIR}"

echo "==> Fetching upstream STIX Two (${STIX_VERSION}) from stipub/stixfonts..."
STIX_BASE="https://raw.githubusercontent.com/stipub/stixfonts/${STIX_VERSION}"
for f in \
  STIXTwoText-Regular.woff2 \
  STIXTwoText-Italic.woff2 \
  STIXTwoText-SemiBold.woff2 \
  STIXTwoText-SemiBoldItalic.woff2 \
  STIXTwoText-Bold.woff2 \
  STIXTwoText-BoldItalic.woff2 \
  STIXTwoMath-Regular.woff2
do
  curl -fsSL "${STIX_BASE}/fonts/static_otf_woff2/${f}" -o "${FONT_DIR}/${f}"
done
curl -fsSL "${STIX_BASE}/OFL.txt" -o "${FONT_DIR}/OFL-STIXTwo.txt"

echo "==> Fetching upstream Commit Mono (v${COMMIT_MONO_VERSION}) from eigilnikolajsen/commit-mono..."
curl -fsSL \
  "https://github.com/eigilnikolajsen/commit-mono/releases/download/v${COMMIT_MONO_VERSION}/CommitMono-${COMMIT_MONO_VERSION}.zip" \
  -o "${TMP_DIR}/cm.zip"
unzip -j -q "${TMP_DIR}/cm.zip" "*/CommitMono-*.otf" "*/license.txt" -d "${TMP_DIR}/cm"
cp "${TMP_DIR}/cm/license.txt" "${FONT_DIR}/OFL-CommitMono.txt"

if command -v woff2_compress >/dev/null 2>&1; then
  for otf in "${TMP_DIR}"/cm/CommitMono-*.otf; do
    woff2_compress "${otf}" >/dev/null
    mv "${otf%.otf}.woff2" "${FONT_DIR}/"
  done
else
  PY_BIN="python3"
  if [ -x /tmp/pw-venv/bin/python ] && ! "${PY_BIN}" -c "import fontTools, brotli" >/dev/null 2>&1; then
    PY_BIN="/tmp/pw-venv/bin/python"
  fi
  "${PY_BIN}" - "${TMP_DIR}/cm" "${FONT_DIR}" <<'PY'
import glob, os, sys
from fontTools.ttLib import TTFont

src_dir, dst_dir = sys.argv[1], sys.argv[2]
for otf in sorted(glob.glob(os.path.join(src_dir, "CommitMono-*.otf"))):
    ft = TTFont(otf)
    ft.flavor = "woff2"
    out = os.path.join(dst_dir, os.path.basename(otf)[:-4] + ".woff2")
    ft.save(out)
PY
fi

# Optional OpenType table sanity check when fontTools is available
PY_CHECK=""
if python3 -c "import fontTools, brotli" >/dev/null 2>&1; then
  PY_CHECK="python3"
elif [ -x /tmp/pw-venv/bin/python ] && /tmp/pw-venv/bin/python -c "import fontTools, brotli" >/dev/null 2>&1; then
  PY_CHECK="/tmp/pw-venv/bin/python"
fi

if [ -n "${PY_CHECK}" ]; then
  "${PY_CHECK}" - "${FONT_DIR}" <<'PY'
import glob, os, sys
from fontTools.ttLib import TTFont

fdir = sys.argv[1]
for p in sorted(glob.glob(os.path.join(fdir, "STIXTwoText-*.woff2"))):
    ft = TTFont(p)
    feats = {r.FeatureTag for r in ft["GSUB"].table.FeatureList.FeatureRecord}
    assert {"smcp", "c2sc", "onum"} <= feats, f"{p} missing smcp/c2sc/onum: {feats}"
mft = TTFont(os.path.join(fdir, "STIXTwoMath-Regular.woff2"))
assert "MATH" in mft, "STIXTwoMath-Regular.woff2 missing MATH table"
for p in sorted(glob.glob(os.path.join(fdir, "CommitMono-*.woff2"))):
    ft = TTFont(p)
    feats = {r.FeatureTag for r in ft["GSUB"].table.FeatureList.FeatureRecord}
    assert "calt" in feats and len(ft.getGlyphOrder()) >= 1900, f"{p} appears subsetted"
print("verified OpenType tables (STIX Two smcp/c2sc/onum + MATH, Commit Mono full glyph set)")
PY
fi

cat > "${FONT_DIR}/VERSIONS" <<EOF
STIX_VERSION=${STIX_VERSION}
COMMIT_MONO_VERSION=${COMMIT_MONO_VERSION}
FONT_CACHE_TAG=${STIX_VERSION#v}-${COMMIT_MONO_VERSION}
EOF

(
  cd "${FONT_DIR}"
  LC_ALL=C sha256sum *.woff2 > SHA256SUMS
)
echo "==> Wrote ${FONT_DIR}/VERSIONS and ${FONT_DIR}/SHA256SUMS"
