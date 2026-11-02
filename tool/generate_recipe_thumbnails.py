"""Create smaller, cropped recipe-card photos from the 250 full-size photos.

Requires Pillow. Run after finalize_recipe_expansion.mjs --emit.
"""
import json
from pathlib import Path

from PIL import Image, ImageOps


ROOT = Path(__file__).resolve().parents[1]
PHOTO_ROOT = ROOT / "supabase/catalog/photos"
SOURCE = ROOT / "supabase/catalog/recipes-250-import-ready.json"
OUTPUT = ROOT / "supabase/catalog/recipes-250-import-ready-with-thumbnails.json"
SIZE = (768, 576)


def main():
    manifest = json.loads(SOURCE.read_text())
    if len(manifest.get("recipes", [])) != 250:
        raise ValueError("Expected all 250 finalized recipes")

    for recipe in manifest["recipes"]:
        source = PHOTO_ROOT / recipe["photo"]["path"]
        target = PHOTO_ROOT / "thumbnails" / (recipe["id"] + ".jpg")
        target.parent.mkdir(parents=True, exist_ok=True)
        with Image.open(source) as original:
            thumbnail = ImageOps.fit(
                original.convert("RGB"),
                SIZE,
                method=Image.Resampling.LANCZOS,
                centering=(0.5, 0.5),
            )
            thumbnail.save(
                target,
                format="JPEG",
                quality=80,
                optimize=True,
                progressive=True,
            )
        recipe["photo"].update({
            "thumbnail_path": f"thumbnails/{recipe['id']}.jpg",
            "thumbnail_width": SIZE[0],
            "thumbnail_height": SIZE[1],
        })

    OUTPUT.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n")
    total = sum(
        (PHOTO_ROOT / "thumbnails" / (r["id"] + ".jpg")).stat().st_size
        for r in manifest["recipes"]
    )
    print(json.dumps({
        "recipes": len(manifest["recipes"]),
        "dimensions": f"{SIZE[0]}x{SIZE[1]}",
        "thumbnailBytes": total,
        "thumbnailMiB": round(total / 1024 / 1024, 2),
        "manifest": str(OUTPUT),
    }))


if __name__ == "__main__":
    main()
