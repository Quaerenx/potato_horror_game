#!/usr/bin/env python3
"""Verify that locked visual assets have not been modified.

Run from the Godot project root:
    python tools/verify_asset_lock.py
"""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
import sys

try:
    from PIL import Image
except Exception:
    Image = None

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "asset_manifest.lock.json"


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def main() -> int:
    if not MANIFEST.exists():
        print(f"ASSET_LOCK_FAIL: missing {MANIFEST}")
        return 1

    data = json.loads(MANIFEST.read_text(encoding="utf-8"))
    failures: list[str] = []

    for asset in data.get("assets", []):
        rel = asset.get("path")
        path = ROOT / rel
        if not path.exists():
            failures.append(f"missing: {rel}")
            continue

        if sha256(path) != asset.get("sha256"):
            failures.append(f"sha256 mismatch: {rel}")

        expected_bytes = asset.get("bytes")
        if expected_bytes is not None and path.stat().st_size != expected_bytes:
            failures.append(f"byte size mismatch: {rel}")

        if Image is not None and path.suffix.lower() in {".png", ".webp", ".jpg", ".jpeg"}:
            with Image.open(path) as im:
                if asset.get("width") is not None and im.width != asset.get("width"):
                    failures.append(f"width mismatch: {rel}")
                if asset.get("height") is not None and im.height != asset.get("height"):
                    failures.append(f"height mismatch: {rel}")
                if asset.get("mode") is not None and im.mode != asset.get("mode"):
                    failures.append(f"mode mismatch: {rel}")

    if failures:
        for item in failures:
            print("ASSET_LOCK_FAIL:", item)
        return 1

    print("ASSET_LOCK_OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
