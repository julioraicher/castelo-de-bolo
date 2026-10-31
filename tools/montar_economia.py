"""Monta a prancha da Economia do Construtor (saídas de tools/prancha_economia.gd
e tools/prancha_economia_mapa.gd) com legendas.
Uso: python3 tools/montar_economia.py DIR SAIDA.jpg"""
import sys
from PIL import Image, ImageDraw, ImageFont

d, saida = sys.argv[1], sys.argv[2]
FONTE = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
f = ImageFont.truetype(FONTE, 20)
fp = ImageFont.truetype(FONTE, 16)
FUNDO, TEXTO, OURO = (24, 20, 28), (240, 230, 210), (255, 200, 120)
W = 1280
o = Image.new("RGB", (W, 1236), FUNDO)
dr = ImageDraw.Draw(o)


def titulo(y, txt):
    dr.text((14, y + 6), txt, fill=OURO, font=f)


def abrir(nome, larg, alt=None):
    im = Image.open(f"{d}/{nome}").convert("RGB")
    if alt is None:
        alt = round(im.height * larg / im.width)
    return im.resize((larg, alt), Image.LANCZOS)


# A. Plantas (1280x440 -> recorte central 1280x340).
y = 0
titulo(y, "A  Árvore (40 s por estágio, 3 toras)              B  Bambu (15 s, 2 varas)            ofuda aceso = pronta")
pl = abrir("plantas.png", W).crop((0, 60, W, 400))
o.paste(pl, (0, 36))
for k, x in enumerate([0.11, 0.24, 0.41, 0.6, 0.69, 0.82]):
    dr.text((int(W * x), 36 + 300), str(k % 3 + 1), fill=TEXTO, font=f, stroke_width=3, stroke_fill=FUNDO)

# C. Maquininha em 4 quadros.
y = 36 + 340 + 6
titulo(y, "C  Maquininha de chapéu (enfeite da classe na placa; estoque na prateleira)")
nomes = ["1 prensa desce", "2 molde brilha", "3 chapéu sai + vapor", "4 vai para a prateleira"]
for q in range(4):
    im = abrir(f"maquina_{q + 1}.png", 320)
    o.paste(im, (q * 320, y + 36))
    dr.text((q * 320 + 10, y + 36 + im.height - 30), nomes[q], fill=TEXTO, font=fp, stroke_width=3, stroke_fill=FUNDO)
y += 36 + 368 + 6

# D. Contador sobre a casinha + E. mapa.
titulo(y, "D  Casinha em obra: contador")
titulo_e = "E  Rio das Lanternas: onde fica cada coisa"
dr.text((W // 2 + 14, y + 6), titulo_e, fill=OURO, font=f)
ct = abrir("contador.png", W // 2)
o.paste(ct, (0, y + 36))
dr.text((14, y + 36 + 8), "Construtor: grande", fill=TEXTO, font=fp, stroke_width=3, stroke_fill=FUNDO)
dr.text((W // 2 - 270, y + 36 + 8), "outras classes: pequeno,", fill=TEXTO, font=fp, stroke_width=3, stroke_fill=FUNDO)
dr.text((W // 2 - 270, y + 36 + 28), "pisca sem estoque", fill=TEXTO, font=fp, stroke_width=3, stroke_fill=FUNDO)
mp = Image.open(f"{d}/mapa.png").convert("RGB")
# Metade azul (o mapa é espelhado), em escala 1:1.
cx, cy = 20, 130
mp = mp.crop((cx, cy, cx + W // 2, cy + 420))
o.paste(mp, (W // 2, y + 36))
dm = ImageDraw.Draw(o)
cores = {"bosque": (120, 230, 120), "bambu": (170, 255, 120), "pilha": (255, 190, 90), "maquinas": (120, 220, 255), "oficinas": (255, 140, 200)}
vistos = set()
for linha in open(f"{d}/mapa.txt"):
    nome, x, yy = linha.split()
    px, py = W // 2 + int(x) - cx, y + 36 + int(yy) - cy
    if not (W // 2 < px < W - 20 and y + 36 < py < y + 36 + 420) or nome in vistos:
        continue
    vistos.add(nome)
    c = cores[nome]
    dm.ellipse((px - 14, py - 14, px + 14, py + 14), outline=c, width=4)
    dm.text((px + 16, py - 10), nome, fill=c, font=fp, stroke_width=3, stroke_fill=FUNDO)
o = o.crop((0, 0, W, y + 36 + 420))
o.save(saida, quality=88)
