"""Planta numerada do mapa (vista de cima, +z para baixo como na câmera do jogo).
Uso: godot --headless --path . -s tools/planta_mapa.gd -- X.json
     python3 tools/planta_mapa.py X.json SAIDA.jpg"""
import json, math, sys
from PIL import Image, ImageDraw, ImageFont

d = json.load(open(sys.argv[1]))
HW, HD = d["meia_largura"], d["meia_prof"]
S, M = 9.0, 16  # pixels por metro, margem
W, H = int(HW * 2 * S) + 2 * M, int(HD * 2 * S) + 2 * M
LEG = 330
FB = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
FR = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
f_num, f_leg, f_tit = ImageFont.truetype(FB, 11), ImageFont.truetype(FR, 14), ImageFont.truetype(FB, 17)
C = dict(chao=(52, 78, 50), estrada=(140, 118, 90), agua=(52, 110, 170), ponte=(170, 70, 60), colina=(84, 104, 62),
         predio=(150, 140, 160), arvore=(40, 120, 70), muro=(120, 112, 130), texto=(240, 234, 220), fundo=(24, 20, 28),
         azul=(90, 150, 255), vermelho=(255, 95, 95))
im = Image.new("RGB", (W, H + LEG), C["fundo"])
dr = ImageDraw.Draw(im)


def px(x, z):
    return ((x + HW) * S + M, (z + HD) * S + M)


def ret(cx, cz, w, h, rot, cor, borda=None):
    a = math.radians(-rot)
    pts = []
    for sx, sz in [(-1, -1), (1, -1), (1, 1), (-1, 1)]:
        x, z = sx * w / 2, sz * h / 2
        pts.append(px(cx + x * math.cos(a) - z * math.sin(a), cz + x * math.sin(a) + z * math.cos(a)))
    dr.polygon(pts, fill=cor, outline=borda)


def circ(x, z, r, cor, borda=None, w=1):
    a, b = px(x - r, z - r), px(x + r, z + r)
    dr.ellipse((a[0], a[1], b[0], b[1]), fill=cor, outline=borda, width=w)


def rotulo(x, z, txt, cor, fonte=f_num, fundo=(20, 16, 24)):
    p = px(x, z)
    bb = dr.textbbox((0, 0), txt, font=fonte)
    w, h = bb[2] - bb[0], bb[3] - bb[1]
    dr.rounded_rectangle((p[0] - w / 2 - 4, p[1] - h / 2 - 4, p[0] + w / 2 + 4, p[1] + h / 2 + 5), 4, fill=fundo, outline=cor)
    dr.text((p[0] - w / 2, p[1] - h / 2 - 1), txt, fill=cor, font=fonte)


# Chão, estrada, rio, pontes e colinas.
dr.rectangle((M, M, W - M, H - M), fill=C["chao"])
a, b = px(-HW, -3.5), px(HW, 3.5)
dr.rectangle((a[0], a[1], b[0], b[1]), fill=C["estrada"])
a, b = px(-4.5, -HD), px(4.5, HD)
dr.rectangle((a[0], a[1], b[0], b[1]), fill=C["agua"])
for o in d["objetos"]:
    if o["modelo"] == "colina":
        ret(o["pos"][0], o["pos"][1], 12, 8, 0, C["colina"], (40, 50, 30))
for z, larg in [(0, 8), (-22, 4.6), (22, 4.6)]:
    ret(0, z, 18, larg, 0, C["ponte"], (60, 30, 30))

# Muralhas.
for p in d["pontos"]:
    if p["tipo"] != "castelo":
        continue
    cx, t = p["pos"][0], p["time"]
    cor = C["azul"] if t == 0 else C["vermelho"]
    xa, xf, m, g = cx + p["atras"], cx + p["frente"], p["meia"], p["portao"]
    e = 3.6
    for z in (-m, m):
        ret((xa + xf) / 2, z, abs(xf - xa) + e, e, 0, C["muro"], cor)
    ret(xa, 0, e, 2 * m, 0, C["muro"], cor)
    for z0, z1 in ((-m, -g), (g, m)):
        ret(xf, (z0 + z1) / 2, e, z1 - z0, 0, C["muro"], cor)

# Objetos: prédios numerados (mesmo número dos dois lados), miúdos sem número.
SEM_NUM = {"lanterna_pedra", "poste", "rio_a", "rio_b", "colina", "escada_colina", "escada_muralha", "ponte_grande",
           "ponte_lateral", "portao", ""}
