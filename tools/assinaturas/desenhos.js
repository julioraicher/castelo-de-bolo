// Desenhos das assinaturas (Ciclo 2.24): branco = tinta, preto = corte.
// SELOS e FIGURAS em viewBox 0..120 (centro 60,60); PECAS em 0..40.
// A ordem das listas é o índice da célula no atlas (ver scripts/fx/assinatura.gd).
const W = 'fill="#fff"';
const K = 'fill="#000"';
const S = (w, x = '') => `fill="none" stroke="#fff" stroke-width="${w}" stroke-linecap="round" stroke-linejoin="round" ${x}`;
const SK = (w, x = '') => `fill="none" stroke="#000" stroke-width="${w}" stroke-linecap="round" stroke-linejoin="round" ${x}`;
const ring = (r, w, x = '') => `<circle cx="60" cy="60" r="${r}" ${S(w, x)}/>`;
const around = (n, fn, a0 = 0) => Array.from({ length: n }, (_, i) =>
  `<g transform="rotate(${(a0 + i * 360 / n).toFixed(2)} 60 60)">${fn(i)}</g>`).join('');
const star = (n, R, r, rot = -90, cx = 60, cy = 60) => Array.from({ length: n * 2 }, (_, i) => {
  const a = (rot + i * 180 / n) * Math.PI / 180, q = i % 2 ? r : R;
  return `${(cx + Math.cos(a) * q).toFixed(1)},${(cy + Math.sin(a) * q).toFixed(1)}`;
}).join(' ');
const espelho = s => s + `<g transform="translate(120 0) scale(-1 1)">${s}</g>`;
const FOLHA = '0,-18 3,-9 11,-14 9,-4 18,-2 10,4 13,12 3,8 0,18 -3,8 -13,12 -10,4 -18,-2 -9,-4 -11,-14 -3,-9';
const GROU = '<polygon points="20,70 60,58 100,70 60,84" ' + W + '/><polygon points="60,60 42,12 74,52" ' + W + '/><polygon points="64,60 96,20 80,58" ' + W + '/><polygon points="24,72 8,42 0,50 9,52 12,68" ' + W + '/><polygon points="98,68 118,50 104,76" ' + W + '/><path d="M60 58 L60 84 M20 70 L100 70" ' + SK(1.6) + '/>';

const SELOS = {};
// Samurai: ensō (círculo de pincel aberto) e duas katanas cruzadas.
SELOS.guerreiro = `<path d="M70 9 A52 52 0 1 1 22 26" ${S(7)}/><path d="M22 26 Q28 17 40 12" ${S(3.5)}/>`
  + espelho(`<line x1="24" y1="96" x2="38" y2="82" ${S(8)}/><line x1="38" y1="82" x2="94" y2="26" ${S(4.5)}/><line x1="32" y1="76" x2="44" y2="88" ${S(4.5)}/>`);
// Ronin Oni: chifres, olhos, presas e o chão rachando para fora (sem anel).
SELOS.ronin_oni = espelho(`<path d="M38 54 Q24 26 42 8 Q42 32 54 48Z" ${W}/><path d="M38 60 L55 67 L41 71Z" ${W}/><path d="M47 84 L52 100 L57 84Z" ${W}/>`)
  + `<path d="M38 82 Q60 92 82 82" ${S(4.5)}/>`
  + `<path d="M24 62 L12 54 L3 63 M96 62 L109 68 L117 58 M60 104 L55 111 L62 118 M30 92 L19 100 L11 95 M90 92 L101 103 L110 98" ${S(3.5)}/>`;
// Sohei: rosário de contas (o anel É o rosário) em volta do sino do templo.
SELOS.sohei = around(18, i => `<circle cx="60" cy="11" r="${i % 9 === 0 ? 6.5 : 4.4}" ${W}/>`)
  + `<path d="M60 30 Q44 34 44 58 L40 78 L80 78 L76 58 Q76 34 60 30Z" ${S(4.5)}/><path d="M46 62 L74 62" ${S(3)}/><path d="M55 30 Q60 20 65 30" ${S(3.5)}/><circle cx="60" cy="86" r="5" ${W}/>`;
// Ninja de Shuriken: shuriken de 4 pontas com furo, entre tufos de fumaça.
SELOS.arqueiro = `<polygon points="${star(4, 52, 13)}" ${W}/><circle cx="60" cy="60" r="8" ${K}/><polygon points="${star(4, 30, 7)}" ${SK(2)}/>`
  + `<g ${W}><circle cx="22" cy="24" r="8"/><circle cx="31" cy="19" r="6"/><circle cx="17" cy="33" r="5"/><circle cx="98" cy="96" r="8"/><circle cx="89" cy="101" r="6"/><circle cx="103" cy="87" r="5"/><circle cx="97" cy="22" r="6"/><circle cx="23" cy="98" r="6"/></g>`;
// Arqueiro Yumi: alvo com olho e marcas de mira.
SELOS.arqueiro_yumi = ring(46, 3.5) + ring(31, 3)
  + `<path d="M38 60 Q60 40 82 60 Q60 80 38 60Z" ${S(4)}/><circle cx="60" cy="60" r="7.5" ${W}/>`
  + around(4, () => `<line x1="60" y1="3" x2="60" y2="17" ${S(4.5)}/>`);
