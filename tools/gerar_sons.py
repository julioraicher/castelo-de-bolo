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


def torretas():
    """Sons PROVISÓRIOS da torreta e da catapulta (Ciclo 2.9b). Os nomes são os
    eventos que o jogo chama (Sfx.SOUNDS); a thread de sons troca só o arquivo.
    Timbre pedido: a besta é madeira + cristal encantado na cor do time
    (fogo-fátuo de raposa); a catapulta é bambu que range + mão de Oni de
    pedra; o meteoro de Chi é energia (luz), não bomba.
    Semente própria. Rode: gerar_sons.py torretas"""
    random.seed(29)
    # Besta: corda de madeira solta ("toc" grave) + tinido do cristal.
    save("besta_virote", mix(pluck(130, 0.22, 0.985), noise(0.04, cutoff=lambda x: 0.5),
                             ganho(sino(2100, 0.25, ((1.0, 1.0, 25), (2.5, 0.5, 35))), 0.3)), 0.6)
    # Escudo devolve o virote: tinido agudo subindo.
    save("besta_devolve", mix(sino(1500, 0.3, ((1.0, 1.0, 14), (2.0, 0.6, 20), (3.2, 0.3, 30))),
                              ganho(tone(lambda x: 900 + 700 * x, 0.18, release_pow=1.5), 0.3)), 0.5)
    # Torreta de pé: madeira assentando + sino curto.
    save("torreta_pronta", mix(tone(lambda x: 120 - 40 * x, 0.25, release_pow=2.5),
                               [0.0] * n(0.12) + ganho(sino(1050, 0.5), 0.7)), 0.6)
    # Torreta cai: estalos de madeira + queda grave + poeira.
    estalos = noise(0.5, cutoff=lambda x: 0.9 if random.random() < 0.08 else 0.1, release_pow=1.5)
    save("torreta_cai", mix(estalos, [0.0] * n(0.2) + ganho(tone(lambda x: 75 - 35 * x, 0.5, release_pow=2.0), 1.3),
                            [0.0] * n(0.25) + noise(0.6, cutoff=lambda x: 0.06, release_pow=1.5)), 0.8)
    # Catapulta arma: bambu rangendo (vibrato lento) + corda esticando.
    save("catapulta_arma", mix(tone(lambda x: 90 + 30 * x, 0.7, vib=0.12, release_pow=0.8),
                               noise(0.7, cutoff=lambda x: 0.12 + 0.1 * math.sin(40 * x), release_pow=0.8)), 0.5)
    # Catapulta lança: "tum" do braço batendo + vento subindo.
    save("catapulta_lanca", mix(ganho(tone(lambda x: 70 - 20 * x, 0.3, release_pow=2.5), 1.3),
                                noise(0.06, cutoff=lambda x: 0.7),
                                [0.0] * n(0.08) + noise(0.6, cutoff=lambda x: 0.08 + 0.5 * x, release_pow=1.0)), 0.7)
    # Meteoro de Chi: assobio caindo + estrondo de energia (sino grave, não bomba).
    assobio = tone(lambda x: 1400 - 1100 * x, 0.55, release_pow=0.6)
    bum = mix(ganho(tone(lambda x: 60 - 20 * x, 0.6, release_pow=2.0), 1.2),
              sino(220, 0.8, ((1.0, 1.0, 2.5), (2.0, 0.5, 4), (3.1, 0.3, 6))),
              noise(0.3, cutoff=lambda x: 0.1, release_pow=1.5))
    save("catapulta_meteoro", ganho(assobio, 0.5) + bum, 0.8)


def membrana(f0, sec, queda=0.35):
    """Taiko: modos de uma membrana circular (zeros de Bessel: 1, 1,59, 2,14,
    2,30, 2,65) com o tom caindo um pouco no ataque (a pele relaxa)."""
    modos = ((1.0, 1.0, 6), (1.594, 0.5, 9), (2.136, 0.3, 12), (2.296, 0.25, 14), (2.653, 0.15, 18))
    out = []
    for i in range(n(sec)):
        t = i / SR
        f = f0 * (1 + queda * math.exp(-t * 30))
        out.append(sum(a * math.sin(2 * math.pi * f * r * t) * math.exp(-t * d) for r, a, d in modos))
    return mix(out, noise(0.04, cutoff=lambda x: 0.6))


def tigela(f0, sec):
    """Rin (tigela de templo): parciais 1; 2,71; 5,15; 8,4 e cada uma em par
    levemente desafinado, o que dá o batimento ("uáu-uáu") típico."""
    parc = []
    for r, a, d in ((1.0, 1.0, 1.2), (2.71, 0.6, 2.0), (5.15, 0.3, 3.5), (8.4, 0.15, 6.0)):
        parc += [(r, a, d), (r * 1.004, a * 0.8, d)]
    return sino(f0, sec, tuple(parc))


def guizos(sec, densidade=40, f_min=3500, f_max=6500):
    """Kagura suzu: muitos sininhos pequenos batendo em tempos aleatórios."""
    out = [0.0] * n(sec)
    for _ in range(int(densidade * sec)):
        t0 = n(random.uniform(0, sec * 0.85))
        b = suave(sino(random.uniform(f_min, f_max), 0.12, ((1.0, 1.0, 35), (2.3, 0.4, 50))), 0.002)
        for j, v in enumerate(b):
            if t0 + j < len(out):
                out[t0 + j] += v * random.uniform(0.15, 0.4) * (1 - t0 / len(out))
    return out


def coro(notas, sec, vogal=(700, 1150), ataque=0.25):
    """Coro "ah" baixo: série harmônica pesada por duas ressonâncias (formantes
    F1 e F2 da vogal A). Três vozes levemente desafinadas por nota."""
    out = [0.0] * n(sec)
    for f0 in notas:
        for det in (0.996, 1.0, 1.005):
            f = f0 * det
            hs = [(h, math.exp(-((h * f - vogal[0]) / 250) ** 2) + 0.6 * math.exp(-((h * f - vogal[1]) / 300) ** 2) + 0.05)
                  for h in range(1, int(3000 / f))]
            for i in range(len(out)):
                t = i / SR
                e = min(1.0, t / ataque) * (1 - i / len(out)) ** 1.5
                out[i] += e * sum(a * math.sin(2 * math.pi * f * h * t + h) for h, a in hs[:12]) / 12
    return out