NOMES = {"casa_a": "casa", "loja": "loja", "pousada": "pousada", "armazem": "armazém", "casa_moinho": "casa da roda d'água",
         "casa_moinho_esq": "casa da roda d'água", "forja": "forja", "casa_de_cha": "casa de chá", "jardim": "jardim de pedra",
         "barraca": "barraca da feira", "varal": "varal", "torii": "portal torii", "carroca": "carroça", "barricada": "barricada",
         "festival": "festival", "jizos": "estátuas jizo", "poco": "poço", "pilha": "caixas e barris", "estatua": "estátua",
         "templo": "templo", "arvore_espirito": "árvore-espírito", "dojo": "dojo", "lago": "lago", "bambuzal": "bambuzal (enfeite)",
         "santuario": "santuário", "arvore_alta": "cedro gigante", "arvore_media": "árvore", "arvore_grande": "árvore grande",
         "ruina": "ruína", "rochas": "rochas", "cerca": "cerca", "aldeoes": "moradores", "arrozal": "arrozal", "barco": "barco",
         "cachoeira": "cachoeira", "ponte_corda": "ponte de corda", "pagode": "pagode (colina)", "vigia": "torre de vigia (colina)",
         "sino": "sino", "barril": "barril", "caixotes": "caixotes"}
numero = {}
for o in d["objetos"]:
    x, z = o["pos"]
    mod = o["modelo"]
    if o["col"] == "caixa" and mod not in ("", "colina"):
        ret(x + o["desl"][0], z + o["desl"][1], o["tam"][0], o["tam"][1], o["rot"] if o["rot"] >= 0 else 0, C["predio"], (60, 55, 70))
    elif o["col"] == "cilindro":
        circ(x, z, o["raio"], C["arvore"] if "arvore" in mod else C["predio"], (30, 40, 30))
    elif mod in ("lanterna_pedra", "poste"):
        circ(x, z, 0.45, (255, 200, 110))
    elif mod not in SEM_NUM:
        circ(x, z, 0.9, (110, 100, 120))
for o in d["objetos"]:
    mod = o["modelo"]
    if mod in SEM_NUM:
        continue
    nome = NOMES.get(mod, mod)
    if nome not in numero:
        numero[nome] = len(numero) + 1
    rotulo(o["pos"][0], o["pos"][1], str(numero[nome]), C["texto"])

# Jogo: letras grandes coloridas.
JOGO = {"mascara": ("M", (255, 240, 120), "Máscara (onde ela fica)"), "maquina": ("C", (110, 220, 255), "Maquininhas de chapéu (4 por time)"),
        "oficina": ("O", (255, 140, 210), "Oficinas / casinhas (custam madeira)"), "pilha": ("P", (255, 180, 80), "Pilha de toras (entrega da madeira)"),
        "arvore": ("A", (120, 240, 120), "Árvore de corte (bosque seguro)"), "bambu": ("B", (190, 255, 110), "Bambu de corte (meio, briga)"),
        "torre_principal": ("T", (230, 230, 255), "Torre principal"), "nascer": ("N", (200, 200, 200), "Onde o time nasce"),
        "torre": ("t", (200, 200, 220), "Torres do portão")}
for p in d["pontos"]:
    if p["tipo"] in JOGO:
        letra, cor, _ = JOGO[p["tipo"]]
        fundo = (30, 40, 90) if p["time"] == 0 else ((90, 30, 30) if p["time"] == 1 else (30, 60, 30))
        rotulo(p["pos"][0], p["pos"][1], letra, cor, f_tit, fundo)

# Legenda.
y0 = H + 8
dr.text((M, y0), "Rio das Lanternas visto de cima (azul à esquerda, vermelho à direita; a câmera do jogo olha de baixo para cima)", fill=(255, 200, 120), font=f_tit)
y0 += 30
col = 0
for k, (letra, cor, txt) in enumerate(JOGO.values()):
    x = M + (k % 3) * 400
    y = y0 + (k // 3) * 22
    dr.text((x, y), letra, fill=cor, font=f_tit)
    dr.text((x + 24, y + 2), txt, fill=C["texto"], font=f_leg)
y0 += 3 * 22 + 12
itens = sorted(numero.items(), key=lambda kv: kv[1])
por_col = math.ceil(len(itens) / 5)
for i, (nome, n) in enumerate(itens):
    x = M + (i // por_col) * 245
    y = y0 + (i % por_col) * 19
    dr.text((x, y), f"{n:>2}  {nome}", fill=C["texto"], font=f_leg)
dr.text((M, H + LEG - 22), "pontinhos amarelos = lanternas e postes · cinza = prédio com colisão · verde = árvore · faixa marrom = estrada · azul = rio",
        fill=(190, 185, 200), font=f_leg)
im = im.crop((0, 0, W, y0 + por_col * 19 + 30))
if im.width > 1280:
    im = im.resize((1280, round(im.height * 1280 / im.width)), Image.LANCZOS)
im.save(sys.argv[2], quality=90)
print(im.size, len(numero), "tipos numerados")
