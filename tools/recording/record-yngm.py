"""Record YNGM through its normal window, with silent speakers and game audio."""
import argparse
import ctypes
import json
import logging
import os
import shutil
import subprocess
import sys
import time
import uuid
from ctypes import wintypes
from datetime import datetime
from pathlib import Path
from PIL import ImageGrab

PROJECT = Path(__file__).resolve().parents[2]
ENGINE = PROJECT / "tools/godot/Godot_v4.7.2-stable_win64.exe"
AUDIO_SCRIPT = Path(__file__).with_name("yngm-record-audio.gd")
USER32 = ctypes.WinDLL("user32", use_last_error=True)
USER32.SetProcessDPIAware()
USER32.GetForegroundWindow.restype = wintypes.HWND
USER32.SetForegroundWindow.argtypes = [wintypes.HWND]
USER32.GetClientRect.argtypes = [wintypes.HWND, ctypes.POINTER(wintypes.RECT)]
USER32.ClientToScreen.argtypes = [wintypes.HWND, ctypes.POINTER(wintypes.POINT)]
USER32.GetWindowThreadProcessId.argtypes = [wintypes.HWND, ctypes.POINTER(wintypes.DWORD)]
USER32.IsWindowVisible.argtypes = [wintypes.HWND]
CALLBACK = ctypes.WINFUNCTYPE(wintypes.BOOL, wintypes.HWND, wintypes.LPARAM)

def find_ffmpeg() -> Path:
    configured = os.environ.get("FFMPEG_PATH") or shutil.which("ffmpeg")
    if not configured:
        raise SystemExit("FFmpeg not found - put ffmpeg on PATH or set FFMPEG_PATH to its full path")
    return Path(configured)

class Guid(ctypes.Structure):
    _fields_ = [("bytes", ctypes.c_ubyte * 16)]

def make_guid(value: str) -> Guid:
    return Guid.from_buffer_copy(uuid.UUID(value).bytes_le)

def invoke_com(pointer, index: int, argument_types: tuple, *arguments) -> None:
    table = ctypes.cast(pointer, ctypes.POINTER(ctypes.POINTER(ctypes.c_void_p))).contents
    function = ctypes.WINFUNCTYPE(ctypes.c_long, ctypes.c_void_p, *argument_types)(table[index])
    result = function(pointer, *arguments)
    if result < 0:
        raise RuntimeError(f"Windows audio operation failed: {result:#x}")

def mute_speakers() -> bool:
    ole32 = ctypes.OleDLL("ole32")
    ole32.CoInitialize(None)
    enumerator, device, volume = (ctypes.c_void_p() for _ in range(3))
    identifier = make_guid("BCDE0395-E52F-467C-8E3D-C4579291692E")
    interface = make_guid("A95664D2-9614-4F35-A746-DE8DB63617E6")
    result = ole32.CoCreateInstance(ctypes.byref(identifier), None, 1,
                                  ctypes.byref(interface), ctypes.byref(enumerator))
    if result < 0:
        raise RuntimeError(f"Cannot access Windows speaker mute: {result:#x}")
    invoke_com(enumerator, 4, (ctypes.c_int, ctypes.c_int, ctypes.c_void_p),
               0, 1, ctypes.byref(device))
    interface = make_guid("5CDF2C82-841E-4546-9722-0CF74078229A")
    invoke_com(device, 3, (ctypes.c_void_p, ctypes.c_ulong, ctypes.c_void_p, ctypes.c_void_p),
               ctypes.byref(interface), 23, None, ctypes.byref(volume))
    invoke_com(volume, 14, (wintypes.BOOL, ctypes.c_void_p), True, None)
    muted = wintypes.BOOL()
    invoke_com(volume, 15, (ctypes.c_void_p,), ctypes.byref(muted))
    for pointer in (volume, device, enumerator):
        invoke_com(pointer, 2, ())
    ole32.CoUninitialize()
    if not muted.value:
        raise RuntimeError("Speakers are not muted; recording stopped")
    return True

def save_json(path: Path, value: dict) -> None:
    path.write_text(json.dumps(value, indent=2), encoding="utf-8")

def read_json(path: Path) -> dict:
    for _ in range(20):
        try:
            return json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            time.sleep(0.05)
    raise RuntimeError(f"Cannot read recording state: {path}")

