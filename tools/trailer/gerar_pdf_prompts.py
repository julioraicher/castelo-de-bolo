# Gera o PDF de prompts do trailer para o Gemini: python3 tools/trailer/gerar_pdf_prompts.py PASTA
# (PASTA precisa ter ninjas.jpg e cenario.jpg, recortes das pranchas 04 e 11/12)
import sys
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm
from reportlab.lib import colors
from reportlab.lib.styles import ParagraphStyle
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (SimpleDocTemplate, Paragraph, Spacer, Image,
                                Table, TableStyle, PageBreak, KeepTogether)

D = sys.argv[1]
F = "/home/user/castelo-de-bolo/assets/fonts/"
pdfmetrics.registerFont(TTFont("Titulo", F + "Shojumaru-Regular.ttf"))
pdfmetrics.registerFont(TTFont("Texto", F + "ChakraPetch-Medium.ttf"))
pdfmetrics.registerFont(TTFont("Negrito", F + "ChakraPetch-Bold.ttf"))
pdfmetrics.registerFont(TTFont("Mono", "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf"))

TINTA = colors.HexColor("#1b1626")
SANGUE = colors.HexColor("#b3202a")
CINZA = colors.HexColor("#555060")
FUNDO = colors.HexColor("#f3eee6")

h1 = ParagraphStyle("h1", fontName="Titulo", fontSize=24, leading=28, textColor=SANGUE)
h2 = ParagraphStyle("h2", fontName="Negrito", fontSize=14, leading=18, textColor=TINTA, spaceBefore=8, spaceAfter=4)
txt = ParagraphStyle("t", fontName="Texto", fontSize=10.5, leading=14.5, textColor=TINTA)
pq = ParagraphStyle("pq", parent=txt, fontSize=9, leading=12, textColor=CINZA)
code = ParagraphStyle("c", fontName="Mono", fontSize=8.6, leading=11.6, textColor=TINTA)


def caixa(texto, cor=FUNDO):
    t = Table([[Paragraph(texto.replace("\n", "<br/>"), code)]], colWidths=[174 * mm])
    t.setStyle(TableStyle([("BACKGROUND", (0, 0), (-1, -1), cor),
                           ("BOX", (0, 0), (-1, -1), 0.6, CINZA),
                           ("LEFTPADDING", (0, 0), (-1, -1), 7), ("RIGHTPADDING", (0, 0), (-1, -1), 7),
                           ("TOPPADDING", (0, 0), (-1, -1), 6), ("BOTTOMPADDING", (0, 0), (-1, -1), 6)]))
    return t


def img(path, w):
    from PIL import Image as P
    a, b = P.open(path).size
    return Image(path, width=w, height=w * b / a)


ESTILO = """STYLE: dark painted fairy-tale, like a hand-painted PS3-era stylized game (Fat Princess) but grim and cinematic. Stylized 3D characters about 3.5 heads tall, slightly big hands and feet, chunky readable silhouettes, expressive angry faces. Hand-painted textures with big soft brush strokes, painted shadows in corners, warm rim light, thin ink outline. Lighting: dusk turning to night, blood-orange and red sky, long cold purple-blue shadows, low fog on the ground, paper lanterns glowing, crows. Each ninja shows POWER ON THE BODY: glowing seals/sigils on skin and cloth, glowing eyes, dark smoke aura. Rival clans: BLUE clan vs RED clan, team colour on most of the outfit. Keep the costumes, hats and weapons of reference image A and the village of reference image B, only restyle them. Cinematic 16:9, shallow depth of field, film grain, no text, no logos, no UI."""

