class_name CodigoSala
## Código da sala (Ciclo 2.28; 2.28c: sorteado, para a conexão automática).
## Formato: 32 bits + 8 bits de conferência = 8 letras. No 2.28 os 32 bits eram
## o IPv4 do anfitrião; desde o 2.28c são sorteados (o código só dá o tópico e a
## chave do quadro de recados, ver Sinal). ler() devolve "codigo" para as 8
## letras e "ip" (legado e testes). Texto antigo: o endereço IPv4 do anfitrião virado em 8
## letras fáceis de ditar ("K7QF-M9X2"). 32 bits do IP + 8 bits de conferência
## = 40 bits = 8 símbolos de 5 bits. Alfabeto Crockford (sem I, L, O, U: não
## confunde com 1, 0 e V). Também aceita o IP digitado direto ("26.1.2.3" ou
## "26.1.2.3:24680"), que é o que aparece no Radmin VPN.

const ALFABETO := "0123456789ABCDEFGHJKMNPQRSTVWXYZ"


static func gerar(ip: String) -> String:
	var p := ip.split(".")
	if p.size() != 4:
		return ""
	var n := 0
	for s in p:
		n = (n << 8) | (int(s) & 255)
	n = (n << 8) | _conferencia(n)
	var out := ""
	for i in 8:
		out = ALFABETO[n & 31] + out
		n >>= 5
	return out.substr(0, 4) + "-" + out.substr(4)


## Código novo e sorteado (conexão automática).
static func novo() -> String:
	var b := Crypto.new().generate_random_bytes(4)
	return gerar("%d.%d.%d.%d" % [b[0], b[1], b[2], b[3]])


## {"ip": String, "porta": int} (+ "codigo" se vieram as 8 letras); vazio se
## o texto não for código nem IP.
static func ler(texto: String, porta_padrao: int) -> Dictionary:
	var t := texto.strip_edges().to_upper()
	if t.count(".") == 3:
		var porta := porta_padrao
		if t.contains(":"):
			porta = int(t.get_slice(":", 1))
			t = t.get_slice(":", 0)
		if t.is_valid_ip_address():
			return {"ip": t, "porta": porta}
		return {}
	t = t.replace("-", "").replace(" ", "").replace("O", "0").replace("I", "1").replace("L", "1")
	if t.length() != 8:
		return {}
	var n := 0
	for ch in t:
		var v := ALFABETO.find(ch)
		if v < 0:
			return {}
		n = (n << 5) | v
	var ip_n := n >> 8
	if (n & 255) != _conferencia(ip_n):
		return {}
	return {"ip": "%d.%d.%d.%d" % [(ip_n >> 24) & 255, (ip_n >> 16) & 255, (ip_n >> 8) & 255, ip_n & 255], "porta": porta_padrao, "codigo": t}


static func _conferencia(n: int) -> int:
	var c := 0x5A
	for i in 4:
		c = (c * 31 + ((n >> (8 * i)) & 255)) & 255
	return c


## IP da internet que não recebe conexão de fora: rede local ou CGNAT do
## provedor (100.64.0.0/10). Nesses casos o código só vale na mesma rede.
static func ip_privado(ip: String) -> bool:
	var p := ip.split(".")
	if p.size() != 4:
		return true
	var a := int(p[0])
	var b := int(p[1])
	return a == 10 or a == 127 or (a == 192 and b == 168) or (a == 172 and b >= 16 and b <= 31) \
			or (a == 100 and b >= 64 and b <= 127) or (a == 169 and b == 254)
