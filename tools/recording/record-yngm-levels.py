"""Record each YNGM level with Godot Movie Maker (HIGH, 1920x1080, 60 fps) into labelled YouTube-ready clips."""
import argparse
import json
import logging
import os
import shutil
import subprocess
import sys
from pathlib import Path

PROJECT = Path(__file__).resolve().parents[2]
GAME = PROJECT / "game"
ENGINE = PROJECT / "tools/godot/Godot_v4.7.2-stable_win64_console.exe"
OVERRIDE = GAME / "override.cfg"
OVERRIDE_TEXT = """; Temporary file written by record-yngm-levels.py for Movie Maker. Safe to delete.
[display]

window/size/window_width_override=1920
window/size/window_height_override=1080
window/size/borderless=true
window/size/initial_position_type=0
window/size/initial_position=Vector2i(0, 0)

[editor]

movie_writer/video_quality=0.95
movie_writer/ogv/encoding_speed=4
movie_writer/ogv/keyframe_interval=60
movie_writer/ogv/audio_quality=0.8
"""
LEVEL_TITLES = {
    1: "South of Market", 2: "The Opportunity Center", 3: "The 101", 4: "Sand Hill Road",
    5: "Disrupt-a-thon", 6: "Overclass Campus", 7: "Cold Aisle", 8: "Pier 70",
    9: "The Ark", 10: "The Boardroom", 11: "OMEGA",
}
RENDER_TIMEOUT_SECONDS = 6 * 60 * 60
BT601_TO_BT709 = ("colorspace=space=bt709:primaries=bt709:trc=bt709:range=tv:"
                  "ispace=bt470bg:iprimaries=bt709:itrc=bt709:irange=tv")
PEAK_LIMITER = "alimiter=limit=0.84:level=false"


def find_tool(name: str) -> Path:
    configured = os.environ.get("FFMPEG_PATH")
    if configured:
        candidate = Path(configured).with_name(f"{name}.exe")
        if candidate.exists():
            return candidate
    found = shutil.which(name)
    if not found:
        raise SystemExit(f"{name} not found - put it on PATH or set FFMPEG_PATH to ffmpeg.exe's full path")
    return Path(found)


def get_clip_name(level: int) -> str:
    return f"{level:02d} - {LEVEL_TITLES[level]}.mp4"


def write_override() -> None:
    if OVERRIDE.exists() and OVERRIDE.read_text(encoding="utf-8") != OVERRIDE_TEXT:
        raise SystemExit(f"{OVERRIDE} already exists and was not written by this script; refusing to replace it")
    OVERRIDE.write_text(OVERRIDE_TEXT, encoding="utf-8")


def remove_override() -> None:
    if OVERRIDE.exists() and OVERRIDE.read_text(encoding="utf-8") == OVERRIDE_TEXT:
        OVERRIDE.unlink()


def render_level(level: int, output: Path) -> Path:
    movie = output / "raw" / f"L{level:02d}.ogv"
    report = output / "reports" / f"L{level:02d}"
    report.mkdir(parents=True, exist_ok=True)
    arguments = [str(ENGINE), "--path", str(GAME), "--write-movie", str(movie),
                 "--script", "res://tests/autoplay/playthrough.gd", "--", "--recording",
                 f"--start-level={level}", f"--stop-after-level={level}", "--difficulty=normal",
                 "--quality=high", f"--report-dir={report}"]
    logging.info("Rendering level %d to %s", level, movie)
    with (output / "logs" / f"L{level:02d}-godot.log").open("wb") as log:
        result = subprocess.run(arguments, stdout=log, stderr=subprocess.STDOUT, timeout=RENDER_TIMEOUT_SECONDS)
    summary = json.loads((report / "playthrough.json").read_text(encoding="utf-8"))
    if result.returncode != 0 or not summary["complete"]:
        raise RuntimeError(f"Level {level} did not finish (exit {result.returncode}); see logs/L{level:02d}-godot.log")
    return movie