def sopro(f0, sec, curva=-0.08):
    """Shakuhachi: seno com vibrato e muito ar (ruído) em volta, caindo de leve."""
    tom = tone(lambda x: f0 * (1 + curva * x), sec, vib=0.012, release_pow=1.2)
    ar = noise(sec, cutoff=lambda x: 0.25, release_pow=1.2)
    return mix(ganho(tom, 0.6), ganho(ar, 0.5))


def suave(track, ataque=0.006):
    """Rampa de ataque curta: sino que começa seco vira um clique de banda larga."""
    k = max(1, n(ataque))
    return [v * min(1.0, i / k) for i, v in enumerate(track)]


def atraso(track, seg):
    return [0.0] * n(seg) + track


def elementos():
    """Assinatura sonora por classe (sons/direcao-sonora.md): o som segue o
    elemento, não o evento. Usados por ClassStats.som_poder/som_super/
    som_golpe_final. Semente própria. Rode: gerar_sons.py elementos"""
    random.seed(53)

    def save(name, track, gain=0.8):  # cauda suave: nada de corte seco no fim
        k = len(track)
        ini = int(k * 0.7)
        globals()["save"](name, [v * (1.0 if i < ini else (1 - (i - ini) / (k - ini)) ** 2) for i, v in enumerate(track)], gain)
    aco = lambda f, s: sino(f, s, ((1.0, 1.0, 9), (2.41, 0.6, 12), (3.9, 0.4, 16), (6.3, 0.2, 22)))
    corte = noise(0.18, cutoff=lambda x: 0.15 + 0.8 * x, release_pow=1.5)
    # Samurai: aço + taiko.
    save("samurai_final", mix(ganho(membrana(75, 0.7), 1.4), corte, atraso(ganho(aco(1900, 0.68), 0.35), 0.02)), 0.85)
    giro = noise(1.1, cutoff=lambda x: 0.06 + 0.12 * (0.5 + 0.5 * math.sin(2 * math.pi * 7 * x)), release_pow=0.8)
    save("samurai_poder", mix(giro, ganho(aco(1500, 1.0), 0.3), ganho(membrana(70, 0.6), 0.9)), 0.75)
    batida = lambda: membrana(48, 0.25, 0.1)
    coracao = mix(atraso(batida(), 0.35), atraso(ganho(batida(), 0.7), 0.6))
    save("sombra_entra", mix(ganho(sopro(560, 1.2, -0.2), 1.3), ganho(ao_contrario(noise(0.5, cutoff=lambda x: 0.1)), 0.6), coracao), 0.65)
    save("sombra_sai", ao_contrario(noise(0.3, cutoff=lambda x: 0.05 + 0.3 * x, release_pow=2.0)) + mix(corte, ganho(aco(2100, 0.4), 0.3)), 0.6)
    # Ninja: metal fino (assobios e tinidos).
    assobio = lambda: tone(lambda x: 2600 - 900 * x, 0.25, release_pow=1.0)
    rajada = mix(*(atraso(ganho(assobio(), 0.4), k * 0.045) for k in range(7)))
    tin = lambda f: sino(f, 0.25, ((1.0, 1.0, 20), (2.4, 0.6, 28), (4.1, 0.3, 38)))
    save("ninja_poder", mix(rajada, noise(0.5, cutoff=lambda x: 0.1 + 0.5 * x, release_pow=1.2),
                            atraso(ganho(tin(1700), 0.5), 0.3), atraso(ganho(tin(2100), 0.4), 0.38)), 0.7)
    save("ninja_final", mix(*(atraso(ganho(tin(f), 0.6), k * 0.06) for k, f in enumerate((1500, 1800, 2200)))), 0.6)
    # Kitsune: fogo azul subindo + rin + guizos + coro baixo.
    chama = noise(1.4, cutoff=lambda x: 0.03 + 0.25 * x * (1 - x) * 4 * 0.5, release_pow=1.0)
    save("kitsune_poder", mix(ganho(chama, 1.0), ganho(tigela(392, 2.0), 0.6), guizos(1.0, 30),
                              atraso(ganho(coro((196, 293.7), 1.3), 0.5), 0.1)), 0.8)
    uivo = tone(lambda x: 380 + 300 * math.sin(math.pi * x) - 80 * x, 1.4, vib=0.02, release_pow=1.0)
    save("kitsune_super", mix(ganho(uivo, 0.35), *(atraso(ganho(tigela(f, 2.2), 0.45), k * 0.12) for k, f in enumerate((220, 261.6, 329.6))),
                              guizos(1.4, 55), ganho(coro((110, 164.8), 2.0, ataque=0.4), 0.6)), 0.85)
    brilho = mix(*(atraso(ganho(suave(sino(random.uniform(2500, 5000), 0.3, ((1.0, 1.0, 12),))), 0.25), random.uniform(0, 0.9)) for _ in range(24)))
    save("luz_poder", mix(brilho, ganho(coro((261.6, 329.6, 392), 1.4), 0.7), ganho(tigela(523, 1.6), 0.5)), 0.75)
    succao = ao_contrario(noise(0.6, cutoff=lambda x: 0.04 + 0.4 * x, release_pow=2.5))
    sussurro = [v * (0.5 + 0.5 * math.sin(2 * math.pi * 9 * i / SR)) for i, v in enumerate(noise(0.9, cutoff=lambda x: 0.7, release_pow=1.0))]
    save("sombra_poder", mix(succao + ganho(membrana(40, 0.7, 0.2), 1.5), ganho(sussurro, 0.12)), 0.8)
    # Construtor: marteladas em ritmo (madeira).
    madeira = lambda f: mix(tone(lambda x: f * (1 - 0.3 * x), 0.09, release_pow=4), noise(0.03, cutoff=lambda x: 0.5))
    save("mutirao", mix(*(atraso(madeira(f), t) for t, f in ((0, 420), (0.16, 380), (0.32, 450), (0.4, 400), (0.56, 430)))), 0.7)
    # Super genérico (classes sem assinatura própria): dois taikos + brilho subindo + gongo.
    save("super_maior", mix(ganho(membrana(60, 0.9), 1.3), atraso(ganho(membrana(55, 0.9), 1.0), 0.22),
                            noise(0.8, cutoff=lambda x: 0.02 + 0.3 * x, release_pow=0.6),
                            atraso(sino(98, 1.8, ((1.0, 1.0, 1.5), (2.1, 0.6, 2.2), (3.3, 0.4, 3.0))), 0.25)), 0.85)
    # Golpe pelas costas (crítico): estalo seco + aço agudo curto, distinto do 3º golpe.
    save("corte_critico", mix(noise(0.08, cutoff=lambda x: 0.9 - 0.5 * x, release_pow=2.0),
                              ganho(suave(aco(2800, 0.35), 0.002), 0.5), ganho(membrana(140, 0.15, 0.2), 0.6)), 0.7)
    # Renascer: sininho de templo + ar subindo (suave, toca muito).
    save("renascer", mix(ganho(tigela(784, 0.9), 0.5), noise(0.4, cutoff=lambda x: 0.05 + 0.3 * x, release_pow=0.8)), 0.4)