// Kusarigama: os elos da corrente fazem o anel; a foice no meio.
SELOS.kusarigama = around(14, i => i % 2 === 0 ? `<ellipse cx="60" cy="13" rx="9.5" ry="5.5" ${S(3.4)}/>` : `<line x1="52" y1="13" x2="68" y2="13" ${S(4.2)}/>`)
  + `<line x1="46" y1="88" x2="66" y2="44" ${S(5.5)}/><path d="M64 42 Q94 30 100 62 Q86 46 64 53Z" ${W}/><circle cx="41" cy="42" r="6.5" ${W}/>`;
// Kitsune: pata de raposa e três fogos-fátuos.
SELOS.kitsune = `<g ${W}><ellipse cx="60" cy="74" rx="19" ry="15"/><ellipse cx="35" cy="54" rx="8" ry="10"/><ellipse cx="51" cy="40" rx="8" ry="10.5"/><ellipse cx="69" cy="40" rx="8" ry="10.5"/><ellipse cx="85" cy="54" rx="8" ry="10"/></g>`
  + around(3, () => `<path d="M60 0 Q71 12 64 21 Q56 24 55 16 Q55 8 60 0Z" ${W}/>`, 60)
  + around(9, i => i % 3 === 0 ? '' : `<circle cx="60" cy="8" r="2.6" ${W}/>`, 20);
// Kitsune da Luz: lótus de 8 pétalas dentro de um anel liso.
SELOS.kitsune_luz = ring(53, 4.5) + ring(45, 2.4)
  + around(8, () => `<path d="M60 19 Q73 38 60 54 Q47 38 60 19Z" ${S(3.2)}/>`)
  + around(8, () => `<path d="M60 36 Q67 46 60 55 Q53 46 60 36Z" ${W}/>`, 22.5)
  + `<circle cx="60" cy="60" r="6" ${W}/>`;
// Kitsune Sombria: coroa em ziguezague e dois olhos.
SELOS.kitsune_sombria = `<polygon points="${star(9, 55, 37)}" ${S(4.5)}/>`
  + espelho(`<path d="M34 60 Q45 48 57 63 Q45 67 34 60Z" ${W}/><ellipse cx="46" cy="59" rx="2" ry="5" ${K}/>`)
  + `<path d="M60 78 L64 86 L60 94 L56 86Z" ${W}/>`;
// Construtor: planta de carpinteiro (quadrada): esquadro, compasso e régua.
SELOS.construtor = `<rect x="12" y="12" width="96" height="96" ${S(4.5)}/>`
  + `<path d="M4 12 H12 M12 4 V12 M108 4 V12 M108 12 H116 M4 108 H12 M12 108 V116 M108 108 H116 M108 108 V116" ${S(3)}/>`
  + `<path d="M26 26 L26 94 L94 94 L94 80 L40 80 L40 26Z" ${S(3.6)}/>`
  + `<circle cx="74" cy="48" r="15" ${S(3, 'stroke-dasharray="7 5"')}/><path d="M74 42 V54 M68 48 H80" ${S(2.6)}/>`
  + Array.from({ length: 7 }, (_, i) => `<line x1="${24 + i * 12}" y1="12" x2="${24 + i * 12}" y2="${i % 2 ? 17 : 20}" ${S(2.4)}/>`).join('');
// Armadilheiro: mandíbula de armadilha vista de cima, dentes para dentro.
SELOS.armadilheiro = `<path d="M14 53 A47 47 0 0 1 106 53" ${S(5)}/><path d="M14 67 A47 47 0 0 0 106 67" ${S(5)}/>`
  + [-56, -28, 0, 28, 56, 124, 152, 180, 208, 236].map(a => `<polygon points="54,13 66,13 60,34" transform="rotate(${a} 60 60)" ${W}/>`).join('')
  + `<rect x="2" y="54" width="14" height="12" ${W}/><rect x="104" y="54" width="14" height="12" ${W}/>`
  + `<circle cx="60" cy="60" r="11" ${S(4)}/><circle cx="60" cy="60" r="3.5" ${W}/>`;
// Bombardeiro: pavio em espiral queimando até a bomba no meio.
SELOS.bombardeiro = `<polyline points="${Array.from({ length: 90 }, (_, i) => { const t = i / 89, a = t * 2.4 * 2 * Math.PI, r = 50 - t * 36; return `${(60 + Math.cos(a) * r).toFixed(1)},${(60 + Math.sin(a) * r).toFixed(1)}`; }).join(' ')}" ${S(4)}/>`
  + `<circle cx="60" cy="60" r="12" ${W}/><rect x="56" y="43" width="8" height="7" ${W}/><circle cx="56" cy="56" r="3" ${K}/>`
  + `<polygon points="${star(8, 10, 4, 0, 108, 58)}" ${W}/>`;
