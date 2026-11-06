"""Gera um efeito sonoro por texto e salva na biblioteca (não mexe no jogo).

Uso:
  python3 tools/sons/gerar_ia.py <arquivo_saida_sem_ext> "<descrição em inglês>" [--seg=2] [--motor=stable|eleven]

Motores:
  stable  Stable Audio Open no Hugging Face (grátis). Precisa de HF_TOKEN nos segredos do
          ambiente (a cota anônima de GPU do Space costuma falhar). pip install gradio_client
  eleven  ElevenLabs Sound Effects (pago, melhor). Precisa de ELEVENLABS_API_KEY.

Saída: assets/audio/biblioteca/ia/<arquivo>.{wav|mp3}. Depois ouça no catálogo
(tools/sons/catalogo.py) e aplique com tools/sons/trocar_som.sh.
Dica de texto: "short, dry, close, game sound effect, no music, no reverb" + o objeto.
"""
import json
import os
import pathlib
import shutil
import sys
import urllib.request

RAIZ = pathlib.Path(__file__).resolve().parents[2]
SAIDA = RAIZ / "assets/audio/biblioteca/ia"
SPACE = "artificialguybr/Stable-Audio-Open-Zero"


def stable(texto: str, seg: float, destino: pathlib.Path) -> pathlib.Path:
    from gradio_client import Client  # pip install gradio_client
    cli = Client(SPACE, token=os.environ.get("HF_TOKEN"))
    arq = cli.predict(texto, seg, 100, 7, api_name="/predict")
    alvo = destino.with_suffix(pathlib.Path(arq).suffix or ".wav")
    shutil.copy(arq, alvo)
    return alvo


def eleven(texto: str, seg: float, destino: pathlib.Path) -> pathlib.Path:
    chave = os.environ.get("ELEVENLABS_API_KEY")
    if not chave:
        sys.exit("falta ELEVENLABS_API_KEY nos segredos do ambiente")
    corpo = json.dumps({"text": texto, "duration_seconds": seg, "prompt_influence": 0.5}).encode()
    req = urllib.request.Request("https://api.elevenlabs.io/v1/sound-generation", data=corpo,
                                 headers={"xi-api-key": chave, "Content-Type": "application/json"})
    alvo = destino.with_suffix(".mp3")
    with urllib.request.urlopen(req, timeout=120) as r:
        alvo.write_bytes(r.read())
    return alvo


def main() -> None:
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    opts = dict(a[2:].split("=", 1) for a in sys.argv[1:] if a.startswith("--") and "=" in a)
    if len(args) < 2:
        sys.exit(__doc__)
    SAIDA.mkdir(parents=True, exist_ok=True)
    motor = {"stable": stable, "eleven": eleven}[opts.get("motor", "stable")]
    alvo = motor(args[1], float(opts.get("seg", 2)), SAIDA / args[0])
    print(alvo.relative_to(RAIZ))


if __name__ == "__main__":
    main()
