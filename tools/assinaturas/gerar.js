// Gera os atlas de campo de distância (SDF) das assinaturas:
//   assets/fx/assinaturas/selos.png (7x7 células de 256: 26 selos + 22 figuras)
//   assets/fx/assinaturas/pecas.png (5x5 células de 96: partículas)
// Uso: node tools/assinaturas/gerar.js [--prancha arquivo.png]
// Cada desenho (desenhos.js) é pintado grande num canvas, vira máscara e a
// distância até a borda (EDT de Felzenszwalb) é guardada em cinza: 0,5 = borda,
// claro = dentro. O shader desenha traço, filete e brilho a partir disso, nítido
// em qualquer tamanho. Depois de gerar: tools/assinaturas/cinza.py (PNG em 8 bits).
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');
const { SELOS, FIGURAS, PECAS } = require('./desenhos.js');

const RAIZ = path.resolve(__dirname, '../..');
const SAIDA = path.join(RAIZ, 'assets/fx/assinaturas');

async function main() {
  fs.mkdirSync(SAIDA, { recursive: true });
  const browser = await chromium.launch();
  const page = await browser.newPage();
  const atlas = async (lista, vb, margem, cel, cols, lins, espalha) => page.evaluate(async ({ lista, vb, margem, cel, cols, lins, espalha }) => {
    const K = 4, G = cel * K, INF = 1e20;
    const edt1 = (f, n) => {
      const d = new Float64Array(n), v = new Int32Array(n), z = new Float64Array(n + 1);
      let k = 0; v[0] = 0; z[0] = -INF; z[1] = INF;
      for (let q = 1; q < n; q++) {
        let s;
        do { const p = v[k]; s = ((f[q] + q * q) - (f[p] + p * p)) / (2 * q - 2 * p); } while (s <= z[k] && --k >= 0);
        k++; v[k] = q; z[k] = s; z[k + 1] = INF;
      }
      k = 0;
      for (let q = 0; q < n; q++) { while (z[k + 1] < q) k++; const p = v[k]; d[q] = (q - p) * (q - p) + f[p]; }
      return d;
    };
    const edt = (dentro, n) => {  // distância (px) até o pixel "dentro" mais próximo
      const g = new Float64Array(n * n);
      for (let i = 0; i < n * n; i++) g[i] = dentro[i] ? 0 : INF;
      const col = new Float64Array(n);
      for (let x = 0; x < n; x++) { for (let y = 0; y < n; y++) col[y] = g[y * n + x]; const d = edt1(col, n); for (let y = 0; y < n; y++) g[y * n + x] = d[y]; }
      for (let y = 0; y < n; y++) { const d = edt1(g.subarray(y * n, y * n + n), n); for (let x = 0; x < n; x++) g[y * n + x] = Math.sqrt(d[x]); }
      return g;
    };
    const out = document.createElement('canvas'); out.width = cel * cols; out.height = cel * lins;
    const octx = out.getContext('2d'); octx.fillStyle = '#000'; octx.fillRect(0, 0, out.width, out.height);
    const c = document.createElement('canvas'); c.width = G; c.height = G;
    const ctx = c.getContext('2d', { willReadFrequently: true });
    for (let i = 0; i < lista.length; i++) {
      const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${G}" height="${G}" viewBox="${-margem} ${-margem} ${vb + 2 * margem} ${vb + 2 * margem}">${lista[i]}</svg>`;
      const img = new Image();
      await new Promise((ok, erro) => { img.onload = ok; img.onerror = erro; img.src = 'data:image/svg+xml;charset=utf-8,' + encodeURIComponent(svg); });
      ctx.clearRect(0, 0, G, G); ctx.drawImage(img, 0, 0);
      const px = ctx.getImageData(0, 0, G, G).data;
      const dentro = new Uint8Array(G * G), fora = new Uint8Array(G * G);
      for (let j = 0; j < G * G; j++) { const on = px[j * 4] * px[j * 4 + 3] > 127 * 255; dentro[j] = on ? 1 : 0; fora[j] = on ? 0 : 1; }
      const dd = edt(dentro, G), df = edt(fora, G);  // dd: fora -> distância até a tinta; df: dentro -> até a borda
      const cell = octx.createImageData(cel, cel);
      const esp = espalha * K;
      for (let y = 0; y < cel; y++) for (let x = 0; x < cel; x++) {
        let s = 0;
        for (let b = 0; b < K; b++) for (let a = 0; a < K; a++) { const j = (y * K + b) * G + x * K + a; s += df[j] - dd[j]; }
        const v = Math.max(0, Math.min(255, Math.round(255 * (0.5 + (s / (K * K)) / (2 * esp)))));
        const o = (y * cel + x) * 4; cell.data[o] = cell.data[o + 1] = cell.data[o + 2] = v; cell.data[o + 3] = 255;
      }
      octx.putImageData(cell, (i % cols) * cel, Math.floor(i / cols) * cel);
    }
    return out.toDataURL('image/png');
  }, { lista, vb, margem, cel, cols, lins, espalha });

  const grava = (nome, url) => fs.writeFileSync(path.join(SAIDA, nome), Buffer.from(url.split(',')[1], 'base64'));
  const selos = [...Object.values(SELOS), ...Object.values(FIGURAS)];
  grava('selos.png', await atlas(selos, 120, 10, 256, 7, 7, 14));
  grava('pecas.png', await atlas(Object.values(PECAS), 40, 5, 96, 5, 5, 9));
  console.log('selos:', Object.keys(SELOS).join(' '));
  console.log('figuras:', Object.keys(FIGURAS).join(' '));
  console.log('pecas:', Object.keys(PECAS).join(' '));

  const i = process.argv.indexOf('--prancha');
  if (i > 0) {  // folha de conferência: os desenhos em branco sobre escuro, com o nome
    const nomes = [...Object.keys(SELOS), ...Object.keys(FIGURAS), ...Object.keys(PECAS).map(n => 'p:' + n)];
    const svgs = [...selos.map(s => [s, 120]), ...Object.values(PECAS).map(s => [s, 40])];
    await page.setViewportSize({ width: 1240, height: 1000 });
    await page.setContent(`<body style="margin:0;background:#191522;display:grid;grid-template-columns:repeat(10,1fr);gap:4px;padding:6px;font:11px sans-serif;color:#cbb">`
      + svgs.map(([s, vb], k) => `<div style="text-align:center"><svg viewBox="0 0 ${vb} ${vb}" width="112" height="112" style="background:#000">${s}</svg><br>${k} ${nomes[k]}</div>`).join('') + '</body>');
    await page.screenshot({ path: process.argv[i + 1], fullPage: true });
  }
  await browser.close();
}
main().catch(e => { console.error(e); process.exit(1); });