// Sumotori: corda shimenawa grossa, cinco papéis shide e as duas linhas do dohyō.
SELOS.sumotori = `<circle cx="60" cy="60" r="41" fill="none" stroke="#fff" stroke-width="9" stroke-dasharray="10.5 2.4"/>`
  + around(5, () => `<path d="M56 15 L64 15 L58 9 L66 9 L61 2" ${S(3)}/>`, 36)
  + `<rect x="50" y="52" width="20" height="4.5" ${W}/><rect x="50" y="63.5" width="20" height="4.5" ${W}/>`
  + `<g ${W}>${Array.from({ length: 16 }, (_, i) => `<circle cx="${(60 + Math.cos(i * 2.4) * (14 + i * 1.1)).toFixed(1)}" cy="${(60 + Math.sin(i * 2.4) * (14 + i * 1.1)).toFixed(1)}" r="2.1"/>`).join('')}</g>`;
// Kappa: ondas quebradas em volta do prato d'água.
SELOS.kappa = ring(52, 3.6, 'stroke-dasharray="46 14"') + ring(39, 3.6, 'stroke-dasharray="30 11" transform="rotate(40 60 60)"') + ring(26, 3.2, 'stroke-dasharray="22 9" transform="rotate(110 60 60)"')
  + `<ellipse cx="60" cy="60" rx="13" ry="8" ${S(3.6)}/><path d="M52 60 Q56 56 60 60 T68 60" ${S(2.4)}/>`
  + around(3, () => `<path d="M60 2 Q65 9 60 12 Q55 9 60 2Z" ${W}/>`, 25);
// Yamabushi: folhas de bordo num redemoinho (sem anel).
SELOS.yamabushi = Array.from({ length: 7 }, (_, k) => `<g transform="rotate(${k * 52} 60 60) translate(60 ${15 + k * 4.4}) rotate(${35 + k * 20}) scale(${(0.72 - k * 0.05).toFixed(2)})"><polygon points="${FOLHA}" ${W}/><line x1="0" y1="14" x2="0" y2="26" ${S(3)}/></g>`).join('')
  + `<polyline points="${Array.from({ length: 40 }, (_, i) => { const t = i / 39, a = (t * 1.3 * 360 - 90) * Math.PI / 180, r = 3 + t * 15; return `${(60 + Math.cos(a) * r).toFixed(1)},${(60 + Math.sin(a) * r).toFixed(1)}`; }).join(' ')}" ${S(3.4)}/>`;
// Karasu Tengu: cata-vento de nove penas pretas.
SELOS.karasu_tengu = around(9, () => `<path d="M60 48 Q72 36 69 24 L64 27 L68 15 L63 4 Q49 26 60 48Z" ${W}/><path d="M61 46 Q60 26 63 8" ${SK(1.6)}/>`)
  + `<circle cx="60" cy="60" r="6.5" ${W}/>`;
// Mujina: rosto liso (oval) rachando, com cacos em volta.
SELOS.mujina = `<ellipse cx="60" cy="60" rx="33" ry="43" ${S(5)}/>`
  + `<path d="M63 18 L56 34 L67 47 L58 62 L64 76" ${S(3.2)}/><path d="M28 56 L42 54 L49 63" ${S(2.8)}/><path d="M92 70 L80 72 L75 82" ${S(2.8)}/>`
  + `<polygon points="8,14 22,10 14,26" ${W}/><polygon points="104,8 114,20 100,22" ${W}/><polygon points="6,96 18,104 8,112" ${W}/><polygon points="100,98 114,96 108,112" ${W}/>`;
// Onmyoji: estrela de Seimei (a única de 5 pontas) com cinco talismãs.
SELOS.onmyoji = ring(39, 3.4)
  + `<polygon points="${[0, 2, 4, 1, 3].map(i => { const a = (-90 + i * 72) * Math.PI / 180; return `${(60 + Math.cos(a) * 39).toFixed(1)},${(60 + Math.sin(a) * 39).toFixed(1)}`; }).join(' ')}" ${S(3.4)}/>`
  + around(5, () => `<rect x="53.5" y="1.5" width="13" height="17" ${S(2.8)}/><line x1="60" y1="6" x2="60" y2="14" ${S(2.2)}/>`);
// Tennin: duas fitas em espiral e nuvens.
SELOS.tennin = `<path d="M60 60 C60 30 96 30 96 56 C96 84 52 90 36 70 C22 52 34 22 62 16" ${S(5.5)}/><path d="M60 60 C60 90 24 90 24 64 C24 36 68 30 84 50 C98 68 86 98 58 104" ${S(3.6)}/>`
  + `<g ${W}><circle cx="16" cy="24" r="6"/><circle cx="25" cy="19" r="7.5"/><circle cx="34" cy="13" r="5"/><circle cx="102" cy="98" r="6"/><circle cx="93" cy="103" r="7.5"/><circle cx="84" cy="108" r="5"/></g>`;
