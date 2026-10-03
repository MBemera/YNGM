"""Generate the game's sound effects as 16-bit mono WAV files using only the standard library.

Run: python tools/generate_sfx.py
"""

import math
import random
import struct
import wave
from pathlib import Path

SAMPLE_RATE = 22050
PEAK_LEVEL = 0.9
OUTPUT_DIRECTORY = Path(__file__).resolve().parent.parent / "game" / "assets" / "audio" / "sfx"


def sample_times(duration_seconds: float) -> list[float]:
    return [index / SAMPLE_RATE for index in range(int(duration_seconds * SAMPLE_RATE))]


def white_noise(count: int, rng: random.Random) -> list[float]:
    return [rng.uniform(-1.0, 1.0) for _ in range(count)]


def low_pass(samples: list[float], smoothing: float) -> list[float]:
    filtered: list[float] = []
    previous = 0.0
    for sample in samples:
        previous += smoothing * (sample - previous)
        filtered.append(previous)
    return filtered


def tone(frequency: float, duration_seconds: float, decay: float) -> list[float]:
    return [math.sin(2 * math.pi * frequency * t) * math.exp(-t * decay) for t in sample_times(duration_seconds)]


def normalize(samples: list[float]) -> list[float]:
    loudest = max(abs(sample) for sample in samples) or 1.0
    return [sample * PEAK_LEVEL / loudest for sample in samples]


def make_dart(rng: random.Random) -> list[float]:
    times = sample_times(0.12)
    burst = low_pass(white_noise(len(times), rng), 0.35)
    return [burst[index] * math.exp(-t * 35) for index, t in enumerate(times)]


def make_confetti_pop(rng: random.Random) -> list[float]:
    times = sample_times(0.45)
    crackle = white_noise(len(times), rng)
    samples = []
    for index, t in enumerate(times):
        thump = math.sin(2 * math.pi * (180 - 120 * t) * t) * math.exp(-t * 18)
        sparkle_level = 1.0 if rng.random() < 0.08 else 0.15
        samples.append(0.7 * thump + 0.5 * crackle[index] * sparkle_level * math.exp(-t * 7))
    return samples


def make_hit() -> list[float]:
    return [a + 0.5 * b for a, b in zip(tone(520, 0.1, 40), tone(780, 0.1, 50))]


def make_hurt() -> list[float]:
    times = sample_times(0.22)
    return [(1.0 if math.sin(2 * math.pi * (140 - 200 * t) * t) > 0 else -1.0) * 0.5 * math.exp(-t * 9) for t in times]


def make_throw(rng: random.Random) -> list[float]:
    times = sample_times(0.3)
    whoosh = low_pass(white_noise(len(times), rng), 0.12)
    return [whoosh[index] * math.sin(math.pi * t / 0.3) for index, t in enumerate(times)]


def make_beam() -> list[float]:
    times = sample_times(0.14)
    return [math.sin(2 * math.pi * (1400 - 3200 * t) * t) * math.exp(-t * 12) for t in times]


def make_melody(notes: list[tuple[float, float]], vibrato: float) -> list[float]:
    samples: list[float] = []
    for frequency, duration in notes:
        for t in sample_times(duration):
            wobble = 1 + vibrato * math.sin(2 * math.pi * 6 * t)
            envelope = min(1.0, t * 40) * math.exp(-t * 2.5)
            samples.append(math.sin(2 * math.pi * frequency * wobble * t) * envelope)
    return samples


def make_rotor(rng: random.Random) -> list[float]:
    times = sample_times(1.0)
    rumble = low_pass(white_noise(len(times), rng), 0.08)
    return [rumble[index] * (0.3 + 0.7 * max(0.0, math.sin(2 * math.pi * 9 * t)) ** 3) for index, t in enumerate(times)]


def make_slop_explosion(rng: random.Random) -> list[float]:
    times = sample_times(1.4)
    rumble = low_pass(white_noise(len(times), rng), 0.06)
    crackle = white_noise(len(times), rng)
    samples = []
    for index, t in enumerate(times):
        thump = math.sin(2 * math.pi * (70 - 30 * t) * t) * math.exp(-t * 5)
        blast = 2.5 * rumble[index] * math.exp(-t * 3.2)
        crack = 0.6 * crackle[index] * math.exp(-t * 14)
        squelch = 0.5 * math.sin(2 * math.pi * (240 - 150 * t) * t + 3 * math.sin(2 * math.pi * 23 * t)) * math.exp(-t * 6)
        samples.append(thump + blast + crack + squelch)
    return samples


