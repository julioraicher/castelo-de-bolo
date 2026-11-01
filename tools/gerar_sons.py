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
    combate()
    print("Sons gerados em", os.path.abspath(OUT))


def combate():
    """Sons da Rodada A (bloqueio e poderes). Semente própria: não muda os outros."""
    random.seed(7)
    # Bloqueio: "clang" de metal = parciais inarmônicas (razões de uma placa
    # vibrando, 1 : 2,76 : 5,40) com decaimento exponencial + estalo de ruído.
    total = n(0.4)
    clang = [sum(a * math.sin(2 * math.pi * 520 * r * i / SR) * math.exp(-i / SR * d)
                 for r, a, d in ((1.0, 1.0, 9), (2.76, 0.6, 14), (5.40, 0.35, 22)))
             for i in range(total)]
    save("block", mix(clang, noise(0.04, cutoff=lambda x: 0.9)), 0.8)
    # Poder: whoosh subindo + estrondo grave + acorde maior.
    whoosh = noise(0.45, cutoff=lambda x: 0.03 + 0.5 * x, release_pow=0.7)
    boom = tone(lambda x: 90 - 50 * x, 0.5, release_pow=2.5)
    chord = mix(*(tone(midi(m), 0.6, square, 1.2, vib=0.01) for m in (60, 64, 67, 72)))
    save("power", mix(whoosh, boom, [0.0] * n(0.12) + [x * 0.35 for x in chord]), 0.75)
    # Medidor cheio: arpejo brilhante subindo.
    save("power_ready", seq([midi(m) for m in (79, 83, 86, 91)], 0.06, lambda f, s: tone(f, s, release_pow=1.2)), 0.45)


def sino(f0, sec, parciais=((1.0, 1.0, 3), (2.76, 0.5, 6), (5.4, 0.25, 10), (8.9, 0.12, 16))):
    """Sino/metal: parciais inarmônicas com decaimento exponencial próprio."""
    return [sum(a * math.sin(2 * math.pi * f0 * r * i / SR) * math.exp(-i / SR * d) for r, a, d in parciais)
            for i in range(n(sec))]


def ganho(track, g):
    return [x * g for x in track]


def ao_contrario(track):
    return list(reversed(track))


def efeitos():
    """Sons dos efeitos (docs/direcao-efeitos.md): lançar e acertar por
    projétil, estrondo do poder de Chi, nível da oficina e captura.
    Semente própria: não muda os outros sons. Rode: gerar_sons.py efeitos"""
    random.seed(11)
    # Lançar
    save("lancar_metal", mix(noise(0.13, cutoff=lambda x: 0.5 + 0.4 * x, release_pow=1.5),
                             ganho(sino(2400, 0.13, ((1.0, 1.0, 30), (1.5, 0.4, 40))), 0.25)), 0.45)
    save("pavio", noise(0.3, cutoff=lambda x: 0.85 if random.random() < 0.3 else 0.15, release_pow=1.0), 0.4)
    save("fogo", mix(noise(0.32, cutoff=lambda x: 0.04 + 0.25 * math.sin(math.pi * x), release_pow=1.2),
                     ganho(tone(lambda x: 220 + 180 * x, 0.32, vib=0.05, release_pow=1.5), 0.3)), 0.55)
    save("luz", mix(ganho(sino(1320, 0.4), 0.6), noise(0.2, cutoff=lambda x: 0.05 + 0.4 * x, release_pow=1.0)), 0.45)
    # Sombra: "inspiração" ao contrário (sobe e corta seco), grave.
    save("sombra", ao_contrario(mix(noise(0.35, cutoff=lambda x: 0.06, release_pow=1.5),
                                    ganho(tone(lambda x: 110 - 40 * x, 0.35, release_pow=1.5), 0.8))), 0.55)
    # Acertar
    save("tinido", mix(sino(1800, 0.18, ((1.0, 1.0, 22), (2.4, 0.6, 30), (4.1, 0.3, 40))), noise(0.03, cutoff=lambda x: 0.9)), 0.5)
    save("flecha_chao", mix(tone(lambda x: 180 - 90 * x, 0.1, release_pow=3), noise(0.05, cutoff=lambda x: 0.4)), 0.6)
    save("brasa", mix(noise(0.3, cutoff=lambda x: 0.9 if random.random() < 0.05 else 0.08, release_pow=1.5),
                      ganho(tone(lambda x: 160 - 60 * x, 0.2, release_pow=2.5), 0.6)), 0.55)
    save("sino", mix(sino(880, 0.6), ganho(sino(1320, 0.6), 0.5)), 0.5)
    implode = ao_contrario(noise(0.3, cutoff=lambda x: 0.08 + 0.3 * x, release_pow=2.0))
    save("implosao", implode + ganho(tone(lambda x: 70 - 30 * x, 0.18, release_pow=2.5), 1.2), 0.6)
    # Explosão: ruído grave longo + "tum" descendo + estalos.
    save("explosao", mix(noise(0.8, cutoff=lambda x: 0.12 * (1 - x) + 0.02, release_pow=1.8),
                         ganho(tone(lambda x: 85 - 45 * x, 0.6, release_pow=2.0), 1.3),
                         noise(0.05, cutoff=lambda x: 0.9)), 0.8)
    # Poder de Chi (E): taiko grave + estrondo longo (som "cheio").
    taiko = mix(ganho(tone(lambda x: 65 - 25 * x, 0.9, release_pow=2.2), 1.4), noise(0.12, cutoff=lambda x: 0.25))
    save("poder_boom", mix(taiko, [0.0] * n(0.18) + ganho(taiko, 0.5), noise(1.1, cutoff=lambda x: 0.03, release_pow=1.3)), 0.85)
    # Oficina sobe de nível: três sinos subindo.
    save("nivel", seq([midi(m) for m in (72, 76, 79, 84)], 0.11, lambda f, s: ganho(sino(f, s + 0.3), 1.0)[: n(s)]) + sino(midi(84), 0.6), 0.5)
    # Captura da máscara: gongo grave longo.
    save("captura", mix(sino(110, 2.0, ((1.0, 1.0, 1.2), (2.1, 0.6, 1.8), (3.3, 0.4, 2.5), (4.7, 0.25, 3.5))),
                        ganho(taiko, 0.8)), 0.8)


if __name__ == "__main__":
    import sys
    if sys.argv[1:] == ["efeitos"]:
        efeitos()
    else:
        main()
        efeitos()