// Komusō: cesto trançado no meio e ondas de som dos dois lados.
SELOS.komuso = `<circle cx="60" cy="60" r="19" ${S(4)}/><path d="M46 50 H74 M43 60 H77 M46 70 H74 M50 44 V76 M60 41 V79 M70 44 V76" ${S(2.4)}/>`
  + espelho(`<path d="M34 42 A31 31 0 0 0 34 78" ${S(4.2)}/><path d="M24 34 A44 44 0 0 0 24 86" ${S(3.8)}/><path d="M13 27 A56 56 0 0 0 13 93" ${S(3.4)}/>`)
  + `<ellipse cx="54" cy="16" rx="5.5" ry="4.2" transform="rotate(-20 54 16)" ${W}/><path d="M59 15 V2 Q66 4 66 10" ${S(2.6)}/><ellipse cx="62" cy="108" rx="5.5" ry="4.2" transform="rotate(-20 62 108)" ${W}/><path d="M67 107 V94 Q74 96 74 102" ${S(2.6)}/>`;

// --- Heróis 2.27 ---
// Flecha (haste + penas) cravada: ponta em (x,y), entrando no ângulo `a` (graus).
const flechaCravada = (x, y, a, comp = 34) => `<g transform="translate(${x} ${y}) rotate(${a})"><line x1="0" y1="0" x2="${comp}" y2="0" ${S(3.2)}/>`
  + `<polygon points="${comp - 9},0 ${comp + 2},-7 ${comp + 4},-2" ${W}/><polygon points="${comp - 9},0 ${comp + 2},7 ${comp + 4},2" ${W}/></g>`;
// Ochimusha: ensō partido (o círculo de pincel rachado e com um pedaço solto)
// com três flechas cravadas.
SELOS.ochimusha = `<path d="M70 21 A40 40 0 1 1 26 38" ${S(8)}/><path d="M84 28 A40 40 0 0 1 99 52" ${S(8)}/>`
  + `<path d="M22 70 L31 66 L28 75 L37 73" ${SK(3.2)}/><path d="M64 99 L60 92 L68 89 L64 82" ${SK(3.2)}/>`
  + [-150, -20, 75, 140].map((a, k) => { const r = a * Math.PI / 180; return flechaCravada((60 + Math.cos(r) * 37).toFixed(1), (60 + Math.sin(r) * 37).toFixed(1), a, k % 2 ? 22 : 18); }).join('')
  + `<g ${W}><circle cx="60" cy="60" r="6"/><circle cx="49" cy="69" r="3.2"/><circle cx="71" cy="70" r="2.6"/><circle cx="64" cy="47" r="2"/></g>`;
// Shishimai: cabeça de leão de frente, juba em chamas (estrela de 14 pontas) e nuvens.
SELOS.shishimai = `<polygon points="${star(14, 56, 43)}" ${W}/><circle cx="60" cy="60" r="41" ${K}/>`
  + `<path d="M31 52 Q31 28 60 28 Q89 28 89 52 Q90 80 60 90 Q30 80 31 52Z" ${S(4.5)}/>`
  + espelho(`<circle cx="47" cy="50" r="7" ${W}/><circle cx="48" cy="51" r="3" ${K}/><path d="M36 40 Q44 33 55 38" ${S(4)}/>`)
  + `<path d="M52 60 Q60 55 68 60 Q66 68 60 68 Q54 68 52 60Z" ${W}/><path d="M40 73 Q60 86 80 73" ${S(4)}/>`
  + `<g ${W}>${[45, 53, 61, 69].map(x => `<polygon points="${x},76 ${x + 6},76 ${x + 3},83"/>`).join('')}<circle cx="60" cy="18" r="4"/></g>`;
// Jorogumo: teia de oito raios com espiral que cede entre eles e a aranha no meio.
SELOS.jorogumo = around(8, () => `<line x1="60" y1="60" x2="60" y2="3" ${S(2.4)}/>`)
  + [17, 29, 41, 53].map(r => `<path d="${Array.from({ length: 8 }, (_, i) => { const a0 = (i * 45 - 90) * Math.PI / 180, a1 = ((i + 1) * 45 - 90) * Math.PI / 180, am = (a0 + a1) / 2;
    return `${i ? '' : `M${(60 + Math.cos(a0) * r).toFixed(1)} ${(60 + Math.sin(a0) * r).toFixed(1)} `}Q${(60 + Math.cos(am) * r * 0.82).toFixed(1)} ${(60 + Math.sin(am) * r * 0.82).toFixed(1)} ${(60 + Math.cos(a1) * r).toFixed(1)} ${(60 + Math.sin(a1) * r).toFixed(1)}`; }).join(' ')}" ${S(2.2)}/>`).join('')
  + `<circle cx="60" cy="62" r="17" ${K}/>`
  + espelho(`<path d="M54 56 Q40 44 36 50 M53 61 Q38 58 34 66 M54 66 Q42 72 40 80 M56 70 Q48 80 50 88" ${S(3)}/>`)
  + `<ellipse cx="60" cy="68" rx="8" ry="10" ${W}/><circle cx="60" cy="54" r="5.5" ${W}/><path d="M57 64 L63 64 L60 69 L63 74 L57 74 L60 69Z" ${K}/>`;