def find_window(process_id: int) -> int | None:
    handles = []
    def inspect(handle, parameter):
        owner = wintypes.DWORD()
        USER32.GetWindowThreadProcessId(handle, ctypes.byref(owner))
        if owner.value == process_id and USER32.IsWindowVisible(handle):
            handles.append(handle)
        return True
    USER32.EnumWindows(CALLBACK(inspect), 0)
    return handles[0] if handles else None

def wait_window(process: subprocess.Popen) -> int:
    deadline = time.monotonic() + 30
    while time.monotonic() < deadline:
        handle = find_window(process.pid)
        if handle:
            return handle
        if process.poll() is not None:
            raise RuntimeError("Game exited before its window appeared")
        time.sleep(0.2)
    raise RuntimeError("Game window did not appear")

def get_window_region(handle: int) -> tuple[int, int, int, int]:
    rectangle, origin = wintypes.RECT(), wintypes.POINT()
    if not USER32.GetClientRect(handle, ctypes.byref(rectangle)):
        raise RuntimeError("Cannot inspect game window")
    USER32.ClientToScreen(handle, ctypes.byref(origin))
    return origin.x, origin.y, origin.x + rectangle.right, origin.y + rectangle.bottom

def launch_game(root: Path) -> tuple[subprocess.Popen, int]:
    mute_speakers()
    arguments = [str(ENGINE), "--path", str(PROJECT / "game"), "--fullscreen",
                 "--resolution", "1920x1080", "--max-fps", "60", "--script",
                 str(AUDIO_SCRIPT), "--", str(root)]
    with (root / "game.log").open("wb") as log:
        process = subprocess.Popen(arguments, stdout=log, stderr=log,
                                   creationflags=subprocess.CREATE_NO_WINDOW)
    handle = wait_window(process)
    USER32.SetForegroundWindow(handle)
    time.sleep(1)
    return process, handle

def start_capture(root: Path, handle: int) -> subprocess.Popen:
    arguments = [str(find_ffmpeg()), "-hide_banner", "-loglevel", "warning", "-n",
                 "-f", "gdigrab", "-framerate", "30", "-draw_mouse", "0",
                 "-i", f"hwnd={handle}", "-an", "-c:v", "libx264", "-threads", "2",
                 "-preset", "ultrafast", "-crf", "24", "-maxrate", "4000k",
                 "-bufsize", "8000k", "-pix_fmt", "yuv420p", "-stats_period", "0.2",
                 "-progress", str(root / "capture.progress"), str(root / "capture.mkv")]
    with (root / "capture.log").open("wb") as log:
        return subprocess.Popen(arguments, stdin=subprocess.PIPE, stdout=subprocess.DEVNULL,
                                stderr=log, creationflags=subprocess.CREATE_NO_WINDOW)

def wait_capture(root: Path, process: subprocess.Popen) -> float:
    deadline = time.monotonic() + 15
    while time.monotonic() < deadline:
        progress = root / "capture.progress"
        if progress.exists():
            lines = progress.read_text(encoding="utf-8").splitlines()
            values = dict(line.split("=", 1) for line in lines if "=" in line)
            if int(values.get("frame", "0")) > 0:
                return time.time() - int(values.get("out_time_us", "0")) / 1_000_000
        if process.poll() is not None:
            raise RuntimeError("Screen recording failed; inspect capture.log")
        time.sleep(0.03)
    raise RuntimeError("Screen recorder did not produce a frame")

def encode_video(root: Path, video_start: float) -> None:
    game_state = read_json(root / "game-state.json")
    audio_offset = max(0.0, game_state["audio_started"] - video_start)
    trim_seconds = float((root / "trim-start.txt").read_text()) if (root / "trim-start.txt").exists() else 0.0
    arguments = [str(find_ffmpeg()), "-hide_banner", "-loglevel", "warning", "-n",
                 "-ss", str(trim_seconds), "-i", str(root / "capture.mkv"), "-itsoffset", str(audio_offset),
                 "-ss", str(trim_seconds), "-i", str(root / "game-audio.wav"), "-map", "0:v:0", "-map", "1:a:0",
                 "-vf", "scale=1920:1080:flags=lanczos", "-c:v", "libx264", "-threads", "2",
                 "-preset", "medium", "-crf", "26", "-maxrate", "2200k", "-bufsize", "4400k",
                 "-pix_fmt", "yuv420p", "-c:a", "aac", "-b:a", "96k", "-ar", "48000",
                 "-af", "alimiter=limit=0.95", "-movflags", "+faststart",
                 str(root / "YNGM-full-playthrough-1080p.mp4")]
    with (root / "encode.log").open("wb") as log:
        subprocess.run(arguments, stdout=subprocess.DEVNULL, stderr=log, check=True)
    save_json(root / "result.json", {"video": str(root / "YNGM-full-playthrough-1080p.mp4"),
        "size_mb": round((root / "YNGM-full-playthrough-1080p.mp4").stat().st_size / 1e6, 2),
        "speakers_muted": mute_speakers(), "audio_offset_seconds": round(audio_offset, 3)})