def magia():
    """Camada sonora do kit de magia (Ciclo 2.20): um som curto por elemento que
    toca junto do som próprio da classe quando o poder sai. Semente própria.
    Rode: gerar_sons.py magia"""
    random.seed(20)
    # Selo: pincelada (ruído que abre e fecha) + nota grave que sobe e corta.
    pincel = noise(0.34, cutoff=lambda x: 0.05 + 0.5 * math.sin(math.pi * x) ** 2, release_pow=1.0)
    save("magia_selo", mix(pincel, ganho(ao_contrario(tone(lambda x: 150 - 70 * x, 0.34, release_pow=1.6)), 0.7),
                           [0.0] * n(0.3) + ganho(tigela(660, 0.5), 0.35)), 0.5)
    # Fogo: rugido (ruído grave que incha) + estalos de brasa.
    rugido = noise(0.7, cutoff=lambda x: 0.03 + 0.22 * math.sin(math.pi * min(1.0, x * 1.6)), release_pow=1.3)
    estalos = noise(0.7, cutoff=lambda x: 0.9 if random.random() < 0.04 else 0.02, release_pow=1.2)
    save("magia_fogo", mix(rugido, ganho(estalos, 0.5), ganho(tone(lambda x: 95 + 60 * x, 0.5, vib=0.08, release_pow=1.6), 0.5)), 0.6)
    # Vento: sopro que gira (dois ruídos com o filtro oscilando fora de fase).
    v1 = noise(0.6, cutoff=lambda x: 0.12 + 0.3 * abs(math.sin(9 * x)), release_pow=1.2)
    v2 = noise(0.6, cutoff=lambda x: 0.1 + 0.25 * abs(math.cos(7 * x)), release_pow=1.4)
    save("magia_vento", mix(v1, ganho(v2, 0.7), ganho(sopro(520, 0.5), 0.25)), 0.5)
    # Luz: tigela de templo + guizos subindo.
    save("magia_luz", mix(tigela(880, 0.8), ganho(guizos(0.5), 0.3), ganho(sino(1760, 0.5), 0.25)), 0.45)
    # Estouro: clarão seco (estalo) + corpo grave curto + cauda de ar.
    save("magia_estouro", mix(noise(0.04, cutoff=lambda x: 0.95), ganho(tone(lambda x: 120 - 75 * x, 0.35, release_pow=2.2), 1.2),
                              noise(0.5, cutoff=lambda x: 0.2 * (1 - x) + 0.02, release_pow=1.6)), 0.7)


