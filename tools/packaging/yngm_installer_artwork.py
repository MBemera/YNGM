"""Cut the installer splash, wizard and progress-page bitmaps from YNGM's cover art."""
from pathlib import Path
from PIL import Image

SPLASH_WIDTH = 640
WELCOME_SIZE = (164, 314)
WELCOME_CROP = (142, 225, 499, 909)
INSTALL_ART_HEIGHT = 182


def resize_to_width(image: Image.Image, width: int) -> Image.Image:
    height = round(image.height * width / image.width)
    return image.resize((width, height), Image.Resampling.LANCZOS)


def resize_to_height(image: Image.Image, height: int) -> Image.Image:
    width = round(image.width * height / image.height)
    return image.resize((width, height), Image.Resampling.LANCZOS)


def save_bitmap(image: Image.Image, path: Path) -> Path:
    image.convert("RGB").save(path, format="BMP")
    return path


def create_installer_artwork(cover_art: Path, output: Path) -> dict[str, Path]:
    if not cover_art.is_file():
        raise FileNotFoundError(f"Cover art missing: {cover_art}")
    output.mkdir(parents=True, exist_ok=True)
    with Image.open(cover_art) as source:
        cover = source.convert("RGB")
    welcome = cover.crop(WELCOME_CROP).resize(WELCOME_SIZE, Image.Resampling.LANCZOS)
    return {
        "splash": save_bitmap(resize_to_width(cover, SPLASH_WIDTH), output / "splash.bmp"),
        "welcome": save_bitmap(welcome, output / "welcome.bmp"),
        "install": save_bitmap(resize_to_height(cover, INSTALL_ART_HEIGHT), output / "install-art.bmp"),
    }
