#!/usr/bin/env python3
"""Assert that a compiled bundle contains no chromatic color.

`*glob?` is deliberately hue-free: every color must resolve to R = G = B. This
walks the compiled output (`public/` by default) and reports any color literal
that carries chroma — hex, `rgb()`/`rgba()`, `hsl()`, `oklch()`/`lch()`,
`oklab()`/`lab()`, `hwb()`, or `color()`.

`<style>` blocks inside HTML are skipped: that is the verbatim `zebraw`
Expressive-Code sheet, whose `var(--ec-*, <chromatic fallback>)` defaults are
inert (see `assets/mono.css`, which pins every one of those properties to a
theme token) and cannot be edited from here.

Usage: scripts/check-monochrome.py [public]
Exit status is 1 when anything chromatic is found.
"""

from __future__ import annotations

import pathlib
import re
import sys

# Any color literal worth auditing. Named colors are intentionally not matched:
# CSS in the bundle is generated, and words like "red" or "gray" show up in prose.
COLOR_PATTERNS = [
    ("hex", re.compile(r"(?<![&\w#])#([0-9a-fA-F]{8}|[0-9a-fA-F]{6}|[0-9a-fA-F]{3})\b")),
    ("rgb", re.compile(r"\brgba?\(\s*([^)]*)\)", re.IGNORECASE)),
    ("hsl", re.compile(r"\bhsla?\(\s*([^)]*)\)", re.IGNORECASE)),
    ("hwb", re.compile(r"\bhwb\(\s*([^)]*)\)", re.IGNORECASE)),
    ("oklch", re.compile(r"\boklch\(\s*([^)]*)\)", re.IGNORECASE)),
    ("lch", re.compile(r"(?<!\bok)\blch\(\s*([^)]*)\)", re.IGNORECASE)),
    ("oklab", re.compile(r"\boklab\(\s*([^)]*)\)", re.IGNORECASE)),
    ("lab", re.compile(r"(?<!\bok)\blab\(\s*([^)]*)\)", re.IGNORECASE)),
    ("color", re.compile(r"\bcolor\(\s*([^)]*)\)", re.IGNORECASE)),
]

STYLE_BLOCK = re.compile(r"<style\b[^>]*>.*?</style\s*>", re.IGNORECASE | re.DOTALL)
CSS_COMMENT = re.compile(r"/\*.*?\*/", re.DOTALL)


def blank_comments(text: str) -> str:
    """Replace `/* … */` comments with whitespace, preserving line numbers."""
    return CSS_COMMENT.sub(lambda m: "\n" * m.group(0).count("\n"), text)


def channel(value: str) -> float:
    """Parse one color component (`12`, `12%`, `90deg`, `none`) into a float."""
    value = value.strip().lower()
    if value in ("none", ""):
        return 0.0
    if value.endswith("%"):
        return float(value[:-1]) / 100.0
    if value.endswith("deg"):
        return float(value[:-3])
    return float(value)


def split_args(args: str) -> list[str]:
    """Split a color function's arguments, dropping any `/ alpha` part."""
    args = args.split("/", 1)[0]
    return [part for part in re.split(r"[,\s]+", args.strip()) if part]


def chromatic(kind: str, args: str) -> str | None:
    """Return a human-readable reason when the literal carries hue, else None."""
    parts = split_args(args)
    try:
        if kind in ("rgb", "color"):
            # `color(srgb r g b)` / `color(display-p3 r g b)` after the space token.
            if kind == "color":
                parts = parts[1:]
            values = [channel(p) for p in parts[:3]]
            if len(values) == 3 and max(values) - min(values) > 1e-6:
                return "unequal R/G/B channels"
            return None
        if kind == "hsl":
            values = [channel(p) for p in parts]
            if len(values) >= 2 and values[1] != 0:
                return "non-zero saturation"
            return None
        if kind == "hwb":
            return "hwb() cannot be verified as achromatic"
        if kind in ("oklch", "lch"):
            values = [channel(p) for p in parts]
            if len(values) < 3:
                return "unparsable color function"
            if values[1] != 0:
                return "non-zero chroma"
            if values[2] != 0:
                return "non-zero hue"
            return None
        if kind in ("oklab", "lab"):
            values = [channel(p) for p in parts]
            if len(values) < 3:
                return "unparsable color function"
            if values[1] != 0 or values[2] != 0:
                return "non-zero a/b axes"
            return None
    except ValueError:
        return "unparsable color function"
    return "unchecked color syntax"


def audit_text(text: str, name: str) -> list[tuple[str, int, str]]:
    findings: list[tuple[str, int, str]] = []
    for kind, pattern in COLOR_PATTERNS:
        for match in pattern.finditer(text):
            args = match.group(1) if kind != "hex" else match.group(1)
            if kind == "hex":
                digits = args
                if len(digits) == 8:
                    digits = digits[:6]
                if len(digits) == 3:
                    digits = "".join(c * 2 for c in digits)
                if len({digits[i : i + 2] for i in (0, 2, 4)}) == 1:
                    continue
                reason = "unequal R/G/B channels"
            else:
                reason = chromatic(kind, args)
                if reason is None:
                    continue
            line = text.count("\n", 0, match.start()) + 1
            findings.append((name, line, f"{match.group(0)}  ({reason})"))
    return findings


def main() -> int:
    root = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else "public")
    if not root.is_dir():
        print(f"check-monochrome: no {root}/ — compile first (`just compile`)", file=sys.stderr)
        return 2

    targets = sorted(
        p for p in root.rglob("*") if p.is_file() and p.suffix in (".css", ".html")
    )
    findings: list[tuple[str, int, str]] = []
    literals = 0
    for path in targets:
        text = path.read_text(encoding="utf-8", errors="replace")
        if path.suffix == ".html":
            text = STYLE_BLOCK.sub("", text)
        else:
            text = blank_comments(text)
        literals += sum(1 for _, pattern in COLOR_PATTERNS for _ in pattern.finditer(text))
        findings += audit_text(text, str(path))

    rel = root.name or str(root)
    if findings:
        print(f"check-monochrome: {len(findings)} chromatic color(s) in {rel}/", file=sys.stderr)
        for name, line, message in sorted(findings):
            print(f"  {name}:{line}: {message}", file=sys.stderr)
        return 1

    print(
        f"check-monochrome: {literals} color literal(s) across {len(targets)} file(s) "
        f"in {rel}/ are hue-free"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
