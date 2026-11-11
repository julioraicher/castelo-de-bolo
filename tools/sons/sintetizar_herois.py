#!/usr/bin/env python3
"""Sons dos heróis raros (Ciclo 2.23) sintetizados com numpy, sem fonte externa:
agua (respingo com bolhas), grasnido (corvo), flauta (nota de shakuhachi com sopro).
O papel vem da Kenney (rpg/bookFlip*). Saída: assets/audio/biblioteca/sintese/*.wav;
aplicar com tools/sons/trocar_som.sh <nome> <arquivos>.
Uso: python3 tools/sons/sintetizar_herois.py"""
import os, wave
import numpy as np

SR = 44100
OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "audio", "biblioteca", "sintese")
rng = np.random.default_rng(23)


def salvar(nome, x):
    x = x / (np.max(np.abs(x)) + 1e-9) * 0.9
    with wave.open(os.path.join(OUT, nome + ".wav"), "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes((x * 32767).astype(np.int16).tobytes())


def passa_baixa(x, fc):
    # Filtro de 1 polo (RC): y[n] = y[n-1] + a (x[n] - y[n-1]); fc pode variar no tempo.
    fc = np.broadcast_to(fc, x.shape)
    a = 1 - np.exp(-2 * np.pi * fc / SR)
    y = np.zeros_like(x)
    acc = 0.0
    for i in range(len(x)):
        acc += a[i] * (x[i] - acc)
        y[i] = acc
    return y


def t_(dur):
    return np.arange(int(dur * SR)) / SR


def agua(seed):
    r = np.random.default_rng(seed)
    t = t_(0.55)
    # Respingo: ruído com ataque rápido e corte que fecha (o "chuá" escurece).
    ruido = r.normal(0, 1, len(t)) * np.exp(-t * 9) * (1 - np.exp(-t * 400))
    x = passa_baixa(ruido, 6000 * np.exp(-t * 5) + 300) * 1.2
    # Bolhas: senos curtos com frequência subindo (bolha que sobe e estoura).
    for _ in range(7):
        t0 = r.uniform(0.03, 0.35)
        f0 = r.uniform(500, 1100)
        d = r.uniform(0.03, 0.07)
        m = (t >= t0) & (t < t0 + d)
        tt = t[m] - t0
        x[m] += 0.45 * np.sin(2 * np.pi * (f0 * tt + 0.5 * f0 * 6 * tt * tt)) * np.exp(-tt * 40)
    return x


def grasnido(seed):
    r = np.random.default_rng(seed)
    t = t_(0.62)
    x = np.zeros_like(t)
    for k, t0 in enumerate([0.0, 0.3]):
        d = 0.24 - 0.03 * k
        m = (t >= t0) & (t < t0 + d)
        tt = t[m] - t0
        f = 720 * (1 - 0.35 * tt / d) * r.uniform(0.95, 1.05)  # cai no fim: "cráá"
        fase = 2 * np.pi * np.cumsum(f) / SR
        serra = 2 * ((fase / (2 * np.pi)) % 1.0) - 1  # rouco: dente de serra + ruído
        env = np.sin(np.pi * tt / d) ** 0.6
        x[m] += (serra * 0.8 + r.normal(0, 0.35, len(tt))) * env
    # Formante nasal: realça ~1,5 kHz (diferença de dois passa-baixas).
    return passa_baixa(x, 2400) - 0.6 * passa_baixa(x, 700)


def flauta(f0, seed):
    r = np.random.default_rng(seed)
    t = t_(0.7)
    vib = 1 + 0.012 * np.sin(2 * np.pi * 5.2 * t) * np.clip(t * 3, 0, 1)
    fase = 2 * np.pi * np.cumsum(f0 * vib) / SR
    tom = np.sin(fase) + 0.25 * np.sin(2 * fase) + 0.08 * np.sin(3 * fase)
    env = np.clip(t / 0.08, 0, 1) * np.exp(-np.clip(t - 0.35, 0, None) * 5)
    sopro = passa_baixa(r.normal(0, 1, len(t)), 3500) * (0.35 * np.exp(-t * 6) + 0.08)
    return (tom * 0.8 + sopro) * env


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    for i in range(3):
        salvar("agua_%d" % i, agua(10 + i))
        salvar("grasnido_%d" % i, grasnido(20 + i))
    for i, f in enumerate([392.0, 440.0, 523.25]):  # sol, lá, dó: pentatônica
        salvar("flauta_%d" % i, flauta(f, 30 + i))
    print("ok:", sorted(os.listdir(OUT)))