def run_worker(root: Path) -> None:
    game, handle = launch_game(root)
    capture = start_capture(root, handle)
    video_start = wait_capture(root, capture)
    (root / "start-audio").write_text("start", encoding="utf-8")
    save_json(root / "session.json", {"worker_pid": __import__("os").getpid(),
        "game_pid": game.pid, "capture_pid": capture.pid, "handle": handle,
        "video_started": video_start, "region": get_window_region(handle)})
    while not (root / "stop-recording").exists():
        if game.poll() is not None or capture.poll() is not None:
            raise RuntimeError("Game or recorder exited unexpectedly")
        time.sleep(0.25)
    (root / "stop-audio").write_text("stop", encoding="utf-8")
    capture.stdin.write(b"q\n")
    capture.stdin.flush()
    capture.wait(timeout=30)
    game.wait(timeout=30)
    encode_video(root, video_start)

def start_worker(root: Path) -> None:
    root.mkdir(parents=True, exist_ok=False)
    arguments = [sys.executable, str(Path(__file__)), "worker", "--root", str(root)]
    with (root / "worker.log").open("wb") as log:
        process = subprocess.Popen(arguments, stdout=log, stderr=log,
                                   creationflags=subprocess.CREATE_NO_WINDOW)
    deadline = time.monotonic() + 45
    while time.monotonic() < deadline:
        if (root / "session.json").exists():
            print(json.dumps(read_json(root / "session.json")))
            return
        if process.poll() is not None:
            raise RuntimeError("Recorder startup failed; inspect worker.log and game.log")
        time.sleep(0.2)
    raise RuntimeError("Recorder startup timed out; inspect worker.log")

def focus_game(root: Path) -> int:
    handle = read_json(root / "session.json")["handle"]
    if USER32.GetForegroundWindow() != handle:
        USER32.keybd_event(0x12, USER32.MapVirtualKeyW(0x12, 0), 0, 0)
        USER32.SetForegroundWindow(handle)
        USER32.keybd_event(0x12, USER32.MapVirtualKeyW(0x12, 0), 0x0002, 0)
        time.sleep(0.2)
    if USER32.GetForegroundWindow() != handle:
        raise RuntimeError("Game is not focused; refusing keyboard/mouse input")
    return handle

def press_keys(keys: list[str], released: bool) -> None:
    bindings = {"shift": 0x10, "space": 0x20, "enter": 0x0D, "esc": 0x1B}
    for key in keys:
        if key == "fire":
            USER32.mouse_event(0x0004 if released else 0x0002, 0, 0, 0, 0)
        else:
            code = bindings.get(key, ord(key.upper()) if len(key) == 1 else None)
            if code is None:
                raise ValueError(f"Unknown input: {key}")
            USER32.keybd_event(code, USER32.MapVirtualKeyW(code, 0), 0x0002 if released else 0, 0)

def perform_action(root: Path, arguments) -> None:
    focus_game(root)
    if arguments.click:
        USER32.SetCursorPos(*arguments.click)
        press_keys(["fire"], False)
        time.sleep(0.08)
        press_keys(["fire"], True)
    if arguments.look:
        USER32.mouse_event(0x0001, arguments.look[0], arguments.look[1], 0, 0)
    keys = arguments.keys.split(",") if arguments.keys else []
    try:
        press_keys(keys, False)
        time.sleep(arguments.seconds)
    finally:
        press_keys(list(reversed(keys)), True)
    time.sleep(0.1)
    print(json.dumps(read_json(root / "game-state.json")))

def save_snapshot(root: Path) -> None:
    handle = focus_game(root)
    destination = root / f"frame-{datetime.now():%H%M%S}.png"
    ImageGrab.grab(bbox=get_window_region(handle)).save(destination)
    print(destination)
    print(json.dumps(read_json(root / "game-state.json")))