// Kodama do Shinboku: anéis de tronco cortado (tortos) com a rachadura e a folha brotando.
SELOS.kodama = [50, 40, 31, 22, 13].map((r, i) => `<path d="${Array.from({ length: 33 }, (_, k) => { const a = k / 32 * 2 * Math.PI, rr = r + Math.sin(a * 3 + i) * 1.8 + Math.sin(a * 5 + i * 2) * 1.2;
    return `${k ? 'L' : 'M'}${(60 + Math.cos(a) * rr).toFixed(1)} ${(62 + Math.sin(a) * rr * 0.92).toFixed(1)}`; }).join(' ')}Z" ${S(i === 0 ? 5 : 2.6)}/>`).join('')
  + `<path d="M60 62 L72 74 L70 86 L82 100" ${SK(3)}/><circle cx="60" cy="62" r="4" ${W}/>`
  + `<path d="M58 14 Q46 2 30 6 Q36 20 58 16Z" ${W}/><path d="M62 14 Q76 0 92 6 Q84 20 62 16Z" ${W}/><path d="M60 16 V6" ${S(3)}/>`;
// Kaminari-kozō: anel de oito tambores (cada um com o redemoinho tomoe) e o raio no meio.
SELOS.kaminari_kozo = around(8, () => `<circle cx="60" cy="13" r="9.5" ${W}/><path d="M60 7 Q66 10 62 14 Q58 17 60 20" ${SK(2.2)}/><circle cx="60" cy="13" r="9.5" ${SK(1.6)}/>`)
  + `<path d="M60 22 L60 31 M60 98 L60 89" ${S(2.4)}/>`
  + `<polygon points="66,26 44,64 58,64 50,96 78,52 63,52 72,26" ${W}/>`;

// --- Herói 2.30 ---
// Garrafa de pé centrada em (60,60), do gargalo (y 8) ao fundo (y 112).
const GARRAFA = `<path d="M54 8 H66 V34 Q76 40 76 54 V104 Q76 112 68 112 H52 Q44 112 44 104 V54 Q44 40 54 34Z" ${W}/>`;
// Predero: capacete de obra na frente de duas garrafas cruzadas (o "brasão" da obra).
SELOS.predero = [-34, 34].map(a => `<g transform="rotate(${a} 60 70) translate(60 58) scale(0.98) translate(-60 -60)">${GARRAFA}<rect x="48" y="62" width="24" height="22" ${K}/><path d="M53 6 H67" ${S(5)}/></g>`).join('')
  + `<path d="M24 86 Q24 42 60 42 Q96 42 96 86Z" ${W} stroke="#000" stroke-width="6"/><rect x="12" y="82" width="96" height="12" rx="5" ${W} stroke="#000" stroke-width="5"/>`
  + `<path d="M52 46 Q50 64 52 82 M68 46 Q70 64 68 82" ${SK(3.4)}/><polygon points="${star(5, 8, 3.4, -90, 36, 70)}" ${K}/>`;

const FIGURAS = {};
FIGURAS.pincelada = `<path d="M3 64 Q30 42 70 52 Q100 58 117 48 L111 57 L118 61 Q90 74 60 69 Q30 66 9 77 L14 67Z" ${W}/><circle cx="8" cy="50" r="2.5" ${W}/><circle cx="104" cy="74" r="3" ${W}/><circle cx="114" cy="70" r="1.8" ${W}/><path d="M24 62 Q60 54 100 60" ${SK(1.4)}/>`;
FIGURAS.oni = `<path d="M30 40 Q30 22 60 22 Q90 22 90 40 L93 70 Q90 100 60 108 Q30 100 27 70Z" ${W}/>`
  + espelho(`<path d="M34 34 Q18 14 26 0 Q34 14 48 24Z" ${W}/><path d="M36 48 L55 58 L40 64Z" ${K}/><path d="M34 44 L54 52" ${SK(3)}/>`)
  + `<path d="M38 78 Q60 68 82 78 Q78 98 60 100 Q42 98 38 78Z" ${K}/>`
  + espelho(`<path d="M44 76 L49 92 L54 75Z" ${W}/>`) + `<path d="M55 62 Q60 68 65 62" ${SK(2.4)}/>`;
FIGURAS.sino = `<path d="M40 32 Q40 18 60 18 Q80 18 80 32 L86 88 Q86 96 60 96 Q34 96 34 88Z" ${W}/><path d="M51 19 Q60 2 69 19" ${S(5.5)}/><line x1="28" y1="99" x2="92" y2="99" ${S(6)}/>`
  + `<path d="M39 42 H81 M36 78 H84" ${SK(3)}/><circle cx="60" cy="60" r="7.5" ${K}/><circle cx="60" cy="60" r="3" ${W}/><path d="M48 46 V74 M72 46 V74" ${SK(1.8)}/>`
  + `<circle cx="60" cy="110" r="5" ${W}/>`;
