"""Package YNGM's Linux and macOS exports with readmes, licences and install helpers."""
import io
import logging
import tarfile
import zipfile
from pathlib import Path

GAME_TITLE = "Escape from the Permanent Underclass"
LINUX_BINARY = "YNGM.x86_64"
EXECUTABLE_MODE = 0o755
FILE_MODE = 0o644
UNIX_SYSTEM = 3

ASSISTANT_HELP = """NEED A HAND INSTALLING?
If any step below is unclear, ask an AI coding assistant such as Claude Code or
Codex to install it for you. Open it in the folder that holds this download and
paste this request:

  Install "Escape from the Permanent Underclass" from the download in this
  folder. Read {readme} and follow its steps exactly. Do not change anything
  else on my computer, and tell me what you did.
"""

LINUX_README = """ESCAPE FROM THE PERMANENT UNDERCLASS / YNGM {version} - LINUX (x86_64)

REQUIREMENTS
64-bit x86 Linux desktop (X11 or Wayland) with OpenGL 3.3 graphics drivers.
Keyboard and mouse. No internet connection, account or API key is needed.

INSTALL (recommended)
1. Extract the archive:      tar -xzf YNGM-{version}-Linux-x86_64.tar.gz
2. Enter the folder:         cd YNGM
3. Run the installer:        ./install.sh
   It copies the game to ~/.local/share/yngm and adds
   "Escape from the Permanent Underclass" to your applications menu.

RUN WITHOUT INSTALLING
   cd YNGM && ./YNGM.x86_64

UNINSTALL
   ~/.local/share/yngm/install.sh --uninstall
   This removes ~/.local/share/yngm and the menu entry only.

If the game window does not open, update your graphics drivers (Mesa 20+ or the
vendor driver) and check that "glxinfo | grep 'OpenGL version'" reports 3.3 or newer.

{assistant_help}
Controls and credits: see CREDITS-AND-LICENSES.txt and the in-game HOW TO PLAY screen.
"""

MACOS_README = """ESCAPE FROM THE PERMANENT UNDERCLASS / YNGM {version} - macOS (Apple Silicon and Intel)

REQUIREMENTS
macOS 13 Ventura or newer on Apple Silicon, or macOS 11 Big Sur or newer on Intel.
Keyboard and mouse. No internet connection, account or API key is needed.

INSTALL
1. Double-click YNGM-{version}-macOS-universal.zip to extract it.
2. Drag "{title}.app" into your Applications folder.

FIRST LAUNCH
The app is not notarised by Apple, so macOS blocks the first launch.
1. In Applications, right-click (or Control-click) the app and choose Open,
   then click Open again in the warning dialog. You only need to do this once.
2. If there is no Open button: System Settings > Privacy & Security, scroll down
   and click "Open Anyway" next to the message about this app.
Terminal alternative (removes the download quarantine flag for this app only):
   xattr -dr com.apple.quarantine "/Applications/{title}.app"

UNINSTALL
Drag the app from Applications to the Bin. Saved progress lives in
~/Library/Application Support/Godot/app_userdata/{title}/ if you also want to remove it.

{assistant_help}
Controls and credits: see CREDITS-AND-LICENSES.txt and the in-game HOW TO PLAY screen.
"""

INSTALL_SCRIPT = """#!/bin/sh
# Installs Escape from the Permanent Underclass for the current user only.
set -eu
DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
APP_DIR="$DATA_HOME/yngm"
DESKTOP_FILE="$DATA_HOME/applications/yngm.desktop"
SOURCE_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ "${1:-}" = "--uninstall" ]; then
    rm -rf "$APP_DIR"
    rm -f "$DESKTOP_FILE"
    echo "Removed $APP_DIR and $DESKTOP_FILE"
    exit 0
fi

if [ "$SOURCE_DIR" != "$APP_DIR" ]; then
    mkdir -p "$APP_DIR"
    cp -R "$SOURCE_DIR"/. "$APP_DIR"/
fi
chmod +x "$APP_DIR/YNGM.x86_64" "$APP_DIR/install.sh"
mkdir -p "$(dirname "$DESKTOP_FILE")"
cat > "$DESKTOP_FILE" <<DESKTOP
[Desktop Entry]
Type=Application
Name=Escape from the Permanent Underclass
Comment=Satirical first-person shooter
Exec="$APP_DIR/YNGM.x86_64"
Path=$APP_DIR
Icon=$APP_DIR/yngm.png
Categories=Game;
Terminal=false
DESKTOP
echo "Installed to $APP_DIR"
echo "Launch it from your applications menu, or run: $APP_DIR/YNGM.x86_64"
"""


