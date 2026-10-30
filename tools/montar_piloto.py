"""Monta a prancha do piloto (saída de tools/prancha_piloto.gd) com legendas.
Uso: python3 tools/montar_piloto.py DIR SAIDA.png"""
import sys
from PIL import Image, ImageDraw, ImageFont

d, saida = sys.argv[1], sys.argv[2]
temas = [("dia", "A  Festival ao Sol"), ("crepusculo", "B  Crepúsculo")]
vistas = [("jogo", "1  Câmera do jogo"), ("frente", "2  De frente"), ("fundos", "3  Pelos fundos")]
W, H, top, esq = 640, 480, 44, 230
fonte = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
f = ImageFont.truetype(fonte, 22)
o = Image.new("RGB", (esq + W * len(vistas), top + H * len(temas)), (24, 20, 28))
dr = ImageDraw.Draw(o)
for j, (_, nome) in enumerate(vistas):
    dr.text((esq + j * W + 12, 10), nome, fill=(240, 230, 210), font=f)
for i, (t, nome) in enumerate(temas):
    linhas = nome.split("  ")
    dr.text((14, top + i * H + H // 2 - 30), linhas[0], fill=(255, 200, 120), font=ImageFont.truetype(fonte, 40))
    dr.text((14, top + i * H + H // 2 + 20), linhas[1], fill=(240, 230, 210), font=f)
    for j, (v, _) in enumerate(vistas):
        im = Image.open(f"{d}/{t}_{v}.png").convert("RGB").resize((W, H), Image.LANCZOS)
        o.paste(im, (esq + j * W, top + i * H))
o.save(saida)