def assinaturas_2():
    """Assinatura sonora das classes que estavam no som genérico (auditoria
    2026-11-12): 8 heróis raros, Armadilheiro, Yumi, Bombardeiro, Ronin Oni, Sohei e Kusarigama.
    Cada uma ganha <id>_poder, <id>_super e <id>_final (ClassStats.som_*).
    O som segue o elemento (sons/direcao-sonora.md). Semente própria.
    Rode: gerar_sons.py assinaturas2"""
    random.seed(212)

    def save(name, track, gain=0.8):
        k = len(track)
        ini = int(k * 0.7)
        globals()["save"](name, [v * (1.0 if i < ini else (1 - (i - ini) / (k - ini)) ** 2) for i, v in enumerate(track)], gain)

    def super_de(poder, extra=()):
        # Super = a assinatura do poder por cima de dois taikos e um gongo grave.
        base = mix(ganho(membrana(58, 0.9), 1.1), atraso(ganho(membrana(52, 0.9), 0.8), 0.24),
                   atraso(ganho(sino(98, 1.6, ((1.0, 1.0, 1.6), (2.1, 0.6, 2.3), (3.3, 0.4, 3.2))), 0.6), 0.3))
        return mix(base, atraso(ganho(poder, 1.1), 0.12), *extra)

    aco = lambda f, s: sino(f, s, ((1.0, 1.0, 9), (2.41, 0.6, 12), (3.9, 0.4, 16), (6.3, 0.2, 22)))
    tin = lambda f: sino(f, 0.25, ((1.0, 1.0, 20), (2.4, 0.6, 28), (4.1, 0.3, 38)))
    estalos = lambda sec, p=0.06: noise(sec, cutoff=lambda x: 0.9 if random.random() < p else 0.04, release_pow=1.2)
    whoosh = lambda sec, pico=0.5: noise(sec, cutoff=lambda x: 0.04 + pico * math.sin(math.pi * x) ** 2, release_pow=1.0)

    # Armadilheiro: catraca e mola de metal; a armadilha fecha com estalo seco.
    catraca = mix(*(atraso(ganho(suave(sino(3200 + 150 * k, 0.05, ((1.0, 1.0, 60), (2.2, 0.5, 80))), 0.001), 0.5), k * 0.05) for k in range(8)))
    mola = tone(lambda x: 240 + 160 * math.sin(40 * x) * (1 - x), 0.5, vib=0.0, release_pow=1.6)
    p = mix(catraca, atraso(ganho(mola, 0.45), 0.38), atraso(ganho(aco(900, 0.6), 0.45), 0.4), atraso(estalos(0.4), 0.42))
    save("armadilheiro_poder", p, 0.7)
    save("armadilheiro_super", super_de(p, (atraso(ganho(catraca, 0.6), 0.6),)), 0.85)
    save("armadilheiro_final", mix(noise(0.05, cutoff=lambda x: 0.95), ganho(aco(1200, 0.35), 0.6), ganho(membrana(160, 0.2, 0.2), 0.8)), 0.7)

    # Yumi: corda de arco longa (grave) e a chuva de flechas assobiando.
    corda = mix(pluck(98, 0.6, 0.994), ganho(pluck(147, 0.5, 0.993), 0.5), noise(0.03, cutoff=lambda x: 0.6))
    flechas = mix(*(atraso(ganho(tone(lambda x, f=random.uniform(1700, 2600): f - 1100 * x, 0.35, release_pow=0.9), 0.25), random.uniform(0.25, 0.75)) for _ in range(9)))
    p = mix(corda, flechas, atraso(estalos(0.5, 0.08), 0.7))
    save("arqueiro_yumi_poder", p, 0.7)
    save("arqueiro_yumi_super", super_de(p, (atraso(ganho(flechas, 0.8), 0.45),)), 0.85)
    save("arqueiro_yumi_final", mix(corda, atraso(ganho(tin(2000), 0.35), 0.05)), 0.7)

    # Bombardeiro: pavios chiando e estouros em cascata.
    pavio = noise(0.45, cutoff=lambda x: 0.85 if random.random() < 0.35 else 0.2, release_pow=0.6)
    estouro = lambda: mix(noise(0.03, cutoff=lambda x: 0.95), ganho(tone(lambda x: 110 - 70 * x, 0.35, release_pow=2.2), 1.2),
                          noise(0.4, cutoff=lambda x: 0.15 * (1 - x) + 0.02, release_pow=1.8))
    p = mix(ganho(pavio, 0.6), *(atraso(ganho(estouro(), 0.9 - 0.15 * k), 0.4 + 0.17 * k) for k in range(4)))
    save("bombardeiro_poder", p, 0.8)
    save("bombardeiro_super", super_de(p, (atraso(ganho(estouro(), 1.2), 1.1),)), 0.9)
    save("bombardeiro_final", mix(ganho(noise(0.15, cutoff=lambda x: 0.8 if random.random() < 0.4 else 0.2), 0.5), atraso(estouro(), 0.12)), 0.75)

    # Ronin Oni: rosnado grave (dente de serra com tremor) + ferro pesado.
    def rosnado(sec, f0=70):
        out, ph = [], 0.0
        for i in range(n(sec)):
            x = i / n(sec)
            f = f0 * (1 + 0.25 * math.sin(math.pi * x)) * (1 + 0.06 * math.sin(2 * math.pi * 23 * i / SR))
            ph += f / SR
            out.append(((ph % 1.0) * 2 - 1) * min(1.0, x * 6) * (1 - x) ** 1.2)
        return mix(ganho(noise(sec, cutoff=lambda x: 0.05, release_pow=1.2), 0.8), [v * 0.6 for v in out])
    p = mix(rosnado(1.0), ganho(membrana(50, 0.8, 0.3), 1.4), atraso(ganho(aco(600, 0.7), 0.35), 0.15))
    save("ronin_oni_poder", p, 0.8)
    save("ronin_oni_super", super_de(p, (atraso(rosnado(1.3, 55), 0.4),)), 0.9)
    save("ronin_oni_final", mix(ganho(membrana(62, 0.6, 0.4), 1.5), noise(0.12, cutoff=lambda x: 0.6 - 0.5 * x, release_pow=2.0), ganho(aco(800, 0.5), 0.4)), 0.85)

    # Sumotori: pisão shiko que treme o chão + punhado de sal.
    sal = noise(0.6, cutoff=lambda x: 0.95 if random.random() < 0.25 else 0.5, release_pow=1.5)
    pisao = mix(ganho(membrana(38, 1.0, 0.5), 1.6), noise(0.9, cutoff=lambda x: 0.025, release_pow=1.3))
    p = mix(ganho(sal, 0.25), atraso(pisao, 0.2))
    save("sumotori_poder", p, 0.85)
    save("sumotori_super", super_de(p, (atraso(ganho(pisao, 0.9), 0.75),)), 0.9)
    save("sumotori_final", mix(noise(0.04, cutoff=lambda x: 0.9), ganho(membrana(90, 0.35, 0.3), 1.3)), 0.8)

    # Kappa: jato d'água (chiado sustentado que borbulha) + respingo.
    def bolhas(sec, k=10):
        out = [0.0] * n(sec)
        for _ in range(k):
            t0, f0, d = n(random.uniform(0, sec * 0.8)), random.uniform(450, 1100), random.uniform(0.03, 0.07)
            for j in range(n(d)):
                tt = j / SR
                if t0 + j < len(out):
                    out[t0 + j] += 0.4 * math.sin(2 * math.pi * (f0 * tt + 3 * f0 * tt * tt)) * math.exp(-tt * 40)
        return out
    jato = noise(0.8, cutoff=lambda x: 0.45 + 0.2 * math.sin(30 * x), release_pow=0.7)
    respingo = mix(noise(0.4, cutoff=lambda x: 0.6 * (1 - x) + 0.05, release_pow=1.6), bolhas(0.4, 6))
    p = mix(ganho(jato, 0.6), bolhas(0.8, 12), atraso(respingo, 0.5))
    save("kappa_poder", p, 0.7)
    onda = noise(1.6, cutoff=lambda x: 0.02 + 0.15 * math.sin(math.pi * x), release_pow=0.8)
    save("kappa_super", super_de(p, (onda, atraso(bolhas(1.2, 18), 0.3))), 0.85)
    save("kappa_final", respingo, 0.7)

    # Yamabushi: horagai (trompa de concha) + vento que gira.
    def horagai(f0, sec):
        out, ph = [], 0.0
        for i in range(n(sec)):
            x = i / n(sec)
            ph += f0 * (1 + 0.04 * x) * (1 + 0.006 * math.sin(2 * math.pi * 5 * i / SR)) / SR
            s = sum(math.sin(2 * math.pi * h * ph) / h * (1.5 if h in (3, 4) else 1.0) for h in range(1, 7))
            out.append(s * min(1.0, x * 5) * (1 - x) ** 0.8)
        return out
    giro = noise(1.0, cutoff=lambda x: 0.08 + 0.3 * abs(math.sin(10 * x)), release_pow=1.0)
    p = mix(ganho(horagai(147, 0.9), 0.4), giro)
    save("yamabushi_poder", p, 0.7)
    save("yamabushi_super", super_de(p, (atraso(ganho(horagai(110, 1.4), 0.5), 0.2), noise(1.6, cutoff=lambda x: 0.05 + 0.35 * abs(math.sin(14 * x)), release_pow=0.9))), 0.85)
    save("yamabushi_final", whoosh(0.3, 0.7), 0.6)

    # Karasu Tengu: bater de asas (rajadas de ar) + crocito grave.
    asa = lambda: noise(0.12, cutoff=lambda x: 0.05 + 0.35 * math.sin(math.pi * x), release_pow=1.5)
    asas = lambda k, passo=0.11: mix(*(atraso(ganho(asa(), random.uniform(0.6, 1.0)), j * passo + random.uniform(0, 0.03)) for j in range(k)))
    crocito = mix(*(atraso(ganho(tone(lambda x: 520 - 120 * x, 0.18, square, 1.2), 0.15), t) for t in (0.0, 0.24)))
    p = mix(asas(7), atraso(crocito, 0.25))
    save("karasu_tengu_poder", p, 0.7)
    save("karasu_tengu_super", super_de(p, (atraso(asas(14, 0.07), 0.3),)), 0.85)
    save("karasu_tengu_final", mix(asa(), atraso(noise(0.1, cutoff=lambda x: 0.2 + 0.7 * x, release_pow=1.5), 0.05)), 0.65)

    # Onmyoji de Papel: papel dobrando (estalinhos) + talismã + sininho.
    papel = lambda sec: noise(sec, cutoff=lambda x: 0.95 if random.random() < 0.12 else 0.3, release_pow=1.4)
    p = mix(ganho(papel(0.5), 0.5), atraso(whoosh(0.5, 0.35), 0.2), atraso(ganho(tigela(1046, 0.8), 0.35), 0.3))
    save("onmyoji_poder", p, 0.65)
    voo = mix(*(atraso(ganho(papel(0.25), 0.3), random.uniform(0, 1.1)) for _ in range(14)))
    save("onmyoji_super", super_de(p, (voo, atraso(ganho(coro((261.6, 392), 1.3), 0.4), 0.3))), 0.85)
    save("onmyoji_final", mix(noise(0.04, cutoff=lambda x: 0.8), atraso(ganho(tin(2600), 0.35), 0.02)), 0.6)

    # Komusō: shakuhachi que oscila (hipnose) + tigela.
    p = mix(ganho(sopro(440, 1.1, -0.06), 1.1), atraso(ganho(tigela(220, 1.4), 0.4), 0.2))
    save("komuso_poder", p, 0.65)
    save("komuso_super", super_de(p, (atraso(ganho(sopro(293.7, 1.6, -0.1), 0.9), 0.3), ganho(coro((110, 146.8), 1.8, ataque=0.5), 0.5))), 0.85)
    save("komuso_final", ganho(sopro(587, 0.28, 0.08), 1.0), 0.55)

    # Mujina: ar puxado ao contrário + estalo dissonante (o rosto liso assusta).
    susto = mix(*(ganho(tone(f, 0.35, square, 2.0), 0.15) for f in (622, 659, 880)))
    p = ao_contrario(noise(0.5, cutoff=lambda x: 0.05 + 0.4 * x, release_pow=2.5)) + mix(susto, noise(0.05, cutoff=lambda x: 0.9))
    save("mujina_poder", p, 0.65)
    drone = tone(lambda x: 55 + 10 * math.sin(3 * x), 1.6, vib=0.03, release_pow=1.0)
    save("mujina_super", super_de(p, (ganho(drone, 0.5), atraso(ganho(ao_contrario(noise(0.8, cutoff=lambda x: 0.06)), 0.6), 0.5))), 0.85)
    save("mujina_final", mix(noise(0.08, cutoff=lambda x: 0.9 - 0.6 * x, release_pow=2.0), ganho(susto[: n(0.15)], 0.8)), 0.6)

    # Tennin do Manto: manto que esvoaça + harpa subindo + coro agudo.
    harpa = lambda notas, passo: mix(*(atraso(ganho(pluck(midi(m), 0.6, 0.997), 0.5), k * passo) for k, m in enumerate(notas)))
    p = mix(whoosh(0.7, 0.25), harpa((72, 76, 79, 84), 0.08), atraso(ganho(coro((523, 659), 0.9), 0.35), 0.15), ganho(guizos(0.6, 25), 0.6))
    save("tennin_poder", p, 0.65)
    save("tennin_super", super_de(p, (atraso(harpa((60, 64, 67, 72, 76, 79, 84, 88), 0.06), 0.3), ganho(coro((392, 523, 659), 1.6, ataque=0.4), 0.45))), 0.85)
    save("tennin_final", mix(harpa((79, 84), 0.05), ganho(guizos(0.3, 30), 0.6)), 0.55)

    # Sohei: sino grande do templo + naginata cortando o ar (Muralha de Fé).
    p = mix(ganho(sino(196, 1.4, ((1.0, 1.0, 1.8), (2.0, 0.5, 2.6), (2.76, 0.4, 3.5), (5.4, 0.2, 6))), 0.8),
            whoosh(0.35, 0.6), atraso(ganho(membrana(70, 0.5), 0.9), 0.05))
    save("sohei_poder", p, 0.75)
    save("sohei_super", super_de(p, (atraso(ganho(sino(147, 1.6, ((1.0, 1.0, 1.4), (2.0, 0.5, 2.2), (2.76, 0.4, 3.0))), 0.7), 0.5),
                                     atraso(ganho(sino(147, 1.2, ((1.0, 1.0, 1.4), (2.76, 0.4, 3.0))), 0.5), 0.9))), 0.85)
    save("sohei_final", mix(whoosh(0.25, 0.7), atraso(ganho(aco(1400, 0.5), 0.5), 0.12), atraso(ganho(membrana(85, 0.3), 0.8), 0.12)), 0.7)

    # Kusarigama: corrente chacoalhando (elos de metal) + foice que assobia.
    elos = lambda sec, k: mix(*(atraso(ganho(suave(sino(random.uniform(2200, 3600), 0.06, ((1.0, 1.0, 50), (2.7, 0.5, 70))), 0.001),
                                             random.uniform(0.2, 0.45)), random.uniform(0, sec * 0.9)) for _ in range(k)))
    foice = tone(lambda x: 1500 + 600 * math.sin(2 * math.pi * 3 * x), 0.7, release_pow=1.2)
    p = mix(elos(0.8, 26), ganho(foice, 0.18), noise(0.7, cutoff=lambda x: 0.08 + 0.3 * abs(math.sin(9 * x)), release_pow=1.0))
    save("kusarigama_poder", p, 0.65)
    save("kusarigama_super", super_de(p, (atraso(elos(1.2, 40), 0.3),)), 0.85)
    save("kusarigama_final", mix(elos(0.25, 10), atraso(ganho(tin(1900), 0.5), 0.1)), 0.6)

    # 3º tiro das Kitsunes (bola que explode): fogo-raposa estalando + tigela.
    chama = lambda: noise(0.4, cutoff=lambda x: 0.05 + 0.3 * math.sin(math.pi * x), release_pow=1.3)
    save("kitsune_final", mix(chama(), ganho(tigela(523, 0.6), 0.4), estalos(0.3, 0.1)), 0.6)
    save("kitsune_luz_final", mix(chama(), ganho(tigela(784, 0.7), 0.5), ganho(guizos(0.4, 30), 0.5)), 0.6)
    save("kitsune_sombria_final", mix(ao_contrario(chama()), ganho(membrana(55, 0.4, 0.2), 1.0), ganho(tigela(311, 0.6), 0.35)), 0.65)


