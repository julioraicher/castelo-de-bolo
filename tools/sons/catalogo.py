"""Gera uma página HTML única (sons embutidos) para ouvir e escolher efeitos sonoros.

Uso: python3 tools/sons/catalogo.py [saida.html]
Lista: os sons atuais do jogo (assets/audio/*.ogg|wav) e toda a biblioteca
(assets/audio/biblioteca/**). Cada linha mostra o caminho pronto para colar em
tools/sons/trocar_som.sh. Padrão de saída: build/catalogo-sons.html.
"""
import base64
import html
import pathlib
import sys

RAIZ = pathlib.Path(__file__).resolve().parents[2]
AUD = RAIZ / "assets/audio"
MIME = {".ogg": "audio/ogg", ".wav": "audio/wav", ".mp3": "audio/mpeg"}


def linha(p: pathlib.Path) -> str:
    dados = base64.b64encode(p.read_bytes()).decode()
    rel = p.relative_to(RAIZ).as_posix()
    return (f'<div class="s" data-n="{html.escape(rel.lower())}"><code>{html.escape(rel)}</code>'
            f'<audio controls preload="none" src="data:{MIME[p.suffix]};base64,{dados}"></audio></div>')


def secao(titulo: str, arquivos: list) -> str:
    if not arquivos:
        return ""
    return f"<h2>{html.escape(titulo)} ({len(arquivos)})</h2>" + "".join(linha(a) for a in arquivos)


def main() -> None:
    saida = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else RAIZ / "build/catalogo-sons.html"
    saida.parent.mkdir(parents=True, exist_ok=True)
    jogo = sorted(p for p in AUD.iterdir() if p.suffix in MIME and p.stem != "music")
    partes = [secao("No jogo agora", jogo)]
    for pasta in sorted(d for d in (AUD / "biblioteca").rglob("*") if d.is_dir()):
        arqs = sorted(p for p in pasta.iterdir() if p.suffix in MIME)
        partes.append(secao(pasta.relative_to(AUD / "biblioteca").as_posix(), arqs))
    corpo = "".join(partes)
    saida.write_text(f"""<!DOCTYPE html><html lang="pt-BR"><meta charset="utf-8">
<title>Catálogo de sons</title><style>
body{{font:14px system-ui;background:#16131a;color:#eee;max-width:900px;margin:auto;padding:16px}}
h2{{color:#f0b35a;border-bottom:1px solid #444}} .s{{display:flex;gap:12px;align-items:center;margin:4px 0}}
code{{flex:1;font-size:12px;color:#bcd}} audio{{height:30px}} input{{width:100%;padding:8px;font-size:15px}}
</style><h1>Catálogo de sons</h1>
<p>Escolha pelo ouvido e mande o caminho: "hit = .../impact_punch_heavy_000.ogg".</p>
<input placeholder="filtrar (ex.: punch, metal, click)" oninput="for(const d of document.querySelectorAll('.s'))d.style.display=d.dataset.n.includes(this.value.toLowerCase())?'':'none'">
{corpo}</html>""", encoding="utf-8")
    print(saida, f"{saida.stat().st_size // 1024} KB")


if __name__ == "__main__":
    main()