FIGURAS.sombra = `<circle cx="58" cy="22" r="12" ${W}/><polygon points="68,22 98,12 93,21 108,24 70,32" ${W}/><polygon points="46,36 72,36 80,74 40,74" ${W}/><polygon points="40,74 24,112 38,114 56,82 64,82 82,114 96,112 80,74" ${W}/><polygon points="47,40 20,58 25,66 50,52" ${W}/><polygon points="71,40 100,52 96,60 70,52" ${W}/><line x1="96" y1="56" x2="116" y2="36" ${S(3.5)}/><path d="M48 20 H68" ${SK(3.5)}/>`;
FIGURAS.olho = `<path d="M5 60 Q60 12 115 60 Q60 108 5 60Z" ${S(6.5)}/><circle cx="60" cy="60" r="22" ${S(5.5)}/><circle cx="60" cy="60" r="9.5" ${W}/>`
  + `<g transform="translate(0 0)">${[-48, -32, -16, 0, 16, 32, 48].map(a => `<line x1="60" y1="${a % 32 === 0 ? 6 : 12}" x2="60" y2="${a % 32 === 0 ? 16 : 20}" transform="rotate(${a} 60 96)" ${S(3.5)}/>`).join('')}</g>`;
FIGURAS.raposa = `<path d="M22 14 L46 38 Q60 32 74 38 L98 14 L96 60 Q90 92 60 108 Q30 92 24 60Z" ${W}/>`
  + espelho(`<path d="M35 58 Q46 48 55 63 Q45 66 35 58Z" ${K}/><path d="M30 76 L46 80 M32 84 L46 85" ${SK(2.6)}/><polygon points="30,26 42,40 32,42" ${K}/>`)
  + `<path d="M55 90 L65 90 L60 97Z" ${K}/><path d="M60 40 L65 49 L60 57 L55 49Z" ${K}/>`;
FIGURAS.olhos = espelho(`<path d="M6 60 Q30 34 55 64 Q30 74 6 60Z" ${W}/><ellipse cx="32" cy="58" rx="3.2" ry="10" ${K}/>`);
FIGURAS.andaime = `<path d="M24 6 V116 M96 6 V116" ${S(6.5)}/><path d="M14 28 H106 M14 64 H106 M14 100 H106" ${S(5)}/><path d="M24 28 L96 64 M96 28 L24 64 M24 64 L96 100 M96 64 L24 100" ${S(3.2)}/>`
  + `<g ${W}><circle cx="24" cy="28" r="6"/><circle cx="96" cy="28" r="6"/><circle cx="24" cy="64" r="6"/><circle cx="96" cy="64" r="6"/><circle cx="24" cy="100" r="6"/><circle cx="96" cy="100" r="6"/></g><polygon points="24,6 44,12 24,19" ${W}/>`;
FIGURAS.explosao = `<polygon points="${Array.from({ length: 24 }, (_, i) => { const a = (i * 15 - 90) * Math.PI / 180, r = i % 2 ? 31 + (i % 3) * 3 : 57 - (i % 4) * 4; return `${(60 + Math.cos(a) * r).toFixed(1)},${(60 + Math.sin(a) * r).toFixed(1)}`; }).join(' ')}" ${W}/><polygon points="${star(10, 30, 17, -72)}" ${K}/><polygon points="${star(8, 15, 8)}" ${W}/>`;
FIGURAS.leque = '<g transform="translate(60 66) scale(0.84) translate(-60 -66)">' + [-72, -48, -24, 0, 24, 48, 72].map(a => `<g transform="rotate(${a} 60 92)"><path d="M60 78 Q73 52 66 26 L62 30 L60 12 Q46 50 60 78Z" ${W}/><path d="M60 76 V20" ${SK(1.6)}/></g>`).join('')
  + `<circle cx="60" cy="92" r="8" ${W}/><line x1="60" y1="96" x2="60" y2="116" ${S(6.5)}/>` + '</g>';
FIGURAS.asas = espelho(`<path d="M57 56 Q34 14 2 18 Q13 28 9 40 Q19 40 18 53 Q27 51 28 64 Q37 60 40 73 Q49 67 57 78Z" ${W}/><path d="M52 60 Q34 34 14 28 M50 66 Q36 48 22 46 M50 71 Q42 60 32 58" ${SK(1.8)}/>`)
  + `<ellipse cx="60" cy="64" rx="5" ry="14" ${W}/>`;
FIGURAS.rosto = `<ellipse cx="60" cy="60" rx="35" ry="47" ${W}/><path d="M63 13 L55 34 L67 49 L57 66 L64 84 L58 107" ${SK(3)}/><path d="M25 54 L41 52 L49 63 M95 72 L81 73 L74 84 M57 66 L44 74" ${SK(2.4)}/>`;
FIGURAS.grou = GROU;
FIGURAS.nota = `<ellipse cx="34" cy="94" rx="14" ry="10.5" transform="rotate(-20 34 94)" ${W}/><ellipse cx="86" cy="82" rx="14" ry="10.5" transform="rotate(-20 86 82)" ${W}/><path d="M46 92 V26 M98 80 V14" ${S(5.5)}/><polygon points="46,20 98,8 98,24 46,36" ${W}/>`;
FIGURAS.halo = ring(38, 6) + ring(27, 2.6) + around(16, i => `<line x1="60" y1="${i % 2 ? 9 : 3}" x2="60" y2="15" ${S(3.6)}/>`);
FIGURAS.shide = `<polygon points="42,4 82,4 64,34 90,34 68,68 94,68 58,116 68,80 44,80 62,46 38,46 56,16 42,16" ${W}/><path d="M56 16 L72 16 M62 46 L80 46 M68 80 L84 80" ${SK(1.6)}/>`;