def herois_2_27():
    """Heróis 2.27 (Ochimusha, Shishimai, Jorogumo): <id>_poder/_super/_final e
    os sons próprios dos poderes. Semente própria: não muda os outros.
    Rode: gerar_sons.py herois227"""
    random.seed(227)

    def save(name, track, gain=0.8):
        k = len(track)
        ini = int(k * 0.7)
        globals()["save"](name, [v * (1.0 if i < ini else (1 - (i - ini) / (k - ini)) ** 2) for i, v in enumerate(track)], gain)

    def super_de(poder, extra=()):
        base = mix(ganho(membrana(58, 0.9), 1.1), atraso(ganho(membrana(52, 0.9), 0.8), 0.24),
                   atraso(ganho(sino(98, 1.6, ((1.0, 1.0, 1.6), (2.1, 0.6, 2.3), (3.3, 0.4, 3.2))), 0.6), 0.3))
        return mix(base, atraso(ganho(poder, 1.1), 0.12), *extra)

    whoosh = lambda sec, pico=0.5: noise(sec, cutoff=lambda x: 0.04 + pico * math.sin(math.pi * x) ** 2, release_pow=1.0)
    aco = lambda f, s: sino(f, s, ((1.0, 1.0, 9), (2.41, 0.6, 12), (3.9, 0.4, 16), (6.3, 0.2, 22)))
    # Madeira: modos de uma barra livre-livre (1; 2,76; 5,40) com amortecimento alto.
    madeira = lambda f: suave(sino(f, 0.12, ((1.0, 1.0, 45), (2.76, 0.45, 70), (5.4, 0.2, 95))), 0.0015)
    koto = lambda f, sec=0.6: pluck(f, sec, 0.996)

    # Ochimusha: fantasma = ar puxado ao contrário + coro grave desafinado
    # (batimento de 6,5 Hz entre 110 e 116,5 Hz: o "tremor" de alma penada).
    fantasma = mix(ao_contrario(noise(0.6, cutoff=lambda x: 0.05 + 0.35 * x, release_pow=2.2)),
                   atraso(ganho(coro((110, 116.5), 1.0, ataque=0.15), 0.55), 0.45))
    save("ochimusha_fantasma", fantasma, 0.7)
    # Flecha arrancada: rasgo (ruído largo curto) + corda grave + assobio caindo (Doppler).
    rasgo = noise(0.07, cutoff=lambda x: 0.9 - 0.5 * x, release_pow=1.5)
    assobio = tone(lambda x: 2300 - 1100 * x, 0.32, release_pow=1.0)
    save("ochimusha_flecha", mix(rasgo, ganho(pluck(165, 0.35, 0.992), 0.7), atraso(ganho(assobio, 0.22), 0.03)), 0.7)
    chama = noise(0.6, cutoff=lambda x: 0.05 + 0.25 * math.sin(math.pi * x), release_pow=1.2)
    onibi = mix(chama, ganho(tigela(370, 0.9), 0.3), ganho(tigela(392, 0.9), 0.2))  # 22 Hz de batimento: chama azul tremida
    save("ochimusha_onibi", onibi, 0.65)
    passos = mix(*(atraso(ganho(membrana(64 + random.uniform(-6, 6), 0.25, 0.25), random.uniform(0.55, 0.9)), 0.13 * k + random.uniform(0, 0.03)) for k in range(10)))
    grito = ganho(coro((98, 147, 196), 1.2, vogal=(600, 1000), ataque=0.3), 0.5)
    caidos = mix(passos, atraso(grito, 0.1), atraso(whoosh(1.0, 0.3), 0.2))
    save("ochimusha_caidos", caidos, 0.8)
    save("ochimusha_poder", mix(onibi, atraso(ganho(fantasma, 0.5), 0.05)), 0.7)
    save("ochimusha_super", super_de(caidos, (atraso(ganho(fantasma, 0.7), 0.0),)), 0.85)
    eco = mix(ganho(aco(1100, 0.4), 0.6), atraso(ganho(ao_contrario(aco(1100, 0.3)), 0.35), 0.25))
    save("ochimusha_final", mix(whoosh(0.22, 0.75), atraso(eco, 0.08)), 0.7)

    # Shishimai: a boca de madeira estala (kachi-kachi), suzu, taiko e o fue da festa.
    estalo = mix(madeira(820), atraso(ganho(madeira(1180), 0.7), 0.055))
    save("shishimai_mordida", mix(estalo, atraso(ganho(guizos(0.25, 30), 0.4), 0.03)), 0.75)
    save("shishimai_sino", ganho(guizos(0.35, 45), 1.0), 0.6)
    save("shishimai_taiko", mix(ganho(membrana(92, 0.45), 1.1), noise(0.02, cutoff=lambda x: 0.6)), 0.8)
    ritmo = mix(*(atraso(ganho(membrana(92 if k % 2 == 0 else 120, 0.35), 1.0 if k % 4 == 0 else 0.6), 0.16 * k) for k in range(8)))
    fue = mix(*(atraso(ganho(sopro(midi(m), 0.22, 0.02), 0.5), 0.14 * k) for k, m in enumerate((79, 81, 84, 81, 79, 76, 79))))
    festa = mix(ritmo, atraso(fue, 0.1), ganho(guizos(1.2, 35), 0.45), atraso(estalo, 0.0), atraso(estalo, 0.64))
    save("shishimai_festa", festa, 0.8)
    save("shishimai_poder", mix(estalo, whoosh(0.55, 0.55), ganho(guizos(0.5, 30), 0.5)), 0.7)
    save("shishimai_super", super_de(festa), 0.85)
    save("shishimai_final", mix(estalo, atraso(ganho(membrana(110, 0.3), 0.8), 0.06), ganho(guizos(0.3, 30), 0.5)), 0.7)

    # Jorogumo: seda é ruído agudo e fino (fio vibrando no ar) + cordas de koto tensas.
    seda = mix(noise(0.22, cutoff=lambda x: 0.75 - 0.4 * x, release_pow=1.6), ganho(tone(lambda x: 1900 + 500 * x, 0.18, release_pow=1.4), 0.12))
    save("seda", seda, 0.5)
    gruda = mix(noise(0.09, cutoff=lambda x: 0.25 - 0.2 * x, release_pow=2.0), ganho(tone(lambda x: 420 - 260 * x, 0.14, release_pow=1.8), 0.35))
    save("seda_gruda", gruda, 0.6)
    teia = mix(*(atraso(ganho(koto(midi(m), 0.5), 0.45), 0.05 * k) for k, m in enumerate((81, 76, 84))))
    save("jorogumo_teia", mix(seda, atraso(teia, 0.12), atraso(gruda, 0.2)), 0.65)
    # Puxar os fios: as cordas esticam (Karplus-Strong com afinação subindo a cada puxão).
    fios = mix(*(atraso(ganho(koto(midi(57 + 5 * k), 0.4), 0.55), 0.07 * k) for k in range(4)), atraso(whoosh(0.4, 0.6), 0.1))
    save("jorogumo_fios", fios, 0.7)
    enrola = noise(0.7, cutoff=lambda x: 0.1 + 0.6 * abs(math.sin(22 * x)) * x, release_pow=0.8)
    casulo = mix(enrola, atraso(ganho(membrana(75, 0.3, 0.2), 0.8), 0.62), atraso(ganho(gruda, 0.8), 0.62))
    save("jorogumo_casulo", casulo, 0.75)
    save("jorogumo_poder", fios, 0.7)
    arpejo = mix(*(atraso(ganho(koto(midi(m), 0.7), 0.4), 0.07 * k) for k, m in enumerate((57, 60, 64, 69, 72, 76))))
    save("jorogumo_super", super_de(casulo, (atraso(arpejo, 0.2),)), 0.85)
    save("jorogumo_final", mix(seda, atraso(ganho(koto(midi(76), 0.4), 0.5), 0.05)), 0.6)


