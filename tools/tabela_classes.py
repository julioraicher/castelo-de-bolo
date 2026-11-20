#!/usr/bin/env python3
"""Gera a tabela de Q/E/R por classe do CONTROLES.md a partir de config/classes/*.tres
(revisão 2026-11-19, DC-05: a tabela escrita à mão ficava para trás a cada classe nova).

Uso: python3 tools/tabela_classes.py        (reescreve o trecho entre os marcadores)
     python3 tools/tabela_classes.py --ver  (só imprime)
Ordem: classes do pátio (game_config.tres > hat_class_list), depois os caminhos e os
heróis de cada uma (campos caminhos/herois do .tres da base) e o Recruta no fim.
"""
import re
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
CLASSES = RAIZ / "config" / "classes"
ALVO = RAIZ / "CONTROLES.md"
INI, FIM = "<!-- tabela-classes:inicio -->", "<!-- tabela-classes:fim -->"


def ler(caminho: Path) -> dict:
    txt = caminho.read_text(encoding="utf-8")
    ext = dict(re.findall(r'\[ext_resource [^\]]*path="res://config/classes/([^"]+)\.tres"[^\]]*id="([^"]+)"', txt))
    ext = {v: k for k, v in ext.items()}  # id -> nome do arquivo
    d = {"_id": caminho.stem}
    for chave, valor in re.findall(r'^(\w+) = (.+)$', txt, re.M):
        if valor.startswith('"'):
            d[chave] = valor[1:-1].replace('\\"', '"')
        elif chave in ("herois", "caminhos"):
            d[chave] = [ext[i] for i in re.findall(r'ExtResource\("([^"]+)"\)', valor) if i in ext]
        else:
            d[chave] = valor
    return d


def padrao(gd: str, campo: str) -> str:
    m = re.search(rf'^@export\S*(?:\([^)]*\))? var {campo} := (.+)$', (RAIZ / "scripts" / "data" / gd).read_text(encoding="utf-8"), re.M)
    return m.group(1).strip() if m else "0"


def num(f: float) -> str:
    f = round(f, 1)
    return (str(int(f)) if f == int(f) else str(f)).replace(".", ",")


def recarga(c: dict, cfg: dict) -> str:
    # Mesma conta de ClassStats.recarga_q (cura usa heal_cooldown, armadilha trap_cooldown).
    campo = {"cura": "heal_cooldown", "armadilha": "trap_cooldown"}.get(c.get("skill", ""), "skill_cooldown")
    t = float(c.get(campo, padrao("class_stats.gd", campo)))
    t *= float(cfg.get("rapida_cooldown_mult", padrao("game_config.gd", "rapida_cooldown_mult")))
    if c.get("heroi", "false") == "true":
        t *= float(cfg.get("heroi_recarga_mult", padrao("game_config.gd", "heroi_recarga_mult")))
    return num(t)


def linha(c: dict, cfg: dict, bairro: str = "") -> str:
    nome = c.get("display_name", padrao("class_stats.gd", "display_name").strip('"')) + (f" ({bairro})" if bairro else "")
    if c.get("skill", "nenhum") == "nenhum":
        q = "(nada)"
    else:
        q = f"**{c.get('skill_name', '')}** ({recarga(c, cfg)} s): {c.get('skill_desc', '')}"
    e = "(nada)" if c.get("power", "nenhum") == "nenhum" else f"**{c.get('power_name', '')}**: {c.get('power_desc', '')}"
    tipo = c.get("super_tipo", "maior")
    if c.get("power", "nenhum") == "nenhum" and tipo == "maior":
        r = "(nada)"
    elif tipo == "proprio":
        r = f"**{c.get('super_nome', '')}**: {c.get('super_desc', '')}"
    elif tipo == "sombra":
        r = f"**{c.get('super_nome', 'Passo da Sombra')}**: some por uns segundos, mais rápido, e o golpe de surpresa dói mais"
    else:
        r = "o E em versão gigante"
    return f"| {nome} | {q} | {e} | {r} |"


def tabela() -> str:
    todas = {p.stem: ler(p) for p in sorted(CLASSES.glob("*.tres"))}
    cfg = (RAIZ / "config" / "game_config.tres").read_text(encoding="utf-8")
    valores = dict(re.findall(r'^(\w+) = (.+)$', cfg, re.M))
    ids = dict(re.findall(r'\[ext_resource [^\]]*path="res://config/classes/([^"]+)\.tres"[^\]]*id="([^"]+)"', cfg))
    ids = {v: k for k, v in ids.items()}
    lista = re.search(r'^hat_class_list = .*$', cfg, re.M).group(0)
    patio = [ids[i] for i in re.findall(r'ExtResource\("([^"]+)"\)', lista) if i in ids]
    feitas: list[str] = []
    out = ["| Classe | Q: rápido (recarga) | E: Chi (barra cheia) | R: Super (barra dourada) |",
           "|---|---|---|---|"]
    for b in patio:
        base = todas[b]
        out.append(linha(base, valores))
        feitas.append(b)
        bairro = base.get("display_name", b)
        for f in base.get("caminhos", []) + base.get("herois", []):
            if f in todas and f not in feitas:
                c = todas[f]
                rotulo = "herói, " + bairro if f in base.get("herois", []) else "caminho, " + bairro
                out.append(linha(c, valores, rotulo))
                feitas.append(f)
    for f, c in todas.items():
        if f not in feitas:
            out.append(linha(c, valores))
    return "\n".join(out)


def main() -> None:
    t = tabela()
    if "--ver" in sys.argv:
        print(t)
        return
    doc = ALVO.read_text(encoding="utf-8")
    if INI not in doc or FIM not in doc:
        sys.exit(f"Marcadores {INI} / {FIM} não estão em {ALVO.name}.")
    a, resto = doc.split(INI, 1)
    _, b = resto.split(FIM, 1)
    ALVO.write_text(f"{a}{INI}\n{t}\n{FIM}{b}", encoding="utf-8")
    print(f"{ALVO.name}: {t.count(chr(10)) - 1} classes.")


if __name__ == "__main__":
    main()
