#!/usr/bin/env python3
"""Offline BGM analysis: RMS energy envelope + approximate BPM/beat grid.

Writes compact JSON under assets/audio/analysis/ for MusicDirector.
Uses ffmpeg + numpy only (no scipy).
"""
from __future__ import annotations

import json
import math
import subprocess
import struct
import sys
from pathlib import Path

import numpy as np

SR = 22050
HOP = 0.05  # 50ms energy hop
ENERGY_HOP = 0.1  # store energy every 100ms in JSON


def decode_mono(path: Path) -> np.ndarray:
    cmd = [
        "ffmpeg", "-v", "error", "-i", str(path),
        "-f", "f32le", "-ac", "1", "-ar", str(SR), "-",
    ]
    raw = subprocess.check_output(cmd)
    return np.frombuffer(raw, dtype=np.float32)


def rms_envelope(samples: np.ndarray, hop_s: float) -> np.ndarray:
    hop = max(1, int(SR * hop_s))
    n = len(samples) // hop
    if n == 0:
        return np.zeros(1, dtype=np.float32)
    trimmed = samples[: n * hop].reshape(n, hop)
    env = np.sqrt(np.mean(trimmed * trimmed, axis=1) + 1e-12)
    # Smooth a bit
    k = 5
    kernel = np.ones(k) / k
    env = np.convolve(env, kernel, mode="same")
    return env.astype(np.float32)


def estimate_bpm(env: np.ndarray, hop_s: float) -> tuple[float, float]:
    """Autocorrelation of onset strength → BPM in [70, 180]. Returns (bpm, beat_offset)."""
    # Onset strength: positive diff of energy
    onset = np.maximum(0.0, np.diff(env, prepend=env[0]))
    # Normalize
    onset = onset - onset.mean()
    if onset.std() < 1e-8:
        return 120.0, 0.0

    # Autocorr
    n = len(onset)
    # Limit lag search window for speed
    max_lag = min(n - 1, int(3.0 / hop_s))  # up to 3s
    min_lag = max(1, int(0.33 / hop_s))  # ~180 BPM
    # Use FFT autocorr
    f = np.fft.rfft(onset, n=2 * n)
    ac = np.fft.irfft(f * np.conj(f))[:n]
    ac = ac / (ac[0] + 1e-12)
    search = ac[min_lag:max_lag]
    if len(search) == 0:
        return 120.0, 0.0
    peak = int(np.argmax(search)) + min_lag
    period_s = peak * hop_s
    bpm = 60.0 / period_s
    # Prefer doubling/halving into musical range
    while bpm < 70:
        bpm *= 2
    while bpm > 180:
        bpm /= 2

    # Beat offset: first strong onset near start
    beat_period = 60.0 / bpm
    window = int(beat_period / hop_s) + 1
    head = onset[: max(window * 4, 1)]
    offset_idx = int(np.argmax(head)) if len(head) else 0
    offset = offset_idx * hop_s
    return float(round(bpm, 2)), float(round(offset, 3))


def downsample_energy(env: np.ndarray, hop_s: float, out_hop: float) -> list[float]:
    step = max(1, int(round(out_hop / hop_s)))
    sampled = env[::step]
    # Percentile normalize to 0..1 for gameplay mapping
    lo = float(np.percentile(sampled, 5))
    hi = float(np.percentile(sampled, 95))
    span = max(hi - lo, 1e-8)
    norm = np.clip((sampled - lo) / span, 0.0, 1.0)
    return [round(float(x), 3) for x in norm]


def analyze(path: Path) -> dict:
    samples = decode_mono(path)
    duration = len(samples) / SR
    env = rms_envelope(samples, HOP)
    bpm, offset = estimate_bpm(env, HOP)
    energy = downsample_energy(env, HOP, ENERGY_HOP)
    # Compact beat list: first ~N beats as verification, plus bpm/offset for rest
    # Store all beats would be fine for 60s tracks; for long tracks store every beat as float still OK
    # 343s @ 120bpm ≈ 686 beats — fine
    period = 60.0 / bpm
    beats = []
    t = offset
    # Snap: if offset is late in first bar, also allow early
    while t < duration - 0.05:
        beats.append(round(t, 3))
        t += period
        if len(beats) > 2000:
            break
    return {
        "track": path.stem,
        "duration": round(duration, 3),
        "bpm": bpm,
        "beatOffset": offset,
        "energyHop": ENERGY_HOP,
        "energy": energy,
        "beats": beats,
        "feel": "",  # filled by caller / defaults
    }


FEELS = {
    "bgm_01": "Acto 1 — apertura: energía media, fan/straight; densifica en picos.",
    "bgm_02": "Acto 2 — pulso corto y agresivo: scouts rápidos, spiral en beats fuertes.",
    "bgm_03": "Acto 3 — contraste: tramos lentos disparan al beat; estallidos densos.",
    "bgm_04": "Acto 4 — clímax largo: tanks + fan/spiral, spawn alto en crestas.",
}


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    bgm_dir = root / "assets" / "audio" / "bgm"
    out_dir = root / "assets" / "audio" / "analysis"
    out_dir.mkdir(parents=True, exist_ok=True)
    tracks = sorted(bgm_dir.glob("bgm_*.mp3"))
    if not tracks:
        print("No BGM found", file=sys.stderr)
        return 1
    for path in tracks:
        print(f"Analyzing {path.name}...")
        data = analyze(path)
        data["feel"] = FEELS.get(path.stem, "")
        out = out_dir / f"{path.stem}.json"
        out.write_text(json.dumps(data, separators=(",", ":")), encoding="utf-8")
        print(
            f"  -> {out.name}: {data['duration']}s bpm={data['bpm']} "
            f"beats={len(data['beats'])} energy={len(data['energy'])}"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
