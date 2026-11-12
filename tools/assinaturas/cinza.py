#!/usr/bin/env python3
"""Converte os atlas gerados (RGBA) para PNG em tons de cinza de 8 bits."""
import os
from PIL import Image
PASTA = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "fx", "assinaturas")
for nome in ("selos.png", "pecas.png"):
    caminho = os.path.join(PASTA, nome)
    Image.open(caminho).convert("L").save(caminho, optimize=True)
    print(nome, os.path.getsize(caminho) // 1024, "KB")