def tap_input(key: str) -> None:
    press_keys([key], False)
    time.sleep(0.06)
    press_keys([key], True)

def turn_toward(state: dict, target: tuple[float, float]) -> float:
    import math
    delta_x = target[0] - state["position"][0]
    delta_z = target[1] - state["position"][2]
    desired_yaw = math.atan2(-delta_x, -delta_z)
    yaw_error = (desired_yaw - state["yaw"] + math.pi) % (2 * math.pi) - math.pi
    horizontal = max(-500, min(500, round(-yaw_error / 0.0025)))
    vertical = max(-50, min(50, round((state["pitch"] + 0.45) / 0.0025)))
    USER32.mouse_event(0x0001, horizontal, vertical, 0, 0)
    return yaw_error

def drive_to(root: Path, target: tuple[float, float], weapon: int) -> None:
    import math
    tap_input(str(weapon))
    deadline, next_shot = time.monotonic() + 30, 0.0
    last_state_time, moving = 0.0, False
    while time.monotonic() < deadline:
        state = read_json(root / "game-state.json")
        if state["state"] == "WON":
            return
        if state["state"] != "PLAYING":
            raise RuntimeError(f"Playthrough ended in {state['state']}")
        distance = math.hypot(target[0] - state["position"][0], target[1] - state["position"][2])
        if distance < 1.0:
            press_keys(["w", "fire"], True)
            print(json.dumps({"target": target, "state": state}), flush=True)
            return
        if state["time"] != last_state_time:
            yaw_error = turn_toward(state, target)
            moving = abs(yaw_error) < 0.5
            press_keys(["w"], not moving)
            last_state_time = state["time"]
        if weapon == 1:
            press_keys(["fire"], False)
        elif time.monotonic() >= next_shot:
            tap_input("fire")
            next_shot = time.monotonic() + (1.3 if weapon == 3 else 0.95)
        time.sleep(0.06)
    raise RuntimeError(f"Movement blocked before waypoint {target}")

def play_route(root: Path) -> None:
    focus_game(root)
    state = read_json(root / "game-state.json")
    if state["state"] == "LOST":
        tap_input("r")
        time.sleep(2)
    state = read_json(root / "game-state.json")
    if state["state"] == "READY":
        tap_input("fire")
        time.sleep(0.5)
    press_keys(["shift"], False)
    targets = [(0, -12, 1), (-4, -25, 3), (-7, -37, 3), (0, -44, 2),
        (7, -57, 3), (2, -70, 3), (0, -84, 3), (3, -86, 3),
        (3, -81.6, 3), (11, -81.6, 3), (11, -103, 3), (8, -112, 3), (8, -110, 3), (-6, -110, 3), (-6, -101.5, 3), (-10.75, -101.5, 3),
        (-10.75, -118.5, 3), (-6, -118.5, 3), (-1, -118.5, 3), (-1, -100, 3), (5, -95, 3)]
    try:
        for x, z, weapon in targets:
            if read_json(root / "game-state.json")["state"] == "WON":
                break
            drive_to(root, (x, z), weapon)
    finally:
        press_keys(["w", "fire", "shift"], True)
    print(json.dumps(read_json(root / "game-state.json")), flush=True)

def parse_arguments():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=["launch", "worker", "action", "snapshot", "status", "finish", "mute", "play"])
    parser.add_argument("--root", type=Path)
    parser.add_argument("--keys", default="")
    parser.add_argument("--seconds", type=float, default=0.1)
    parser.add_argument("--look", type=int, nargs=2)
    parser.add_argument("--click", type=int, nargs=2)
    return parser.parse_args()

def main() -> None:
    arguments = parse_arguments()
    root = arguments.root
    if arguments.command == "mute":
        print(json.dumps({"speakers_muted": mute_speakers()}))
        return
    if root is None:
        raise ValueError("--root is required")
    commands = {"launch": lambda: start_worker(root), "worker": lambda: run_worker(root),
        "action": lambda: perform_action(root, arguments), "play": lambda: play_route(root), "snapshot": lambda: save_snapshot(root),
        "status": lambda: print(json.dumps(read_json(root / "game-state.json"))),
        "finish": lambda: (root / "stop-recording").write_text("stop", encoding="utf-8")}
    commands[arguments.command]()

if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")
    try:
        main()
    except Exception:
        logging.exception("Recording operation failed")
        sys.exit(1)