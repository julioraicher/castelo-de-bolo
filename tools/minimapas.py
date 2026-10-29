"""Minimapas das ideias de mapa (só para escolher; nada disso está no jogo).
Uso: python3 tools/minimapas.py SAIDA.png
Coordenadas em metros, iguais às do jogo: x liga os castelos (azul em -48,
vermelho em +48), z é a profundidade (arena 136 x 72 m)."""
import math, sys
from PIL import Image, ImageDraw, ImageFont

S = 4.6  # pixels por metro
HW, HD = 68, 36
W, H = int(HW * 2 * S), int(HD * 2 * S)
COR = dict(chao=(38, 33, 56), estrada=(96, 92, 116), agua=(44, 96, 150), arvore=(46, 118, 84),
           bambu=(64, 150, 92), predio=(150, 146, 170), azul=(80, 140, 255), vermelho=(255, 92, 92),
           espirito=(90, 255, 160), item=(255, 212, 80), oficina=(205, 150, 90), ponte=(200, 60, 70),
           muro=(120, 116, 140), texto=(240, 232, 255))
FB = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
FR = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"


def px(x, z):
    return ((x + HW) * S, (z + HD) * S)


class Mapa:
    def __init__(self, titulo, linhas):
        self.im = Image.new("RGB", (W, H), COR["chao"])
        self.d = ImageDraw.Draw(self.im)
        self.titulo, self.linhas = titulo, linhas

    def ret(self, x0, z0, x1, z1, cor, borda=None):
        a, b = px(min(x0, x1), min(z0, z1)), px(max(x0, x1), max(z0, z1))
        self.d.rectangle([a, b], fill=COR.get(cor, cor), outline=borda)

    def circ(self, x, z, r, cor, contorno=False):
        a, b = px(x - r, z - r), px(x + r, z + r)
        if contorno:
            self.d.ellipse([a, b], outline=COR[cor], width=3)
        else:
            self.d.ellipse([a, b], fill=COR[cor])

    def linha(self, pts, larg, cor):
        self.d.line([px(*p) for p in pts], fill=COR[cor], width=int(larg * S), joint="curve")

    def estrela(self, x, z):
        cx, cy = px(x, z)
        pts = []
        for k in range(10):
            r = 9 if k % 2 == 0 else 4
            a = -math.pi / 2 + k * math.pi / 5
            pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
        self.d.polygon(pts, fill=COR["item"])

    def castelos(self):
        for f, cor in ((-1, "azul"), (1, "vermelho")):
            cx = 48 * f
            self.ret(cx - 13 if f < 0 else cx - 11, -13, cx + 11 if f < 0 else cx + 13, 13, (30, 26, 44))
            c = COR[cor]
            box = [px(cx - 13 if f < 0 else cx - 11, -13), px(cx + 11 if f < 0 else cx + 13, 13)]
            self.d.rectangle(box, outline=c, width=5)
            gx = cx - 11 * f  # portão na frente (lado do inimigo)
            self.ret(gx - 1.5, -5, gx + 1.5, 5, COR["chao"])
            self.circ(cx + 8 * f, 0, 3.2, cor)       # torre principal
            self.circ(cx + 1 * f, 0, 1.7, "espirito", True)  # pedestal da máscara
            for z in (-8.5, 8.5):
                self.ret(cx + 6 * f, z - 1.5, cx + 9 * f, z + 1.5, COR["oficina"])

    def legenda_texto(self):
        return self.titulo, self.linhas


def atual():
    m = Mapa("0. Vale dos Dois Clãs (o atual)", ["Estrada reta entre os castelos, bosques e pedras",
                                                 "nos lados. Simples e direto: bom para testar."])
    m.ret(-37, -3.5, 37, 3.5, "estrada")
    for x in (-16, 16):
        m.circ(x, 0, 1.7, "predio")
    for x, z in ((26, 19), (8, 12), (0, 24), (33, 31), (19, 27)):
        for sx in (-1, 1):
            for sz in (-1, 1):
                if x == 0 and sx < 0:
                    continue
                m.circ(x * sx, z * sz, 2.4 if x in (26, 33) else 1.5, "arvore")
    for z in (-13, 13):
        m.circ(0, z, 1.9, "predio")
    for sx in (-1, 1):
        for sz in (-1, 1):
            m.circ(40 * sx, 26 * sz, 3.2, "agua")
            m.circ(17 * sx, 15 * sz, 1.3, "predio")
    m.castelos()
    for x, z in ((-8, -18), (10, 20), (0, 6), (-20, 10), (22, -12)):
        m.circ(x, z, 1.2, "espirito")
    m.estrela(0, -8); m.estrela(-12, 0); m.estrela(14, 4)
    return m


def rio():
    m = Mapa("1. Rio das Lanternas", ["Um rio corta o meio. 3 pontes = 3 gargalos: a do meio",
                                       "é larga, as dos lados são estreitas. Espíritos na ilha."])
    pts = [(math.sin(z / 9.0) * 3, z) for z in range(-40, 41, 2)]
    m.linha(pts, 9, "agua")
    m.ret(-37, -3.5, 37, 3.5, "estrada")
    m.ret(-6, -4.5, 6, 4.5, "ponte")
    for z in (-24, 24):
        m.ret(-6, z - 1.8, 6, z + 1.8, "ponte")
    m.circ(0, 12, 3.5, "arvore"); m.circ(0, -12, 3.5, "arvore")
    for sx in (-1, 1):
        for x, z in ((14, 14), (24, 24), (20, -16), (30, -28), (12, -26)):
            m.circ(x * sx, z, 2.2, "arvore")
        m.circ(18 * sx, 0, 1.8, "predio")
    m.castelos()
    for x, z in ((0, 0), (-2, 6), (2, -6)):
        m.circ(x, z, 1.2, "espirito")
    m.estrela(0, 24); m.estrela(0, -24)
    return m