def make_tar_info(name: str, size: int, mode: int) -> tarfile.TarInfo:
    info = tarfile.TarInfo(name)
    info.size = size
    info.mode = mode
    info.uid = info.gid = 0
    info.uname = info.gname = ""
    return info


def add_bytes_to_tar(archive: tarfile.TarFile, name: str, data: bytes, mode: int) -> None:
    archive.addfile(make_tar_info(name, len(data), mode), io.BytesIO(data))


def add_folder_to_tar(archive: tarfile.TarFile, folder: Path, prefix: str) -> None:
    for path in sorted(folder.rglob("*")):
        if path.is_file():
            add_bytes_to_tar(archive, f"{prefix}/{path.relative_to(folder).as_posix()}", path.read_bytes(), FILE_MODE)


def build_linux_package(project: Path, version: str, linux_build: Path, output: Path) -> Path:
    licenses = project / "game/licenses"
    readme = LINUX_README.format(version=version, assistant_help=ASSISTANT_HELP.format(readme="README-LINUX.txt"))
    with tarfile.open(output, "w:gz") as archive:
        add_bytes_to_tar(archive, f"YNGM/{LINUX_BINARY}", (linux_build / LINUX_BINARY).read_bytes(), EXECUTABLE_MODE)
        add_bytes_to_tar(archive, "YNGM/YNGM.pck", (linux_build / "YNGM.pck").read_bytes(), FILE_MODE)
        add_bytes_to_tar(archive, "YNGM/install.sh", INSTALL_SCRIPT.encode("utf-8"), EXECUTABLE_MODE)
        add_bytes_to_tar(archive, "YNGM/README-LINUX.txt", readme.encode("utf-8"), FILE_MODE)
        add_bytes_to_tar(archive, "YNGM/yngm.png", (project / "game/assets/branding/yngm-logo.png").read_bytes(), FILE_MODE)
        add_bytes_to_tar(archive, "YNGM/CREDITS-AND-LICENSES.txt", (licenses / "CREDITS-AND-LICENSES.txt").read_bytes(), FILE_MODE)
        add_folder_to_tar(archive, licenses, "YNGM/licenses")
    logging.info("Linux package: %s", output)
    return output


def make_zip_info(name: str, mode: int) -> zipfile.ZipInfo:
    info = zipfile.ZipInfo(name)
    info.create_system = UNIX_SYSTEM
    info.external_attr = (0o100000 | mode) << 16
    info.compress_type = zipfile.ZIP_DEFLATED
    return info


def copy_zip_entries(source: zipfile.ZipFile, destination: zipfile.ZipFile) -> None:
    for entry in source.infolist():
        destination.writestr(entry, source.read(entry.filename))


def build_macos_package(project: Path, version: str, godot_zip: Path, output: Path) -> Path:
    licenses = project / "game/licenses"
    readme = MACOS_README.format(version=version, title=GAME_TITLE, assistant_help=ASSISTANT_HELP.format(readme="README-MACOS.txt"))
    with zipfile.ZipFile(godot_zip) as source, zipfile.ZipFile(output, "w", zipfile.ZIP_DEFLATED) as destination:
        copy_zip_entries(source, destination)
        destination.writestr(make_zip_info("README-MACOS.txt", FILE_MODE), readme)
        destination.writestr(make_zip_info("CREDITS-AND-LICENSES.txt", FILE_MODE), (licenses / "CREDITS-AND-LICENSES.txt").read_bytes())
        for path in sorted(licenses.rglob("*")):
            if path.is_file():
                destination.writestr(make_zip_info(f"licenses/{path.relative_to(licenses).as_posix()}", FILE_MODE), path.read_bytes())
    logging.info("macOS package: %s", output)
    return output