// --- Heróis 2.27 ---
FIGURAS.caidos = `<path d="M34 6 Q60 34 86 6 Q80 28 60 31 Q40 28 34 6Z" ${W}/><path d="M41 42 Q41 25 60 25 Q79 25 79 42Z" ${W}/><rect x="34" y="40" width="52" height="6" ${W}/>`
  + `<path d="M46 46 L74 46 L72 58 L48 58Z" ${W}/>` + espelho(`<path d="M50 49 L57 51 L51 54Z" ${K}/>`)
  + `<path d="M22 60 L98 60 L90 73 L30 73Z" ${W}/><path d="M36 73 L84 73 Q88 94 78 110 Q72 100 67 114 Q60 102 53 114 Q48 100 42 110 Q32 94 36 73Z" ${W}/>`
  + `<path d="M40 82 H80 M42 92 H78" ${SK(2.6)}/><path d="M30 66 H90" ${SK(1.8)}/>`
  + `<line x1="92" y1="70" x2="116" y2="10" ${S(4.5)}/><line x1="86" y1="74" x2="99" y2="66" ${S(4.5)}/>`;
FIGURAS.leao = `<polygon points="${star(16, 58, 44)}" ${W}/><circle cx="60" cy="60" r="42" ${K}/>`
  + `<path d="M28 50 Q28 24 60 24 Q92 24 92 50 L90 70 Q86 98 60 104 Q34 98 30 70Z" ${W}/>`
  + espelho(`<circle cx="45" cy="48" r="9" ${K}/><circle cx="46" cy="49" r="4" ${W}/><path d="M32 36 Q42 28 54 34" ${SK(4)}/>`)
  + `<path d="M50 60 Q60 54 70 60 Q68 70 60 70 Q52 70 50 60Z" ${K}/><path d="M36 76 Q60 70 84 76 Q78 96 60 98 Q42 96 36 76Z" ${K}/>`
  + `<g ${W}>${[40, 50, 60, 70].map(x => `<polygon points="${x},76 ${x + 9},76 ${x + 4.5},86"/>`).join('')}</g>`;
FIGURAS.aranha = espelho(`<path d="M52 54 Q30 30 12 34 L8 44 Q28 40 50 60Z" ${W}/><path d="M52 62 Q26 54 6 66 L8 74 Q28 64 52 68Z" ${W}/><path d="M52 70 Q30 76 16 96 L22 102 Q34 84 54 76Z" ${W}/><path d="M54 76 Q40 92 36 114 L44 116 Q46 96 58 80Z" ${W}/>`)
  + `<ellipse cx="60" cy="80" rx="15" ry="20" ${W}/><circle cx="60" cy="52" r="11" ${W}/>`
  + `<path d="M55 74 L65 74 L60 81 L65 88 L55 88 L60 81Z" ${K}/>` + espelho(`<circle cx="55" cy="48" r="2.4" ${K}/><circle cx="52" cy="54" r="1.6" ${K}/>`)
  + `<line x1="60" y1="41" x2="60" y2="2" ${S(2)}/>`;
FIGURAS.arvore = `<g ${W}><circle cx="60" cy="30" r="24"/><circle cx="34" cy="42" r="18"/><circle cx="86" cy="42" r="18"/><circle cx="46" cy="22" r="14"/><circle cx="76" cy="22" r="14"/></g>`
  + `<path d="M50 54 Q52 80 42 112 L78 112 Q68 80 70 54Z" ${W}/><path d="M42 112 Q30 114 22 116 M78 112 Q90 114 98 116" ${S(4)}/>`
  + `<path d="M48 70 Q60 76 72 70" ${SK(4)}/>` + [52, 60, 68].map(x => `<polygon points="${x - 3},73 ${x + 3},73 ${x + 1},84 ${x + 4},84 ${x - 1},94" ${K}/>`).join('')
  + `<path d="M58 60 Q56 66 60 72" ${SK(2)}/>`;
FIGURAS.tambores = `<path d="M10 70 A52 52 0 0 1 110 70" ${S(4)}/>`
  + [-60, -30, 0, 30, 60].map(a => `<g transform="rotate(${a} 60 112)"><circle cx="60" cy="38" r="12" ${W}/><path d="M60 31 Q67 35 62 39 Q57 42 60 46" ${SK(2.4)}/></g>`).join('')
  + `<polygon points="64,52 46,86 58,86 50,118 76,76 63,76 70,52" ${W}/>`;

