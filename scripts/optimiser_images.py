#!/usr/bin/env python3
from pathlib import Path
from PIL import Image, UnidentifiedImageError
import csv
import logging


def parse_file_list(files_arg: str) -> list[Path]:
    rows = csv.reader(files_arg.splitlines())
    return [Path(item.strip()) for row in rows for item in row if item.strip()]


def process_image(src_path: Path, dest_dir: Path, target_width: int) -> bool:
    dest_dir.mkdir(parents=True, exist_ok=True)
    dest = dest_dir / (src_path.stem + ".webp")
    src_mtime = src_path.stat().st_mtime
    if dest.exists() and dest.stat().st_mtime >= src_mtime:
        logging.info(f"Skipped (up-to-date): {dest}")
        return False
    try:
        with Image.open(src_path) as im:
            im = im.convert("RGB")
            width, height = im.size
            out_width = min(width, target_width)
            if out_width < 1:
                logging.warning(f"Invalid width for {src_path}")
                return False
            if out_width < width:
                new_height = round(height * out_width / width)
                im_resized = im.resize((out_width, new_height), Image.LANCZOS)
            else:
                im_resized = im
            im_resized.save(dest, "WEBP", quality=80, method=6)
            logging.info(f"Saved: {dest} ({out_width}px)")
            return True
    except UnidentifiedImageError:
        logging.warning(f"Unrecognized image: {src_path}")
        return False
    except Exception as e:
        logging.warning(f"Error processing {src_path}: {e}")
        return False


def main() -> None:
    logging.basicConfig(level=logging.INFO, format="%(message)s")
    repo_root = Path(__file__).resolve().parents[1]
    images_dir = repo_root / "public" / "images"
    mobile_dir = images_dir / "mobile"
    desktop_dir = images_dir / "desktop"

    if not images_dir.exists():
        logging.info(f"No images folder found at {images_dir}. Nothing to do.")
        return

    import argparse

    parser = argparse.ArgumentParser(description="Optimize images to WebP mobile/desktop variants")
    parser.add_argument("--files", help="Optional CSV or newline-separated list of files to process", default=None)
    args = parser.parse_args()

    exts = {".jpg", ".jpeg", ".png", ".gif", ".tif", ".tiff", ".bmp"}
    generated = 0

    targets = []
    if args.files:
        targets = [repo_root / path for path in parse_file_list(args.files)]
    else:
        targets = list(images_dir.rglob("*"))

    for p in targets:
        if not p.exists() or not p.is_file():
            continue
        # Skip files that are already webp or are inside output folders
        if p.suffix.lower() == ".webp":
            logging.info(f"Skipping source webp: {p}")
            continue
        if mobile_dir in p.parents or desktop_dir in p.parents:
            logging.info(f"Skipping output folder file: {p}")
            continue
        if p.suffix.lower() not in exts:
            logging.info(f"Skipping unsupported file: {p}")
            continue

        if process_image(p, mobile_dir, 480):
            generated += 1
        if process_image(p, desktop_dir, 1080):
            generated += 1

    logging.info(f"Done. WebP files generated/updated: {generated}")


if __name__ == "__main__":
    main()