def encode_clip(movie: Path, clip: Path, output: Path) -> None:
    arguments = [str(find_tool("ffmpeg")), "-hide_banner", "-loglevel", "warning", "-n", "-i", str(movie),
                 "-vf", BT601_TO_BT709, "-c:v", "libx264", "-preset", "slow", "-crf", "17", "-profile:v", "high",
                 "-pix_fmt", "yuv420p", "-r", "60", "-g", "30", "-bf", "2", "-colorspace", "bt709",
                 "-color_primaries", "bt709", "-color_trc", "bt709", "-color_range", "tv",
                 "-af", PEAK_LIMITER, "-c:a", "aac", "-b:a", "384k", "-ar", "48000",
                 "-movflags", "+faststart", str(clip)]
    logging.info("Encoding %s", clip.name)
    with (output / "logs" / f"{clip.stem}-encode.log").open("wb") as log:
        subprocess.run(arguments, stdout=subprocess.DEVNULL, stderr=log, check=True)


def get_duration_seconds(clip: Path) -> float:
    arguments = [str(find_tool("ffprobe")), "-v", "error", "-show_entries", "format=duration",
                 "-of", "default=noprint_wrappers=1:nokey=1", str(clip)]
    return float(subprocess.run(arguments, capture_output=True, text=True, check=True).stdout.strip())


def join_full_playthrough(clips: list[Path], output: Path) -> Path:
    playlist = output / "logs" / "full-playthrough-list.txt"
    playlist.write_text("".join(f"file '{clip.as_posix()}'\n" for clip in clips), encoding="utf-8")
    full_video = output / "YNGM - Full Playthrough (Normal, High, 1080p60).mp4"
    arguments = [str(find_tool("ffmpeg")), "-hide_banner", "-loglevel", "warning", "-n", "-f", "concat",
                 "-safe", "0", "-i", str(playlist), "-c", "copy", "-movflags", "+faststart", str(full_video)]
    with (output / "logs" / "full-playthrough-join.log").open("wb") as log:
        subprocess.run(arguments, stdout=subprocess.DEVNULL, stderr=log, check=True)
    return full_video


def summarise_level(level: int, clip: Path, output: Path) -> dict:
    report = json.loads((output / "reports" / f"L{level:02d}" / "playthrough.json").read_text(encoding="utf-8"))
    result = report["levels"][str(level)]
    return {"level": level, "title": LEVEL_TITLES[level], "clip": f"clips/{clip.name}",
            "duration_seconds": round(get_duration_seconds(clip), 1), "attempts": result["attempts"],
            "deaths": result["deaths"], "hits_taken": result["hits_taken"],
            "runway_lost_months": result["runway_lost"], "runway_left": result.get("runway_left"),
            "max_runway": result.get("max_runway"), "enemies_defeated": result.get("enemies_defeated")}


def record_level(level: int, output: Path) -> Path:
    clip = output / "clips" / get_clip_name(level)
    if clip.exists():
        logging.info("Keeping existing %s", clip.name)
        return clip
    movie = render_level(level, output)
    encode_clip(movie, clip, output)
    return clip


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True, help="folder for clips, raw movies, reports and logs")
    parser.add_argument("--levels", type=int, nargs="+", default=list(LEVEL_TITLES), help="levels to record")
    parser.add_argument("--skip-full", action="store_true", help="do not join the clips into one full video")
    return parser.parse_args()


def main() -> None:
    arguments = parse_arguments()
    output = arguments.output.resolve()
    for folder in ("clips", "raw", "reports", "logs"):
        (output / folder).mkdir(parents=True, exist_ok=True)
    write_override()
    try:
        clips = [record_level(level, output) for level in arguments.levels]
    finally:
        remove_override()
    summary = [summarise_level(level, clip, output) for level, clip in zip(arguments.levels, clips)]
    if not arguments.skip_full:
        summary.append({"full_video": join_full_playthrough(clips, output).name})
    (output / "recording-summary.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
    logging.info("Done: %s", output)


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s: %(message)s")
    try:
        main()
    except Exception:
        logging.exception("Recording failed")
        sys.exit(1)