// --- Herói 2.30 ---
FIGURAS.garrafa = `<g transform="rotate(28 60 60) translate(60 66) scale(0.86) translate(-60 -60)">${GARRAFA}<rect x="46" y="60" width="28" height="26" ${K}/><path d="M50 66 H70 M50 74 H66 M50 80 H70" ${S(2.2)}/></g>`
  + `<g ${W}><circle cx="96" cy="14" r="5"/><circle cx="106" cy="26" r="4"/><circle cx="100" cy="38" r="3"/><circle cx="112" cy="10" r="2.6"/></g>`;

const PECAS = {};
PECAS.pena = `<path d="M20 2 Q31 13 27 25 L23 23 L25 31 L20 38 Q8 17 20 2Z" ${W}/><path d="M20 6 Q19 22 21 36" ${SK(1.2)}/>`;
PECAS.folha = `<g transform="translate(20 19)"><polygon points="${FOLHA}" ${W}/></g><line x1="20" y1="32" x2="20" y2="39" ${S(2.4)}/>`;
PECAS.papel = `<rect x="11" y="3" width="18" height="34" ${W}/><path d="M20 8 V16 M15 12 H25 M16 21 Q20 17 24 21 Q20 25 16 21 M20 25 V32" ${SK(1.8)}/>`;
PECAS.nota = `<ellipse cx="14" cy="30" rx="8.5" ry="6.5" transform="rotate(-20 14 30)" ${W}/><path d="M21 29 V6" ${S(3.4)}/><path d="M21 5 Q34 9 31 22 Q28 14 21 15Z" ${W}/>`;
PECAS.conta = `<circle cx="20" cy="20" r="14" ${W}/><circle cx="20" cy="20" r="4.5" ${K}/><path d="M11 14 Q14 9 20 9" ${SK(1.6)}/>`;
PECAS.gota = `<path d="M20 3 Q33 22 29 29 A9 9 0 0 1 11 29 Q7 22 20 3Z" ${W}/><path d="M15 26 Q15 31 20 32" ${SK(1.6)}/>`;
PECAS.sal = `<polygon points="20,6 31,13 30,28 19,34 9,26 10,12" ${W}/><path d="M20 6 L20 20 L30 28 M20 20 L9 26" ${SK(1.4)}/>`;
PECAS.petala = `<path d="M20 37 Q3 21 13 5 L20 12 L27 5 Q37 21 20 37Z" ${W}/>`;
PECAS.caco = `<polygon points="7,5 35,13 15,37" ${W}/><path d="M14 9 L22 20 L16 30" ${SK(1.5)}/>`;
PECAS.estrepe = `<polygon points="${star(4, 18.5, 4.2, -90, 20, 20)}" ${W}/><circle cx="20" cy="20" r="2.2" ${K}/>`;
PECAS.estrela = `<polygon points="${star(8, 18.5, 8, -90, 20, 20)}" ${W}/>`;
PECAS.elo = `<ellipse cx="20" cy="20" rx="9" ry="15" ${S(5)}/>`;
PECAS.shuriken = `<polygon points="${star(4, 18.5, 6, -90, 20, 20)}" ${W}/><circle cx="20" cy="20" r="3.2" ${K}/>`;
PECAS.chama = `<path d="M20 2 Q33 16 31 27 A11 11 0 1 1 9 27 Q9 20 14 15 Q15 22 19 20 Q16 10 20 2Z" ${W}/><path d="M20 22 Q25 27 20 33 Q15 29 20 22Z" ${K}/>`;
PECAS.lasca = `<polygon points="9,7 19,3 31,33 21,37" ${W}/><path d="M15 8 L25 33" ${SK(1.4)}/>`;
PECAS.grou = `<g transform="scale(0.333)">${GROU}</g>`;

// --- Heróis 2.27 ---
PECAS.cinza = `<polygon points="8,12 20,5 33,10 35,24 26,35 11,32 5,22" ${W}/><g ${K}><circle cx="17" cy="16" r="2.4"/><circle cx="25" cy="25" r="1.8"/><circle cx="14" cy="26" r="1.4"/></g>`;
PECAS.confete = `<path d="M6 14 Q20 4 34 14 L32 26 Q20 16 8 26Z" ${W}/><path d="M12 16 Q20 11 28 16" ${SK(1.4)}/>`;
PECAS.fio = `<path d="M6 6 Q30 14 18 22 Q6 30 34 36" ${S(2.6)}/><circle cx="18" cy="22" r="4" ${W}/>`;
PECAS.nuvem = `<g ${W}><circle cx="14" cy="18" r="8"/><circle cx="24" cy="14" r="9"/><circle cx="31" cy="21" r="6"/><rect x="10" y="18" width="22" height="8"/></g><polygon points="20,26 15,34 19,34 16,39 25,30 21,30 24,26" ${W}/>`;
PECAS.semente = `<path d="M20 38 Q8 30 12 20 Q16 12 20 10 Q24 12 28 20 Q32 30 20 38Z" ${W}/><path d="M20 10 Q14 2 6 4 Q10 12 20 10Z" ${W}/><path d="M20 14 V34" ${SK(1.4)}/>`;
PECAS.faisca = `<polygon points="24,2 8,22 18,22 12,38 32,16 21,16 28,2" ${W}/>`;

module.exports = { SELOS, FIGURAS, PECAS };