def bambuzal():
    m = Mapa("2. Bambuzal de Três Trilhas", ["Paredes de bambu fazem 3 trilhas. A do meio é rápida;",
                                              "as dos lados têm santuários com itens. Emboscadas."])
    m.ret(-37, -3.5, 37, 3.5, "estrada")
    for z0, z1 in ((7, 15), (-15, -7)):
        for x0, x1 in ((-34, -24), (-18, -4), (4, 18), (24, 34)):
            m.ret(x0, z0, x1, z1, "bambu")
    for z in (-22, 22):
        m.linha([(-36, z), (-20, z + (3 if z > 0 else -3)), (0, z), (20, z - (3 if z > 0 else -3)), (36, z)], 5, "estrada")
        m.ret(-2.5, z - 2.5, 2.5, z + 2.5, "predio")
        m.estrela(0, z)
    for sx in (-1, 1):
        m.circ(20 * sx, 0, 1.7, "predio")
    m.ret(-37, 28, 37, 36, "bambu"); m.ret(-37, -36, 37, -28, "bambu")
    m.castelos()
    for x, z in ((-6, 0), (6, 0), (0, 3)):
        m.circ(x, z, 1.2, "espirito")
    return m


def templo():
    m = Mapa("3. Templo Central", ["Um templo murado no meio com 4 portões. Espíritos só",
                                    "nascem lá dentro: quem domina o templo engorda a máscara."])
    m.ret(-37, -3.5, -15, 3.5, "estrada"); m.ret(15, -3.5, 37, 3.5, "estrada")
    m.ret(-15, -12, 15, 12, (60, 54, 80))
    box = [px(-15, -12), px(15, 12)]
    m.d.rectangle(box, outline=COR["muro"], width=int(1.5 * S))
    for x0, z0, x1, z1 in ((-16, -3, -14, 3), (14, -3, 16, 3), (-3, -13, 3, -11), (-3, 11, 3, 13)):
        m.ret(x0, z0, x1, z1, (60, 54, 80))
    m.circ(0, 0, 3.0, "predio")
    for sx in (-1, 1):
        for sz in (-1, 1):
            m.circ(9 * sx, 7 * sz, 1.0, "predio")
            m.circ(28 * sx, 22 * sz, 3.0, "arvore")
            m.circ(12 * sx, 26 * sz, 2.0, "arvore")
    m.castelos()
    for x, z in ((-8, -3), (7, 4), (3, -7), (-5, 6)):
        m.circ(x, z, 1.2, "espirito")
    m.estrela(0, 28); m.estrela(0, -28); m.estrela(-26, 0); m.estrela(26, 0)
    return m


def vila():
    m = Mapa("4. Vila Neon", ["Quarteirões de casas com placas de neon entre os castelos.",
                               "Avenida reta no meio, becos para flanquear, praça central."])
    m.ret(-37, -3.5, 37, 3.5, "estrada")
    for x0 in range(-32, 32, 9):
        for z0 in (-30, -21, -12, 6, 15, 24):
            if math.hypot(x0 + 3, z0 + 3) < 13:
                continue
            m.ret(x0, z0, x0 + 6, z0 + 6, "predio")
            m.ret(x0 + 1, z0 + 5.3, x0 + 5, z0 + 6, (255, 80, 210))
    m.circ(0, 0, 9, "estrada")
    m.circ(0, 0, 2, "agua")
    m.castelos()
    for x, z in ((-6, 5), (6, -5), (2, 8)):
        m.circ(x, z, 1.2, "espirito")
    m.estrela(-14, 18); m.estrela(14, -18); m.estrela(0, -8)
    return m


def main(saida):
    mapas = [atual(), rio(), bambuzal(), templo(), vila()]
    fb, fr = ImageFont.truetype(FB, 26), ImageFont.truetype(FR, 19)
    cab = 92
    cols, rows = 2, 3
    out = Image.new("RGB", (cols * (W + 16) + 16, rows * (H + cab + 16) + 16), (14, 12, 30))
    d = ImageDraw.Draw(out)
    for i, m in enumerate(mapas):
        x = 16 + (i % cols) * (W + 16)
        y = 16 + (i // cols) * (H + cab + 16)
        d.text((x, y), m.titulo, fill=COR["texto"], font=fb)
        for k, l in enumerate(m.linhas):
            d.text((x, y + 34 + k * 24), l, fill=(200, 194, 220), font=fr)
        out.paste(m.im, (x, y + cab))
    # Legenda na última célula.
    x = 16 + W + 16
    y = 16 + 2 * (H + cab + 16)
    d.text((x, y), "Legenda", fill=COR["texto"], font=fb)
    itens = [("azul", "castelo Azul / torre"), ("vermelho", "castelo Vermelho"), ("espirito", "espírito (nasce aqui) / pedestal"),
             ("item", "itens no chão (estrela)"), ("oficina", "terrenos de oficina"), ("estrada", "estrada"),
             ("agua", "água (não dá para andar)"), ("arvore", "árvores / bosques"), ("bambu", "bambuzal (parede)"),
             ("predio", "pedras, santuários, casas"), ("ponte", "ponte")]
    for k, (c, t) in enumerate(itens):
        yy = y + 44 + k * 30
        d.rectangle([x, yy, x + 22, yy + 22], fill=COR[c])
        d.text((x + 34, yy - 1), t, fill=(220, 214, 240), font=fr)
    out.save(saida)


if __name__ == "__main__":
    main(sys.argv[1])