def herois_2_27b():
    """Heróis 2.27b (Kodama do Shinboku, Kaminari-kozō). Semente própria.
    Rode: gerar_sons.py herois227b"""
    random.seed(2272)

    def save(name, track, gain=0.8):
        k = len(track)
        ini = int(k * 0.7)
        globals()["save"](name, [v * (1.0 if i < ini else (1 - (i - ini) / (k - ini)) ** 2) for i, v in enumerate(track)], gain)

    def super_de(poder, extra=()):
        base = mix(ganho(membrana(58, 0.9), 1.1), atraso(ganho(membrana(52, 0.9), 0.8), 0.24),
                   atraso(ganho(sino(98, 1.6, ((1.0, 1.0, 1.6), (2.1, 0.6, 2.3), (3.3, 0.4, 3.2))), 0.6), 0.3))
        return mix(base, atraso(ganho(poder, 1.1), 0.12), *extra)

    whoosh = lambda sec, pico=0.5: noise(sec, cutoff=lambda x: 0.04 + pico * math.sin(math.pi * x) ** 2, release_pow=1.0)
    madeira = lambda f: suave(sino(f, 0.12, ((1.0, 1.0, 45), (2.76, 0.45, 70), (5.4, 0.2, 95))), 0.0015)

    def rangido(sec, f0=45.0, f1=70.0):
        """Madeira rangendo = atrito de aderência e deslize (stick-slip): um trem
        de pulsos curtos cuja taxa varia devagar; cada pulso excita a fibra."""
        out = [0.0] * n(sec)
        t = 0.0
        while t < sec * 0.95:
            x = t / sec
            f = f0 + (f1 - f0) * x + 8 * math.sin(2 * math.pi * 1.7 * t)
            i0 = n(t)
            for j in range(n(0.008)):
                if i0 + j < len(out):
                    out[i0 + j] += math.sin(2 * math.pi * 900 * j / SR) * math.exp(-j / SR * 500) * math.sin(math.pi * x) ** 0.5
            t += 1.0 / f * random.uniform(0.8, 1.25)
        return out

    def farfalha(sec, dens=0.5):
        """Folhas: ruído agudo com envelope que pisca ao acaso (as folhas batendo)."""
        base = noise(sec, cutoff=lambda x: 0.55, release_pow=1.0)
        e, alvo = 0.0, 0.0
        out = []
        for i, v in enumerate(base):
            if i % 200 == 0:
                alvo = random.uniform(0.1, 1.0) if random.random() < dens else 0.05
            e += 0.01 * (alvo - e)
            out.append(v * e)
        return out

    def estalos(sec, dens=900.0, cauda=4000.0):
        """Faísca: impulsos esparsos (descargas de corona) com sinal ao acaso."""
        out = [0.0] * n(sec)
        for i in range(len(out)):
            if random.random() < dens / SR * (1 - i / len(out)):
                a = random.choice((-1, 1)) * random.uniform(0.3, 1.0)
                for j in range(60):
                    if i + j < len(out):
                        out[i + j] += a * math.exp(-j / SR * cauda)
        return out

    def zumbido(sec, f=120.0):
        """O "bzzz" da descarga: quadrada na rede elétrica com harmônicos ímpares."""
        return tone(lambda x: f * (1 + 0.15 * x), sec, wave_fn=square, release_pow=1.5)

    def trovao(sec=1.6, longe=0.0):
        """Trovão: estalo (onda N do canal que expande a supersônico) seguido do
        ronco, que é a soma dos ecos de cada pedaço do raio chegando a tempos
        diferentes (por isso rola). Longe: o ar come os agudos primeiro."""
        estalo = noise(0.09, cutoff=lambda x: 0.95 - 0.6 * x - 0.5 * longe, release_pow=1.6)
        ecos = [atraso(ganho(noise(random.uniform(0.5, 1.0), cutoff=lambda x: 0.03 + 0.03 * (1 - x), release_pow=1.2), random.uniform(0.4, 1.0)), random.uniform(0.02, 0.5)) for _ in range(6)]
        ronco = mix(*ecos)
        return mix(ganho(estalo, 1.2 * (1 - 0.6 * longe)), ganho(ronco, 1.6))[:n(sec)]

    # Kodama: madeira oca, folhas, terra e o ranger da árvore crescendo.
    pop = mix(madeira(640), ganho(whoosh(0.18, 0.35), 0.5))
    save("kodama_semente", pop, 0.55)
    broto = mix(ganho(tone(lambda x: 300 + 500 * x ** 0.7, 0.2, release_pow=1.6), 0.45), atraso(ganho(farfalha(0.3, 0.7), 0.6), 0.04))
    save("kodama_brota", broto, 0.6)
    terra = noise(0.7, cutoff=lambda x: 0.05 + 0.04 * (1 - x), release_pow=1.3)
    rachas = mix(*(atraso(ganho(madeira(random.uniform(180, 320)), random.uniform(0.5, 1.0)), 0.035 * k + random.uniform(0, 0.02)) for k in range(7)))
    raizes = mix(ganho(terra, 1.4), rachas, atraso(ganho(rangido(0.5, 50, 80), 0.6), 0.1))
    save("kodama_raizes", raizes, 0.8)
    bosque = mix(ganho(rangido(1.0, 35, 60), 0.9), atraso(ganho(farfalha(0.9, 0.6), 0.7), 0.25), ganho(terra, 0.9), atraso(ganho(broto, 0.6), 0.1))
    save("kodama_bosque", bosque, 0.75)
    cai = mix(ganho(rangido(0.55, 70, 30), 0.9), atraso(ganho(membrana(48, 0.6, 0.2), 1.2), 0.45), atraso(ganho(farfalha(0.6, 0.8), 0.8), 0.45))
    save("kodama_cai", cai, 0.75)
    floresta = mix(ganho(noise(1.8, cutoff=lambda x: 0.03, release_pow=0.8), 1.6),
                   *(atraso(ganho(rangido(0.9, 30 + 6 * k, 55 + 5 * k), 0.6), 0.12 * k) for k in range(4)),
                   atraso(ganho(farfalha(1.4, 0.8), 0.7), 0.4), atraso(ganho(coro((73, 110), 1.4, vogal=(500, 900), ataque=0.4), 0.45), 0.2))
    save("kodama_floresta", floresta, 0.85)
    save("kodama_poder", bosque, 0.75)
    save("kodama_super", super_de(floresta), 0.85)
    save("kodama_final", mix(pop, atraso(broto, 0.06)), 0.65)

    # Kaminari-kozō: estalo, zumbido, carga subindo e trovão rolando.
    choque = mix(ganho(estalos(0.22, 1400.0), 0.8), ganho(zumbido(0.18, 140), 0.35), noise(0.03, cutoff=lambda x: 0.9))
    save("kaminari_choque", choque, 0.6)
    carga = mix(ganho(tone(lambda x: 180 + 1100 * x ** 1.5, 0.55, wave_fn=square, release_pow=0.6), 0.25), ganho(estalos(0.6, 600.0), 0.7))
    save("kaminari_carga", carga, 0.55)
    save("kaminari_trovao", trovao(1.6), 0.85)
    relampago = mix(ganho(whoosh(0.3, 0.8), 0.8), atraso(choque, 0.02), atraso(ganho(trovao(0.9, 0.3), 0.7), 0.05))
    save("kaminari_relampago", relampago, 0.8)
    rufo = mix(*(atraso(ganho(membrana(70 + 12 * (k % 3), 0.4), 0.9 if k % 3 == 0 else 0.6), 0.11 * k) for k in range(9)))
    tambor = mix(rufo, atraso(ganho(trovao(1.6, 0.5), 0.9), 0.5))
    save("kaminari_tambor", tambor, 0.85)
    save("kaminari_kozo_poder", relampago, 0.8)
    save("kaminari_kozo_super", super_de(tambor), 0.85)
    save("kaminari_kozo_final", mix(choque, atraso(ganho(trovao(0.7, 0.2), 0.6), 0.03)), 0.75)

if __name__ == "__main__":
    import sys
    if sys.argv[1:] == ["efeitos"]:
        efeitos()
    elif sys.argv[1:] == ["torretas"]:
        torretas()
    elif sys.argv[1:] == ["elementos"]:
        elementos()
    elif sys.argv[1:] == ["magia"]:
        magia()
    elif sys.argv[1:] == ["assinaturas2"]:
        assinaturas_2()
    elif sys.argv[1:] == ["herois227"]:
        herois_2_27()
    elif sys.argv[1:] == ["herois227b"]:
        herois_2_27b()
    else:
        main()
        efeitos()
        torretas()
        elementos()
        magia()
        assinaturas_2()
        herois_2_27()
        herois_2_27b()
