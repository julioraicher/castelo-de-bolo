"""Prancha do piloto "pátio + casas que funcionam" (saídas de prancha_patio.gd e
prancha_mecanica.gd) e o vídeo das engrenagens.
Uso: python3 tools/montar_mecanica.py ANTES_DIR DEPOIS_DIR MEC_DIR SAIDA.jpg [VIDEO.mp4]"""
import subprocess
import sys
from PIL import Image, ImageDraw, ImageFont

antes, depois, mec, saida = sys.argv[1:5]
fonte = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
f = ImageFont.truetype(fonte, 24)
fg = ImageFont.truetype(fonte, 40)
W1, H1 = 960, 540     # linha 1: pátio antes e depois
W2, H2 = 640, 480     # linha 2: casa e oficina
top = 46
o = Image.new("RGB", (W1 * 2, top + H1 + top + H2), (24, 20, 28))
dr = ImageDraw.Draw(o)
linha1 = [(f"{antes}/patio.png", "A  Pátio hoje: a oficina de cima some atrás da torre"),
          (f"{depois}/patio.png", "B  Pátio novo: oficinas ao lado da máscara, chapéus na frente")]
for j, (arq, txt) in enumerate(linha1):
    o.paste(Image.open(arq).convert("RGB").resize((W1, H1), Image.LANCZOS), (j * W1, top))
    dr.text((j * W1 + 14, 10), txt, fill=(240, 230, 210), font=f)
y2 = top + H1 + top
linha2 = [(f"{mec}/dia_casa.png", "1  Casa da roda d'água"), (f"{mec}/dia_oficina.png", "2  Oficina de chapéus"),
          (f"{mec}/crepusculo_casa.png", "3  Casa no Crepúsculo")]
for j, (arq, txt) in enumerate(linha2):
    o.paste(Image.open(arq).convert("RGB").resize((W2, H2), Image.LANCZOS), (j * W2, y2))
    dr.text((j * W2 + 14, y2 - 36), txt, fill=(255, 200, 120), font=f)
o.save(saida, quality=90)
if len(sys.argv) > 5:
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-framerate", "30", "-i", f"{mec}/filme/f_%03d.png",
                    "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "24", "-movflags", "+faststart", sys.argv[5]], check=True)
