from pathlib import Path

import pytest
from PIL import Image

from yngm_installer_artwork import INSTALL_ART_HEIGHT, SPLASH_WIDTH, WELCOME_SIZE, create_installer_artwork

COVER_ART = Path(__file__).resolve().parents[2] / "game/assets/branding/cover-art.png"


def read_bitmap(path: Path) -> Image.Image:
    with Image.open(path) as image:
        image.load()
        return image


def test_artwork_has_the_sizes_the_installer_layout_expects(tmp_path: Path) -> None:
    artwork = create_installer_artwork(COVER_ART, tmp_path)
    splash = read_bitmap(artwork["splash"])
    welcome = read_bitmap(artwork["welcome"])
    install = read_bitmap(artwork["install"])
    assert splash.width == SPLASH_WIDTH and splash.height <= 520
    assert welcome.size == WELCOME_SIZE
    assert install.size == (234, INSTALL_ART_HEIGHT)


def test_artwork_is_saved_as_24_bit_bitmaps(tmp_path: Path) -> None:
    for path in create_installer_artwork(COVER_ART, tmp_path).values():
        bitmap = read_bitmap(path)
        assert bitmap.format == "BMP" and bitmap.mode == "RGB"


def test_missing_cover_art_fails_clearly(tmp_path: Path) -> None:
    with pytest.raises(FileNotFoundError, match="Cover art missing"):
        create_installer_artwork(tmp_path / "missing.png", tmp_path / "out")
