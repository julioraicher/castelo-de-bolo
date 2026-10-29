"""Gera todos os efeitos sonoros e a música do jogo por síntese, sem
nenhum arquivo externo. Rode com:  python3 tools/gerar_sons.py

Técnicas usadas (todas com só a biblioteca padrão do Python):
- osciladores (seno, quadrada) com envelope ADSR simplificado
- ruído branco filtrado (passa-baixa de 1 polo) para "whoosh" e impactos
- Karplus-Strong: um buffer de ruído que é realimentado com média de dois
  vizinhos; modela uma corda dedilhada (alaúde/besta)
"""
import math
import os
import random
import struct
import wave

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")
random.seed(42)


def save(name, samples, gain=0.8):
    peak = max(1e-9, max(abs(s) for s in samples))
    data = b"".join(struct.pack("<h", int(max(-1, min(1, s / peak * gain)) * 32000)) for s in samples)
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data)


def n(sec):
    return int(sec * SR)


def env(i, total, attack=0.005, release_pow=2.0):
    t = i / SR
    a = min(1.0, t / attack) if attack > 0 else 1.0
    return a * (1 - i / total) ** release_pow


def tone(freq, sec, wave_fn=math.sin, release_pow=2.0, vib=0.0):
    total = n(sec)
    out, ph = [], 0.0
    for i in range(total):
        f = freq(i / total) if callable(freq) else freq
        f *= 1 + vib * math.sin(2 * math.pi * 6 * i / SR)
        ph += 2 * math.pi * f / SR
        out.append(wave_fn(ph) * env(i, total, release_pow=release_pow))
    return out


def square(ph):
    return 1.0 if math.sin(ph) >= 0 else -1.0


def noise(sec, cutoff=lambda x: 0.3, release_pow=2.0):
    total = n(sec)
    out, y = [], 0.0
    for i in range(total):
        a = cutoff(i / total)
        y += a * (random.uniform(-1, 1) - y)
        out.append(y * env(i, total, attack=0.01, release_pow=release_pow))
    return out


def pluck(freq, sec, damp=0.996):
    period = max(2, int(SR / freq))
    buf = [random.uniform(-1, 1) for _ in range(period)]
    out = []
    for i in range(n(sec)):
        s = buf[i % period]
        nxt = buf[(i + 1) % period]
        buf[i % period] = damp * 0.5 * (s + nxt)
        out.append(s)
    return out


def mix(*tracks):
    length = max(len(t) for t in tracks)
    out = [0.0] * length
    for t in tracks:
        for i, s in enumerate(t):
            out[i] += s
    return out


def seq(notes, step, fn):
    """Concatena notas (freq ou None) com duração `step` cada."""
    out = []
    for f in notes:
        out += fn(f, step) if f else [0.0] * n(step)
    return out


def midi(m):
    return 440.0 * 2 ** ((m - 69) / 12)


def main():
    os.makedirs(OUT, exist_ok=True)
    save("swing", noise(0.18, cutoff=lambda x: 0.05 + 0.5 * math.sin(math.pi * x)), 0.6)
    save("dodge", noise(0.14, cutoff=lambda x: 0.1 + 0.6 * x), 0.5)
    save("hit", mix(tone(lambda x: 140 - 80 * x, 0.14, release_pow=3), noise(0.06, cutoff=lambda x: 0.8)), 0.9)
    save("shoot", mix(pluck(196, 0.25, 0.99), noise(0.05, cutoff=lambda x: 0.4)), 0.7)
    save("magic", tone(lambda x: 500 + 700 * x, 0.32, vib=0.03, release_pow=1.5), 0.5)
    save("heal", mix(*(tone(midi(m), 0.7, release_pow=1.5) for m in (72, 76, 79, 84))), 0.6)
    save("pickup", seq([midi(76), midi(83)], 0.07, lambda f, s: tone(f, s, square, 1.0)), 0.35)
    save("hat", seq([midi(67), midi(71), midi(74), midi(79)], 0.07, lambda f, s: tone(f, s, square, 1.0)), 0.35)
    save("eat", seq([180, None, 160, None, 200], 0.07, lambda f, s: tone(lambda x: f * (1 + 0.5 * math.sin(30 * x)), s, release_pow=0.6)), 0.7)
    save("death", tone(lambda x: 330 * (1 - 0.6 * x), 0.5, square, 1.5), 0.35)
    fanfare = [72, 72, 72, 77, None, 76, 77]
    save("score", seq([midi(m) if m else None for m in fanfare], 0.12, lambda f, s: mix(tone(f, s, square, 0.8), tone(f / 2, s, release_pow=0.8))), 0.45)
    save("alarm", seq([midi(67), midi(62), midi(67), midi(62)], 0.18, lambda f, s: tone(f, s, square, 0.5)), 0.35)
    save("win", seq([midi(m) for m in (60, 64, 67, 72, 76, 79, 84)], 0.13, lambda f, s: mix(tone(f, s, square, 0.8), tone(f * 1.5, s, release_pow=0.9))), 0.45)
    save("lose", seq([midi(m) for m in (67, 63, 60, 55)], 0.28, lambda f, s: tone(f, s, square, 0.7)), 0.4)

    # Música: alaúde em Ré dórico + baixo, 112 bpm, 16 compassos em loop.
    beat = 60 / 112 / 2  # colcheia
    melody = [62, 65, 69, 67, 65, 64, 62, None, 60, 64, 67, 65, 64, 62, 60, None,
              62, 65, 69, 72, 71, 69, 67, 65, 64, 65, 67, 64, 62, None, 62, None]
    bass = [38, None, 45, None, 36, None, 43, None, 38, None, 45, None, 40, None, 45, None]
    lead = seq([midi(m) if m else None for m in melody * 2], beat, lambda f, s: pluck(f, s, 0.997))
    low = seq([midi(m) if m else None for m in bass * 2], beat * 2, lambda f, s: [x * 0.8 for x in pluck(f, s, 0.998)])
    save("music", mix(lead, low), 0.55)
    print("Sons gerados em", os.path.abspath(OUT))


if __name__ == "__main__":
    main()
