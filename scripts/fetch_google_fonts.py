#!/usr/bin/env python3
"""
Downloads @fontsource npm packages (Google Fonts subsets as woff2) and emits
matching .ttf files for iOS (woff2 → ttf via fontTools).

The **Doto** family on Google Fonts is monospace (many people say “Doto Mono”).
We build it from the variable `doto-latin-full-normal` slice at **wght=400** and
**ROND=0** (square dots / mono matrix). Use ROND=100 for the rounded Figma style.

Run from repo root: python3 scripts/fetch_google_fonts.py
Requires: npm, pip packages fonttools + brotli
"""
from __future__ import annotations

import json
import shutil
import subprocess
import sys
import tarfile
from pathlib import Path

from fontTools.ttLib import TTFont
from fontTools.ttLib.woff2 import decompress as woff2_decompress

ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "musicapp" / "Fonts" / "GoogleFonts"

# Doto VF instance (typical JAM status = regular weight, square dots).
DOTO_WGHT = 400
DOTO_ROND = 0

# npm package → relative woff2 path inside package/files/ → output .ttf filename
FONTSPEC: list[tuple[str, str, str]] = [
    ("@fontsource/roboto-mono", "files/roboto-mono-latin-400-normal.woff2", "RobotoMono-Regular.ttf"),
    ("@fontsource/sometype-mono", "files/sometype-mono-latin-400-normal.woff2", "SometypeMono-Regular.ttf"),
    ("@fontsource/sometype-mono", "files/sometype-mono-latin-700-normal.woff2", "SometypeMono-Bold.ttf"),
    ("@fontsource/inter", "files/inter-latin-400-normal.woff2", "Inter-Regular.ttf"),
    ("@fontsource/gothic-a1", "files/gothic-a1-latin-600-normal.woff2", "GothicA1-SemiBold.ttf"),
    ("@fontsource/red-hat-mono", "files/red-hat-mono-latin-400-normal.woff2", "RedHatMono-Regular.ttf"),
]


def npm_pack(pkg: str, pack_dir: Path) -> Path:
    pack_dir.mkdir(parents=True, exist_ok=True)
    name = subprocess.check_output(
        ["npm", "pack", pkg, "--silent"],
        cwd=pack_dir,
    ).decode().strip()
    tarball = pack_dir / name
    if not tarball.exists():
        raise FileNotFoundError(f"npm pack produced no tarball: {tarball}")
    return tarball


def woff_to_ttf(woff_path: Path, ttf_path: Path) -> None:
    ttf_path.parent.mkdir(parents=True, exist_ok=True)
    with woff_path.open("rb") as r, ttf_path.open("wb") as w:
        woff2_decompress(r, w)


def post_script_name(ttf_path: Path) -> str:
    font = TTFont(ttf_path)
    name = font["name"]
    for rec in name.names:
        if rec.nameID == 6:  # PostScript name
            return rec.toUnicode()
    return ttf_path.stem


def extract_package(tarball: Path, work: Path, slug: str) -> Path:
    dest_dir = work / f"unpack_{slug}"
    if dest_dir.exists():
        shutil.rmtree(dest_dir)
    dest_dir.mkdir(parents=True)
    with tarfile.open(tarball, "r:gz") as tar:
        tar.extractall(dest_dir)
    return dest_dir / "package"


def build_doto_mono(npm_staging: Path, work: Path, target: Path) -> str:
    """Variable Doto → static TTF at DOTO_WGHT / DOTO_ROND."""
    pkg = "@fontsource-variable/doto"
    tarball = npm_pack(pkg, npm_staging)
    slug = "doto-variable"
    extracted = extract_package(tarball, work, slug)
    woff = extracted / "files" / "doto-latin-full-normal.woff2"
    if not woff.exists():
        raise FileNotFoundError(f"missing {woff}")

    vf_ttf = work / "doto_variable.ttf"
    woff_to_ttf(woff, vf_ttf)

    subprocess.run(
        [
            sys.executable,
            "-m",
            "fontTools.varLib.instancer",
            "-o",
            str(target),
            str(vf_ttf),
            f"wght={DOTO_WGHT}",
            f"ROND={DOTO_ROND}",
            "--update-name-table",
        ],
        check=True,
    )

    ps = post_script_name(target)
    shutil.rmtree(extracted.parent)
    tarball.unlink(missing_ok=True)
    vf_ttf.unlink(missing_ok=True)
    return ps


def main() -> None:
    work = ROOT / ".tmp_fontsource_extract"
    if work.exists():
        shutil.rmtree(work)
    work.mkdir(parents=True)

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    # Remove obsolete static Doto filename if present.
    legacy = OUT_DIR / "Doto-Regular.ttf"
    if legacy.exists():
        legacy.unlink()

    mappings: dict[str, str] = {}
    npm_staging = work / "npm_pack"
    npm_staging.mkdir(exist_ok=True)

    try:
        doto_out = OUT_DIR / "DotoMono-Regular.ttf"
        mappings["DotoMono-Regular"] = build_doto_mono(npm_staging, work, doto_out)

        for pkg, inner, out_name in FONTSPEC:
            tarball = npm_pack(pkg, npm_staging)
            slug = pkg.replace("@fontsource/", "").replace("/", "-")
            extracted = extract_package(tarball, work, slug)

            woff = extracted / inner
            if not woff.exists():
                raise FileNotFoundError(f"missing extracted file {woff}")

            target = OUT_DIR / out_name
            woff_to_ttf(woff, target)
            mappings[out_name.replace(".ttf", "")] = post_script_name(target)
            shutil.rmtree(extracted.parent)
            tarball.unlink(missing_ok=True)

    finally:
        if work.exists():
            shutil.rmtree(work, ignore_errors=True)

    scripts_dir = ROOT / "scripts"
    scripts_dir.mkdir(exist_ok=True)
    plist_path = scripts_dir / "google_font_postscript_names.json"
    plist_path.write_text(json.dumps({"filenames_postscript": mappings}, indent=2))
    print("Wrote:")
    for f in sorted(OUT_DIR.glob("*.ttf")):
        ps = mappings.get(f.stem, "?")
        print(f"  {f.relative_to(ROOT)} ({ps})")


if __name__ == "__main__":
    main()
