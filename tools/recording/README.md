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
Recording creates an MP4, raw capture/audio and logs. Speakers remain muted;
unmute manually when wanted. No files are deleted.