def make_bounce(rng: random.Random) -> list[float]:
    times = sample_times(0.12)
    click = low_pass(white_noise(len(times), rng), 0.5)
    return [math.sin(2 * math.pi * 180 * t) * math.exp(-t * 45) + 0.4 * click[index] * math.exp(-t * 80) for index, t in enumerate(times)]


def make_staple(rng: random.Random) -> list[float]:
    times = sample_times(0.16)
    clack = low_pass(white_noise(len(times), rng), 0.6)
    return [0.8 * clack[index] * math.exp(-t * 60) + 0.6 * math.sin(2 * math.pi * 900 * t) * math.exp(-t * 70) for index, t in enumerate(times)]


def make_rail(rng: random.Random) -> list[float]:
    times = sample_times(0.7)
    hiss = low_pass(white_noise(len(times), rng), 0.25)
    samples = []
    for index, t in enumerate(times):
        zap = math.sin(2 * math.pi * (2400 * math.exp(-t * 6) + 120) * t) * math.exp(-t * 5)
        thump = math.sin(2 * math.pi * 60 * t) * math.exp(-t * 12)
        samples.append(0.6 * zap + 0.7 * thump + 0.3 * hiss[index] * math.exp(-t * 4))
    return samples


def make_bubble() -> list[float]:
    times = sample_times(0.35)
    return [math.sin(2 * math.pi * (300 + 900 * t) * t + 2 * math.sin(2 * math.pi * 18 * t)) * math.sin(math.pi * t / 0.35) for t in times]


def make_pop(rng: random.Random) -> list[float]:
    times = sample_times(0.5)
    burst = white_noise(len(times), rng)
    return [math.sin(2 * math.pi * (900 - 1400 * t) * t) * math.exp(-t * 14) + 0.5 * burst[index] * math.exp(-t * 30) for index, t in enumerate(times)]


def make_zap(rng: random.Random) -> list[float]:
    times = sample_times(0.3)
    crackle = white_noise(len(times), rng)
    samples = []
    for index, t in enumerate(times):
        buzz = 1.0 if math.sin(2 * math.pi * 110 * t) > 0 else -1.0
        gate = 1.0 if rng.random() < 0.6 else 0.2
        samples.append((0.4 * buzz + 0.6 * crackle[index] * gate) * math.exp(-t * 9))
    return samples


def make_alarm() -> list[float]:
    times = sample_times(1.2)
    return [math.sin(2 * math.pi * (620 if int(t * 4) % 2 == 0 else 470) * t) * 0.8 for t in times]


def make_slam(rng: random.Random) -> list[float]:
    times = sample_times(1.0)
    rumble = low_pass(white_noise(len(times), rng), 0.04)
    return [math.sin(2 * math.pi * (55 - 20 * t) * t) * math.exp(-t * 4) + 2.0 * rumble[index] * math.exp(-t * 3) for index, t in enumerate(times)]


def write_wav(path: Path, samples: list[float]) -> None:
    frames = b"".join(struct.pack("<h", int(sample * 32767)) for sample in normalize(samples))
    with wave.open(str(path), "wb") as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(SAMPLE_RATE)
        wav_file.writeframes(frames)


def build_sounds(rng: random.Random) -> dict[str, list[float]]:
    return {
        "dart": make_dart(rng),
        "confetti": make_confetti_pop(rng),
        "hit": make_hit(),
        "hurt": make_hurt(),
        "throw": make_throw(rng),
        "beam": make_beam(),
        "win": make_melody([(523.25, 0.14), (659.25, 0.14), (783.99, 0.14), (1046.5, 0.5)], 0.0),
        "lose": make_melody([(392.0, 0.35), (370.0, 0.35), (349.2, 0.35), (329.6, 1.0)], 0.01),
        "rotor": make_rotor(rng),
        "slop_explosion": make_slop_explosion(rng),
        "bounce": make_bounce(rng),
        "pickup": make_melody([(659.25, 0.07), (880.0, 0.07), (1318.5, 0.3)], 0.0),
        "staple": make_staple(rng),
        "rail": make_rail(rng),
        "bubble": make_bubble(),
        "pop": make_pop(rng),
        "zap": make_zap(rng),
        "objective": make_melody([(783.99, 0.1), (1046.5, 0.1), (1318.5, 0.1), (1567.98, 0.4)], 0.0),
        "alarm": make_alarm(),
        "slam": make_slam(rng),
    }


def main() -> None:
    OUTPUT_DIRECTORY.mkdir(parents=True, exist_ok=True)
    for name, samples in build_sounds(random.Random(7)).items():
        path = OUTPUT_DIRECTORY / f"{name}.wav"
        write_wav(path, samples)
        print(f"Wrote {path}")


if __name__ == "__main__":
    main()
