# Recording YNGM gameplay for YouTube

How the October 2026 level clips were made, and what to watch for next time.

## What you get

One clip per level, `NN - Level Title.mp4`: HIGH graphics, 1920x1080, a steady 60 fps, H.264 High at CRF 17
(20-48 Mbps) tagged BT.709, with AAC-LC 384k stereo peak-limited to -1.5 dBFS, which matches YouTube's
recommended upload settings. Each clip runs menu (level 1 only) or loading screen, voiced intro,
READY card, gameplay with any lost attempts and retries, then the result screen held for 5 seconds.
Normal difficulty. About 2 minutes of video per level for levels 1-9 and about 3.5 minutes for the
boss levels 10-11.

## Run it

```
set FFMPEG_PATH=<full path to ffmpeg.exe>
python tools/recording/record-yngm-levels.py --output recordings/<new-folder> --levels 1 2 3 4 5 6 --skip-full
```

- Leave out `--levels` to record all 11. Leave out `--skip-full` to also join the clips into one full video.
- Re-running with the same `--output` keeps finished clips, so a stopped run resumes where it left off.
  Clips are encoded to a `.partial.mp4` file first, so an interrupted encode is redone, not kept.
- Run one recording at a time. Runs share `game/override.cfg`.
- Budget about 10 minutes per level on this laptop: roughly 5.5x the clip length to render and 4x to encode.
- A borderless 1920x1080 game window covers the screen. Do not minimise or close it. Covering it with another
  window is fine.
- Speakers stay silent. Movie Maker mixes the game audio straight into the file.

## Why it works this way

- **Movie Maker, not screen capture.** HIGH at 1080p renders at only about 20-29 fps on the Intel UHD
  laptop, so a live capture is choppy. Godot's `--write-movie` renders every frame at a fixed 60 fps of game
  time, so the video plays at normal speed and the audio stays in sync.
- **1080p needs `game/override.cfg`.** Movie Maker sizes the video from
  `display/window/size/window_width_override` and ignores `--resolution` and `--fullscreen`. Godot reads
  `override.cfg` only from the project folder. The script writes it and removes it afterwards, and refuses to
  run if a different `override.cfg` is already there. `.gitignore` keeps it out of git.
- **Raw `.ogv`, not `.avi`.** Godot's MJPEG `.avi` writer uses 32-bit offsets, so anything over 4 GB
  (about 2.3 minutes at 1080p) breaks. Theora `.ogv` at `encoding_speed=4` runs at about 13-18% of real time at
  about 40 Mbps. FFmpeg warns "keyframe not correctly marked" when reading these files; that is harmless.
- **Colour is converted to BT.709.** Godot's Theora writer converts RGB with BT.601 coefficients and leaves
  the colour space unset. YouTube reads untagged HD as BT.709, which shifts reds and greens, so the encode
  converts BT.601 to BT.709 and tags the result.
- **Game timers use game time** (`GameClock.get_msec()`). Under Movie Maker the wall clock runs about 6x
  faster than game time. Any new gameplay timer must use game time too, or enemies fire more often on video
  than in real play.
- **New `class_name` scripts** need `Godot --headless --path game --import` once, or scripts fail with
  "Identifier not declared". The import also rewrites some `.wav.import` files with different line endings.
  That is noise; restore them with `git checkout -- game/assets/audio/voice/*.import`.

## How the bot plays on video (`--recording`)

`game/tests/autoplay/autoplay_bot.gd` normally plays superhumanly: instant perfect aim, dodges every shot,
about 25 s per level, never hurt. That looks fake. In `--recording` mode it plays like a person:

- it waits for the story and holds the menu, READY, result and loss screens
- it reacts 0.25-0.5 s after a new enemy appears, turns smoothly at up to 260 deg/s and its aim wobbles
- it notices 75% of incoming shots and only starts dodging 0.25 s after a shot appears, so it takes real damage
- it walks while fighting and sprints while travelling and in boss fights; it heads for a health pack below 55% runway
- after each death on a level it gets better, reaching full skill after 3 deaths, so it can lose but always finishes

Expect levels 1-9 on the first attempt with 4-20 of 24 runway left. In headless trials the boss levels 10-11
took one to three attempts, and any losses stay in the clip.

The old `record-yngm.py play` route only ran fixed waypoints with the camera tipped at the floor. That is the
clip where the weapons looked held, not fired. Do not use it for footage.

Before a long render, test the bot headless and fast:

```
tools\godot\Godot_v4.7.2-stable_win64_console.exe --headless --fixed-fps 60 --disable-vsync --path game --script res://tests/autoplay/playthrough.gd -- --recording --start-level=10 --stop-after-level=10 --difficulty=normal --report-dir=<folder>
```

## Check before posting

- `ffprobe` each clip: h264 1920x1080 60/1, aac 48000 stereo, and a duration that matches `recording-summary.json`.
- Pull a frame every 3 seconds into a contact sheet. You should see the intro, the bot aiming at enemies,
  shots leaving the barrel, damage numbers and enemy exit lines, the runway going down, and the result screen.
- `recording-summary.json` lists attempts, deaths, hits taken and runway lost per level.

## Send to the iPhone

The clips can go over Taildrop to a phone on your tailnet, with Tailscale open on the phone. Files land in the
Tailscale app's Files folder, and from there you save them to Photos:

```
tailscale file cp "recordings/<folder>/clips/01 - South of Market.mp4" <device>:
```

Send one file at a time. Each clip is 300-450 MB.
