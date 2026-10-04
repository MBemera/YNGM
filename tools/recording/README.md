# Recording helpers

`record-yngm.py` records the game window with FFmpeg and uses the neighbouring
`yngm-record-audio.gd` to capture the Master audio bus independently of speaker mute.
It keeps Windows speakers muted. Inputs use normal Windows keyboard/mouse events.
The game code is not modified. Windows, Python/Pillow, the project-local Godot in
`tools/godot/` and FFmpeg are required. FFmpeg is found on `PATH`, or set `FFMPEG_PATH`
to its full path.

Run from the project root, using a new output folder:

```
python tools/recording/record-yngm.py launch --root recordings/new-take
python tools/recording/record-yngm.py snapshot --root recordings/new-take
python tools/recording/record-yngm.py action --root recordings/new-take --keys w,shift --seconds 2
python tools/recording/record-yngm.py play --root recordings/new-take
python tools/recording/record-yngm.py finish --root recordings/new-take
```

`play` starts from READY/LOST and follows the normal-input route to victory.
It runs a fixed waypoint route and does not aim at enemies, so use the per-level
recorder below for gameplay footage.
Recording creates an MP4, raw capture/audio and logs. Speakers remain muted;
unmute manually when wanted. No files are deleted.

## Per-level YouTube clips (Movie Maker)

`record-yngm-levels.py` renders each level with Godot's Movie Maker at the HIGH preset,
1920x1080 and a locked 60 fps, so the video plays at normal speed even though this laptop
renders HIGH 1080p well below 60 fps. The autoplay bot plays on Normal in `--recording` mode:
it lets the story play out, reacts and aims like a person (no projectile dodging), walks while
fighting, takes damage and can lose; a lost attempt stays in the clip, followed by the retry.

```
set FFMPEG_PATH=C:\path\to\ffmpeg.exe
python tools/recording/record-yngm-levels.py --output recordings/youtube-demo
python tools/recording/record-yngm-levels.py --output recordings/youtube-demo --levels 3 4
```

Output: `clips/NN - Level Title.mp4` (H.264 CRF 17 tagged BT.709 + AAC 384k, 1080p60), a joined full
playthrough, `recording-summary.json` (duration, attempts, deaths, hits taken), raw `.ogv`
movies, bot reports and logs. Existing clips are kept, so a re-run resumes. While it runs,
the script writes a temporary `game/override.cfg` (1920x1080 borderless window) and removes
it afterwards. Budget about 10 minutes per level (render plus encode); keep the game window open (do not minimise it).

Process notes, pitfalls and the Taildrop step: [RECORDING-PROCESS.md](RECORDING-PROCESS.md).
