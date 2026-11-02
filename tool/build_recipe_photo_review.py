"""Build contact sheets of generated recipe photos for visual review (Pillow)."""
import json
from pathlib import Path

from PIL import Image, ImageDraw


def main():
    root = Path(__file__).resolve().parents[1]
    recipes = json.loads(
        (root / "supabase/catalog/recipe-expansion-drafts.json").read_text()
    )["recipes"]
    destination = root / "reports/recipe-expansion-photo-review"
    destination.mkdir(exist_ok=True)
    ready = []
    for recipe in recipes:
        path = root / "supabase/catalog/photos/new" / (recipe["id"] + ".jpg")
        if path.is_file():
            ready.append((recipe, path))
    for start in range(0, len(ready), 24):
        batch = ready[start:start + 24]
        page = Image.new("RGB", (1200, ((len(batch) + 3) // 4) * 260), "#f5f0e8")
        draw = ImageDraw.Draw(page)
        for index, (recipe, path) in enumerate(batch):
            with Image.open(path) as source:
                source.verify()
            with Image.open(path) as source:
                source.thumbnail((290, 215))
                x, y = (index % 4) * 300, (index // 4) * 260
                page.paste(source, (x, y))
                draw.text((x + 5, y + 219), recipe["en"]["title"][:39], fill="black")
                draw.text((x + 5, y + 235), recipe["id"][:43], fill="#555555")
        page.save(destination / f"sheet-{start // 24 + 1:02d}.jpg", quality=87)
    print(json.dumps({"photos": len(ready), "sheets": (len(ready) + 23) // 24,
                      "directory": str(destination)}))


if __name__ == "__main__":
    main()
