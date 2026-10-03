"""Generate every voice clip in the game with Piper TTS and public-domain/CC0 voices.

Existing clips are kept; only missing clips are synthesised.
Run: tools\\tts\\venv\\Scripts\\python tools\\generate_voice.py
"""

import json
import wave
from pathlib import Path

from piper import PiperVoice, SynthesisConfig

PROJECT_ROOT = Path(__file__).resolve().parent.parent
VOICE_MODELS = PROJECT_ROOT / "tools" / "tts" / "voices"
OUTPUT_DIRECTORY = PROJECT_ROOT / "game" / "assets" / "audio" / "voice"
STORY_DIRECTORY = PROJECT_ROOT / "game" / "data" / "story"
CAST_FILE = STORY_DIRECTORY / "cast.json"
VOICES = {
    "joe": "en_US-joe-medium.onnx",
    "norman": "en_US-norman-medium.onnx",
    "kristin": "en_US-kristin-medium.onnx",
    "john": "en_US-john-medium.onnx",
}
ENEMY_LINES = {
    "left_behind": "Don't get left behind!",
    "not_gonna_make_it": "You're not gonna make it!",
    "we_will_pass": "We'll pass.",
    "pivoting": "Pivoting!",
    "acqui_hired": "Ackwee hired!",
    "my_valuation": "Ow! My valuation!",
    "not_in_term_sheet": "That's not in the term sheet!",
    "does_not_compile": "It doesn't even compile!",
    "who_wrote_this": "Who wrote this?!",
    "take_offline": "Let's take this offline.",
    "unsubscribing": "Unsubscribing!",
    "package_delivered": "Package delivered!",
    "youre_in_the_round": "Fine. You're in the round.",
    "meeting_adjourned": "This meeting is adjourned!",
    "everybody_gets_a_ladder": "Okay! Okay! Everybody gets a ladder!",
    "cannot_comment": "I can't comment on that.",
}
ENEMY_SPEECH = SynthesisConfig(length_scale=0.9, noise_scale=0.8, noise_w_scale=0.9)
NARRATION_SPEECH = SynthesisConfig(length_scale=1.02, noise_scale=0.6, noise_w_scale=0.8)


def load_voice(voice_name: str) -> PiperVoice:
    return PiperVoice.load(str(VOICE_MODELS / VOICES[voice_name]))


def write_clip(voice: PiperVoice, text: str, destination: Path, speech: SynthesisConfig) -> None:
    if destination.exists():
        return
    with wave.open(str(destination), "wb") as wav_file:
        voice.synthesize_wav(text, wav_file, syn_config=speech)
    print(f"Wrote {destination.name}")


def generate_enemy_lines(voices: dict[str, PiperVoice]) -> None:
    for voice_name, voice in voices.items():
        for line_id, text in ENEMY_LINES.items():
            write_clip(voice, text, OUTPUT_DIRECTORY / f"{voice_name}_{line_id}.wav", ENEMY_SPEECH)


def generate_story(voices: dict[str, PiperVoice]) -> None:
    cast = json.loads(CAST_FILE.read_text(encoding="utf-8"))
    for story_file in sorted(STORY_DIRECTORY.glob("*.json")):
        if story_file == CAST_FILE:
            continue
        for line in json.loads(story_file.read_text(encoding="utf-8"))["lines"]:
            voice_name = cast[line["cast"]]["voice"]
            destination = OUTPUT_DIRECTORY / f"{voice_name}_story_{line['id']}.wav"
            write_clip(voices[voice_name], line["spoken"], destination, NARRATION_SPEECH)


def main() -> None:
    OUTPUT_DIRECTORY.mkdir(parents=True, exist_ok=True)
    voices = {voice_name: load_voice(voice_name) for voice_name in VOICES}
    generate_enemy_lines(voices)
    generate_story(voices)


if __name__ == "__main__":
    main()