PROMPTS = [
    ("1 · Elenco (pôster dos 4 papéis)", "Pôster para conferir o estilo dos personagens.",
     "Lineup poster of four blue-clan ninjas standing on a red wooden bridge in the fog, low camera looking up: the Samurai (blue kabuto with small golden horns, glowing cyan katana), the Shuriken Ninja (blue hood, headband, glowing star blades between fingers), the Chi Monk (wide straw hat, prayer beads, green spirit fire in both palms), the Trapper (goggles, cloth mask, backpack full of spikes). Their seals glow brighter from left to right. Far behind them, a red castle under a huge red moon.",
     "Slow push-in from low angle. Fog drifts across the bridge, the seals on each ninja ignite one by one from left to right, eyes flare, embers float up. Crows fly across the moon. 8 seconds, no camera cuts."),
    ("2 · Plano 4: o ninja se prepara (close)", "Close de um ninja azul acendendo o poder.",
     "Extreme close-up of the blue-clan Samurai tightening the cloth wrap on his fist. Glowing cyan seals crawl up his forearm, his eyes ignite, dark smoke rises from his shoulders. Lantern light from the side, fog, embers floating.",
     "The cloth is pulled tight with a jerk, seals crawl up the arm like electricity, the camera racks focus from the fist to the glowing eyes. Smoke curls upward. 8 seconds, slow and tense."),
    ("3 · Plano 5: o clã vermelho sai da neblina", "O momento de medo: o inimigo chegando.",
     "Wide shot of a long red wooden bridge over a dark river at night. Six red-clan ninjas walk out of thick fog toward the camera in perfect step: the Ronin Oni with a red demon mask and a spiked club in front, a Kitsune with a white fox mask and blue fox-fire wisps, an Onmyoji with a tall black hat and paper talismans. Only their glowing red eyes and red seals are clearly visible, the rest is silhouette. Menacing, horror movie framing.",
     "Static camera. The silhouettes emerge slowly from the fog, marching in sync, eyes glowing brighter as they approach. Fox-fire wisps flicker. Lanterns on the bridge go out one by one behind them. 8 seconds."),
    ("4 · Plano 3: a Máscara Oni", "O tesouro do jogo, como uma relíquia amaldiçoada.",
     "A large ancient Oni demon mask (red lacquer, golden horns, fangs) resting on a stone pedestal inside a dark castle hall, bound by heavy iron chains. Ghost flames (hitodama, pale blue-green) orbit it slowly. Its empty eyes are starting to glow. Dust in the light beams, unsettling, quiet dread.",
     "Very slow dolly toward the mask. The ghost flames circle faster, the chains tremble and rattle, the eye holes ignite red. At the very end the mouth twitches into a grin. 8 seconds."),
    ("5 · Plano 7: fuga com a máscara", "A mecânica do jogo (carregar o tesouro) em tom de terror.",
     "A blue-clan Shuriken Ninja running through a dark village street at dusk, carrying the huge Oni demon mask in both arms, straining under its weight. Ghostly chains of spirit light pour out of the mask and pull him backward. Red-clan silhouettes with glowing eyes chase him through the fog. Dynamic low angle, motion blur, lanterns swinging.",
     "Tracking shot running alongside the ninja. Spirit chains snap tight and yank him back, he stumbles and keeps running. Pursuers close in from the fog behind. 8 seconds, handheld energy."),
]

doc = SimpleDocTemplate(D + "/trailer-prompts-gemini.pdf", pagesize=A4,
                        leftMargin=18 * mm, rightMargin=18 * mm, topMargin=16 * mm, bottomMargin=14 * mm,
                        title="Trailer: prompts para o Gemini", author="Castelo de Bolo")
s = []
s.append(Paragraph("A Máscara Tem Fome", h1))
s.append(Paragraph("Trailer cinematográfico · prompts de personagens e cenas para testar no Gemini", pq))
s.append(Spacer(1, 6 * mm))
s.append(Paragraph("Como usar (2 minutos por teste)", h2))
for l in [
    "1. No app do Gemini, anexe <b>este PDF</b> e escreva a frase da caixa abaixo, trocando o número do prompt.",
    "2. Gostou da imagem? Peça no mesmo chat: <i>\"agora anime em vídeo usando o MOVIMENTO do prompt N\"</i>, "
    "ou leve a imagem para o Flow (imagem para vídeo) com o texto de MOVIMENTO.",
    "3. Salve o que ficar bom (imagem ou vídeo) e mande para o Claude, na thread do trailer, com o número e "
    "uma frase do que achou (\"3 ficou ótimo, 1 muito fofo\").",
]:
    s.append(Paragraph(l, txt)); s.append(Spacer(1, 2 * mm))
s.append(Spacer(1, 2 * mm))
s.append(caixa("Read the attached PDF. Use reference images A (characters) and B (village) "
               "and the STYLE block. Generate PROMPT 1 as a single 16:9 image. "
               "Do not copy the labels or text from the references.", colors.HexColor("#efe2d6")))
s.append(Spacer(1, 3 * mm))
s.append(Paragraph("Dica: um prompt por vez. Se o Gemini deixar fofo demais, responda "
                   "\"darker, scarier, more horror-movie lighting, keep the characters\".", pq))
s.append(Spacer(1, 5 * mm))
s.append(Paragraph("STYLE (vale para todos os prompts)", h2))
s.append(caixa(ESTILO))
s.append(PageBreak())

s.append(Paragraph("Reference A · characters (keep outfits, hats, weapons)", h2))
s.append(img(D + "/ninjas.jpg", 174 * mm))
s.append(Paragraph("Rows A/B/C = 3 variants of each role. Columns: 1 Warrior, 2 Shooter, 3 Mage, 4 Builder. "
                   "Blue clan shown; the red clan is identical in red. Target look is darker, painted, "
                   "3.5 heads tall, with glowing seals.", pq))
s.append(Spacer(1, 6 * mm))
s.append(Paragraph("Reference B · the village (left: a house at dusk; right: the whole map)", h2))
s.append(img(D + "/cenario.jpg", 174 * mm))
s.append(Paragraph("Rio das Lanternas: river with red wooden bridges, Japanese houses with tiled roofs, water wheels, "
                   "lanterns, market stalls, two castles. The map is shown in daylight; the trailer is at dusk/night.", pq))
s.append(PageBreak())

for titulo, pra_que, imagem, movimento in PROMPTS:
    s.append(KeepTogether([
        Paragraph("PROMPT " + titulo, h2),
        Paragraph(pra_que, pq), Spacer(1, 2 * mm),
        Paragraph("<b>IMAGE</b>", txt), caixa(imagem), Spacer(1, 2 * mm),
        Paragraph("<b>MOTION</b> (para virar vídeo)", txt), caixa(movimento, colors.HexColor("#e6e3ef")),
        Spacer(1, 5 * mm)]))

doc.build(s)
