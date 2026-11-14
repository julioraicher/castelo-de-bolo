extends Node
## Autoload "Rede" (Ciclo 2.28): jogar com amigos.
##
## Sala (2.28c): um de vocês é o anfitrião. "Criar sala" sorteia um código;
## os PCs trocam recados cifrados por um quadro público (Sinal, ntfy.sh) e
## ligam DIRETO por WebRTC (ICE + STUN fura o NAT, inclusive a maioria dos
## CGNAT; nenhuma porta aberta no roteador). A sala também aparece sozinha na
## lista da mesma rede (aviso UDP). Sala de teste e IP digitado usam ENet.
##
## Partida: LOCKSTEP. Cada PC roda o jogo inteiro; só viajam os Comandos dos
## humanos (17 bytes por quadro). O comando apertado no quadro t vale no
## quadro t + atraso em TODOS os PCs, inclusive no seu. O anfitrião junta os
## comandos de cada quadro e devolve o "quadro" completo; ninguém roda o quadro
## t antes de ter o quadro t. Faltou alguém? O jogo segura (pausa) até chegar.
## A cada 2 s todos comparam um resumo do estado (checksum).
##
## A física por trás: a partida é um sistema dinâmico x(t+1) = f(x(t), u(t)).
## Mesmo x(0) (semente), mesmos u(t) (comandos) e mesmo f (binário) = mesma
## trajetória bit a bit. Mas f é caótica (briga, colisão, IA): um bit de
## diferença cresce exponencialmente. Por isso nada que muda as regras pode
## depender do relógio de parede, do FPS ou de sorteio fora de Sorte.

signal sala_mudou
signal aviso(texto: String, cor: Color)
signal salas_lan_mudaram

const PORTA := 24680
const PORTA_LAN := 24681
const MAX_JOGADORES := 8
const VAGAS := 8
## Trocado pelo commit no CI (build.yml): versões diferentes não se misturam,
## porque qualquer diferença de regra dessincroniza a partida.
const VERSAO := "dev"
const HASH_A_CADA := 120     # quadros (2 s)
const ESPERA_AVISO := 1.0    # s segurando antes de mostrar "esperando..."
const ESPERA_LIMITE := 20.0  # s sem notícia de alguém: vira bot
const ESPERA_AMIGO := 30.0   # (amigo) s sem quadro do anfitrião: a conexão caiu
const ESPERA_VOLTA := 600.0  # (amigo que caiu) s tentando voltar para a sala
const VOLTAR_DESSINC := 5.0  # s mostrando o aviso antes de todos voltarem à sala

var online := false
var anfitriao := false
var em_partida := false
var meu_nome := ""
var sala := {}
var codigo_internet := ""
var codigos_lan: Array[String] = []
var upnp_texto := ""
var salas_lan := {}  # ip -> {nome, n, visto}
## Autoplay em rede (CI): o "humano" deste PC é um macaco de teste.
var macaco := false

# --- Lockstep ---
var game: Game
var atraso := 3
var _tick := 1
var _quadros := {}        # tick -> {"c": {peer: bytes}, "ev": []}
var _cmds := {}           # (anfitrião) tick -> {peer: bytes}
var _ativos: Array[int] = []
var _proximo := 1         # (anfitrião) próximo quadro a montar
var _eventos: Array = []  # (anfitrião) para o próximo quadro
var _latch := 0           # toques entre um quadro e outro
var _acao: Array = []     # ação do painel esperando ir no próximo comando
var _hashes := {}         # (anfitrião) tick -> hash dele
var _esperando := 0.0
var _espera_ini := 0
var _dessinc := false
var _voltar_t := 0.0      # (anfitrião) contagem até voltar todos à sala
var _reconectando := false  # amigo que caiu: tenta a sala de novo até o anfitrião voltar
## Aviso para a sala mostrar depois que a cena recarrega (o rótulo antigo some junto).
var aviso_pendente: Array = []
var _macaco_rng := RandomNumberGenerator.new()
var _macaco_dir := Vector2.ZERO
var _macaco_t := 0.0
var _mira_ult := Vector2(0, 1)

var _enet: ENetMultiplayerPeer
# --- Conexão automática (WebRTC) ---
const ICE := {"iceServers": [{"urls": ["stun:stun.l.google.com:19302", "stun:stun.cloudflare.com:3478"]}]}
const ESPERA_SALA := 25.0  # s procurando a sala antes de desistir
var _rtc: WebRTCMultiplayerPeer
var _sinal: Sinal
var _con := {}          # peer -> WebRTCPeerConnection
var _ice_pend := {}     # peer -> [[mid, idx, nome], ...] esperando ir num recado
var _ice_chegou := {}   # peer -> candidatos que chegaram antes da descrição
var _meu_rtc_id := 0
var _procura_t := 0.0
var _oi_t := 0.0
var _ice_t := 0.0
var codigo := ""        # código da sala (conexão automática)
var _udp: PacketPeerUDP
var _udp_t := 0.0
var _escuta: PacketPeerUDP
var _upnp: UPNP
var _upnp_thread: Thread
var _ping_t := 0.0
var _auto_n := 0          # --hospedar-teste=N: começa sozinho com N jogadores
# Teste de queda (tools/teste_queda.sh): o amigo derruba a ligação ou mexe no
# próprio estado no quadro T; o anfitrião volta à sala sozinho e recomeça.
var _cair_teste := 0
var _dessinc_teste := 0
var _recomecar_teste := false
var _tempo_original := -1.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_physics_priority = -1000
	multiplayer.peer_connected.connect(_on_peer_entrou)
	multiplayer.peer_disconnected.connect(_on_peer_saiu)
	multiplayer.connected_to_server.connect(_on_conectou)
	multiplayer.connection_failed.connect(_on_falhou)
	multiplayer.server_disconnected.connect(_on_servidor_caiu)
	meu_nome = _nome_padrao()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--nome="):
			meu_nome = arg.trim_prefix("--nome=")
		elif arg == "--autoplay":
			macaco = true
		elif arg.begins_with("--cair-teste="):
			_cair_teste = int(arg.trim_prefix("--cair-teste="))
		elif arg.begins_with("--dessinc-teste="):
			_dessinc_teste = int(arg.trim_prefix("--dessinc-teste="))
		elif arg == "--recomecar-teste":
			_recomecar_teste = true
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--hospedar-teste="):
			_auto_n = int(arg.trim_prefix("--hospedar-teste="))
			hospedar.call_deferred(meu_nome, false)
		elif arg.begins_with("--criar-sala-teste="):
			_auto_n = int(arg.trim_prefix("--criar-sala-teste="))
			criar_sala.call_deferred(meu_nome)
		elif arg.begins_with("--entrar="):
			Menus.abrir_sala = true
			entrar.call_deferred(meu_nome, arg.trim_prefix("--entrar="))


func _nome_padrao() -> String:
	var n := OS.get_environment("USERNAME")
	if n == "":
		n = OS.get_environment("USER")
	return n.left(14) if n != "" else "Jogador"


## Versão que precisa bater para jogar junto: commit + sistema (a mesma
## conta de ponto flutuante pode dar o último bit diferente entre Windows e
## Linux, e isso basta para dessincronizar).
func versao() -> String:
	return "%s-%s" % [VERSAO, OS.get_name()]


func id() -> int:
	return multiplayer.get_unique_id() if online else 1


# --- Sala -----------------------------------------------------------------------

## Criar sala (conexão automática). Sem a extensão WebRTC (editor sem o
## plugin) cai na sala antiga por ENet.
func criar_sala(nome: String) -> bool:
	if not _tem_webrtc():
		return hospedar(nome, true)
	sair()
	meu_nome = nome
	_rtc = WebRTCMultiplayerPeer.new()
	if _rtc.create_server() != OK:
		_rtc = null
		return hospedar(nome, true)
	multiplayer.multiplayer_peer = _rtc
	online = true
	anfitriao = true
	sala = {"jogadores": {}, "tempo": 15, "dificuldade": Settings.difficulty, "semente": 0, "atraso": 3,
			"mapa": Settings.mapa, "tema": Settings.theme, "versao": versao()}
	_adicionar(1, nome)
	codigo = CodigoSala.novo()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--codigo="):
			codigo = arg.trim_prefix("--codigo=")
	codigo_internet = ""
	codigos_lan.clear()
	upnp_texto = "Ligando o quadro de recados..."
	_abrir_sinal()
	_udp = PacketPeerUDP.new()
	_udp.set_broadcast_enabled(true)
	_udp.set_dest_address("255.255.255.255", PORTA_LAN)
	sala_mudou.emit()
	return true


func _tem_webrtc() -> bool:
	if OS.get_name() == "Web":
		return false
	var c := WebRTCPeerConnection.new()
	return c.initialize({}) == OK


func _abrir_sinal() -> void:
	if _sinal == null:
		_sinal = Sinal.new()
		add_child(_sinal)
		_sinal.recado.connect(_on_recado)
		_sinal.aberto.connect(_on_sinal_aberto)
		_sinal.caiu.connect(_on_sinal_caiu)
	_sinal.abrir(codigo)


func hospedar(nome: String, abrir_porta := true) -> bool:
	sair()
	meu_nome = nome
	_enet = ENetMultiplayerPeer.new()
	var err := _enet.create_server(PORTA, MAX_JOGADORES - 1)
	if err != OK:
		aviso.emit("Não deu para abrir a sala (a porta %d já está em uso? feche outra cópia do jogo)." % PORTA, Color(1, 0.55, 0.5))
		_enet = null
		return false
	multiplayer.multiplayer_peer = _enet
	online = true
	anfitriao = true
	sala = {"jogadores": {}, "tempo": 15, "dificuldade": Settings.difficulty, "semente": 0, "atraso": 3,
			"mapa": Settings.mapa, "tema": Settings.theme, "versao": versao()}
	_adicionar(1, nome)
	codigos_lan.clear()
	for ip in _ips_locais():
		codigos_lan.append(ip)
	codigo_internet = ""
	if abrir_porta and OS.get_name() != "Web":
		upnp_texto = "Abrindo a porta no roteador..."
		_upnp_thread = Thread.new()
		_upnp_thread.start(_upnp_abrir)
	else:
		upnp_texto = ""
	_udp = PacketPeerUDP.new()
	_udp.set_broadcast_enabled(true)
	_udp.set_dest_address("255.255.255.255", PORTA_LAN)
	sala_mudou.emit()
	return true


## Modo teste: abre a sala e uma segunda janela do jogo que entra nela, para
## testar o online sozinho no mesmo PC.
func sala_teste(nome: String) -> void:
	if not hospedar(nome, false):
		return
	var args := PackedStringArray()
	if not OS.has_feature("template"):
		args.append_array(["--path", ProjectSettings.globalize_path("res://")])
	args.append_array(["--", "--entrar=127.0.0.1", "--nome=Janela 2"])
	OS.create_process(OS.get_executable_path(), args)


func entrar(nome: String, texto: String) -> bool:
	var alvo := CodigoSala.ler(texto, PORTA)
	if alvo.is_empty():
		aviso.emit("Código inválido. Confira as 8 letras (ou digite o IP).", Color(1, 0.55, 0.5))
		return false
	if alvo.has("codigo") and _tem_webrtc():
		return _entrar_rtc(nome, alvo.codigo)
	sair()
	meu_nome = nome
	_enet = ENetMultiplayerPeer.new()
	if _enet.create_client(alvo.ip, alvo.porta) != OK:
		aviso.emit("Não deu para conectar.", Color(1, 0.55, 0.5))
		_enet = null
		return false
	multiplayer.multiplayer_peer = _enet
	online = true
	anfitriao = false
	aviso.emit("Procurando a sala em %s..." % alvo.ip, Color(1, 0.9, 0.6))
	return true


func sair() -> void:
	if _upnp_thread and _upnp_thread.is_started():
		_upnp_thread.wait_to_finish()
	_upnp_thread = null
	if _upnp:
		_upnp.delete_port_mapping(PORTA, "UDP")
		_upnp = null
	if _enet:
		_enet.close()
		_enet = null
	if _sinal:
		_sinal.fechar()
	for p in _con:
		_con[p].close()
	_con.clear()
	_ice_pend.clear()
	_ice_chegou.clear()
	if _rtc:
		_rtc.close()
		_rtc = null
	_procura_t = 0.0
	_reconectando = false
	_voltar_t = 0.0
	codigo = ""
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	_udp = null
	online = false
	anfitriao = false
	em_partida = false
	sala = {}
	game = null
	_restaurar_config()
	sala_mudou.emit()


func jogadores() -> Dictionary:
	return sala.get("jogadores", {})


func eu() -> Dictionary:
	return jogadores().get(id(), {})


## Peer na vaga (time, i) ou -1 (bot).
func peer_na_vaga(time: int, vaga: int) -> int:
	var js := jogadores()
	for p in js:
		if js[p].time == time and js[p].vaga == vaga:
			return p
	return -1


func humanos_no_time(time: int) -> int:
	var n := 0
	for p in jogadores():
		if jogadores()[p].time == time:
			n += 1
	return n


func pedir_vaga(time: int, vaga: int) -> void:
	if anfitriao:
		_mover(1, time, vaga)
	else:
		_r_vaga.rpc_id(1, time, vaga)


func pedir_pronto(p: bool) -> void:
	if anfitriao:
		_pronto(1, p)
	else:
		_r_pronto.rpc_id(1, p)


## Anfitrião: move qualquer um (vaga ocupada = os dois trocam).
func mover(peer: int, time: int, vaga: int) -> void:
	if anfitriao:
		_mover(peer, time, vaga)


func embaralhar() -> void:
	if not anfitriao:
		return
	var ps := jogadores().keys()
	ps.shuffle()
	var n := [0, 0]
	for k in ps.size():
		var t := k % 2
		jogadores()[ps[k]].time = t
		jogadores()[ps[k]].vaga = n[t]
		n[t] += 1
	_espalhar()


func ajustar(chave: String, valor: Variant) -> void:
	if anfitriao:
		sala[chave] = valor
		_espalhar()


func todos_prontos() -> bool:
	for p in jogadores():
		if p != 1 and not jogadores()[p].pronto:
			return false
	return true


func comecar() -> void:
	if not anfitriao:
		return
	var pior := 0
	for p in jogadores():
		pior = maxi(pior, int(jogadores()[p].get("ping", 0)))
	# Comando de A até B passa pelo anfitrião: ~ (rtt_A + rtt_B) / 2 ≤ pior rtt.
	sala.atraso = clampi(ceili(pior / (1000.0 / Engine.physics_ticks_per_second)) + 1, 2, 9)
	sala.semente = randi()
	_r_comecar.rpc(sala)
	_r_comecar(sala)


func voltar_para_sala() -> void:
	if not anfitriao:
		return
	_voltar_t = 0.0
	# Quem caiu durante a partida sai da lista (se voltar, entra de novo).
	var ligados := multiplayer.get_peers()
	for p in jogadores().keys():
		if int(p) != 1 and int(p) not in ligados:
			jogadores().erase(p)
	_espalhar()
	_r_voltar.rpc()
	_r_voltar()


# --- RPC da sala ------------------------------------------------------------------

@rpc("any_peer", "call_remote", "reliable")
func _r_ola(nome: String, versao: String) -> void:
	var p := multiplayer.get_remote_sender_id()
	if not anfitriao:
		return
	if versao != versao():
		_r_recusado.rpc_id(p, "Versões diferentes do jogo (sua: %s, sala: %s). Baixem a mesma da \"ultima-versao\" (todos no .exe do Windows)." % [versao, versao()])
		return
	if em_partida:
		_r_recusado.rpc_id(p, "A partida já começou. Espere voltarem para a sala.")
		return
	if jogadores().size() >= MAX_JOGADORES:
		_r_recusado.rpc_id(p, "Sala cheia (%d)." % MAX_JOGADORES)
		return
	_adicionar(p, nome)
	aviso.emit("%s entrou." % nome, Color(0.7, 1, 0.75))
	_espalhar()


@rpc("authority", "call_remote", "reliable")
func _r_recusado(motivo: String) -> void:
	aviso.emit(motivo, Color(1, 0.55, 0.5))
	sair()


@rpc("authority", "call_remote", "reliable")
func _r_sala(s: Dictionary) -> void:
	sala = s
	sala_mudou.emit()


@rpc("any_peer", "call_remote", "reliable")
func _r_vaga(time: int, vaga: int) -> void:
	if anfitriao:
		_mover(multiplayer.get_remote_sender_id(), time, vaga)


@rpc("any_peer", "call_remote", "reliable")
func _r_pronto(p: bool) -> void:
	if anfitriao:
		_pronto(multiplayer.get_remote_sender_id(), p)


@rpc("authority", "call_remote", "reliable")
func _r_comecar(s: Dictionary) -> void:
	sala = s
	em_partida = true
	atraso = int(s.atraso)
	if _tempo_original < 0.0:
		_tempo_original = Config.cfg.tempo_limite
	Config.cfg.tempo_limite = float(s.tempo) * 60.0
	for p in jogadores():
		jogadores()[p].pronto = false
	# Já aceita comandos desta partida: o amigo pode recarregar a cena antes do
	# anfitrião e mandar o quadro 3 antes de o anfitrião montar o jogo.
	_cmds.clear()
	_quadros.clear()
	_eventos.clear()
	_ativos.clear()
	for p in jogadores():
		_ativos.append(int(p))
	_ativos.sort()
	_proximo = atraso + 1
	Menus.pular_inicio = true
	Game.sandbox_pedido = false
	Game.time_pedido = int(eu().get("time", 0))
	get_tree().paused = false
	get_tree().reload_current_scene()


@rpc("authority", "call_remote", "reliable")
func _r_voltar() -> void:
	print("REDE sala")
	em_partida = false
	game = null
	_restaurar_config()
	Menus.abrir_sala = true
	get_tree().paused = false
	get_tree().reload_current_scene()


func _restaurar_config() -> void:
	if _tempo_original >= 0.0:
		Config.cfg.tempo_limite = _tempo_original
		_tempo_original = -1.0


func _adicionar(p: int, nome: String) -> void:
	var t := 0 if humanos_no_time(0) <= humanos_no_time(1) else 1
	var v := 0
	while peer_na_vaga(t, v) >= 0:
		v += 1
	jogadores()[p] = {"nome": nome.left(14), "time": t, "vaga": v, "pronto": false, "ping": 0}


func _mover(p: int, time: int, vaga: int) -> void:
	if not jogadores().has(p) or vaga < 0 or vaga >= VAGAS:
		return
	var outro := peer_na_vaga(time, vaga)
	if outro >= 0 and outro != p:
		jogadores()[outro].time = jogadores()[p].time
		jogadores()[outro].vaga = jogadores()[p].vaga
	jogadores()[p].time = time
	jogadores()[p].vaga = vaga
	_espalhar()


func _pronto(p: int, v: bool) -> void:
	if jogadores().has(p):
		jogadores()[p].pronto = v
		_espalhar()


func _espalhar() -> void:
	if anfitriao:
		_r_sala.rpc(sala)
		sala_mudou.emit()


func _on_peer_entrou(p: int) -> void:
	_folga_enet(p)  # depois espera o "olá" com nome e versão


## Carregar a partida trava o PC alguns segundos (Intel UHD: mais). O ENet
## derruba quem fica 5 s sem responder; dá até 30 s de folga.
func _folga_enet(p: int) -> void:
	if _enet:
		var pp := _enet.get_peer(p)
		if pp:
			pp.set_timeout(64, 30000, 60000)


func _on_peer_saiu(p: int) -> void:
	if not anfitriao:
		return
	_con.erase(p)
	var nome: String = jogadores().get(p, {}).get("nome", "Alguém")
	if em_partida:
		if p in _ativos:
			_ativos.erase(p)
			_eventos.append(["saiu", p])
			_montar_quadros()
			if _recomecar_teste:
				_voltar_t = 6.0  # teste: o "Julio" aperta Esc → Voltar à sala
	else:
		jogadores().erase(p)
		_espalhar()
	aviso.emit("%s saiu." % nome, Color(1, 0.8, 0.5))


func _on_conectou() -> void:
	_folga_enet(1)
	_r_ola.rpc_id(1, meu_nome, versao())


func _on_falhou() -> void:
	aviso.emit("Não achei a sala. Confira o código; se for de outra casa, o anfitrião talvez precise do Radmin VPN.", Color(1, 0.55, 0.5))
	sair()


func _on_servidor_caiu() -> void:
	if not online or anfitriao:
		return
	var estava := em_partida
	var cod := codigo
	sair()
	if estava and cod != "" and _tem_webrtc():
		# Caiu no meio da partida (a internet piscou, o PC travou): volta para
		# a mesma sala sozinho. Enquanto o anfitrião estiver na partida, ele
		# responde "espere"; quando voltar à sala, o amigo entra de novo.
		_entrar_rtc(meu_nome, cod)
		_reconectando = true
		_procura_t = ESPERA_VOLTA
		_aviso_depois("Você caiu da partida. Tentando voltar para a sala %s sozinho..." % cod, Color(1, 0.8, 0.45))
	else:
		_aviso_depois("A conexão com o anfitrião caiu (ou ele fechou a sala)." if estava else "O anfitrião fechou a sala.", Color(1, 0.55, 0.5))
	if estava:
		Menus.abrir_sala = true
		get_tree().paused = false
		get_tree().reload_current_scene()


## Aviso agora (sala aberta) e guardado para a sala nova depois de recarregar.
func _aviso_depois(texto: String, cor: Color) -> void:
	aviso_pendente = [texto, cor]
	aviso.emit(texto, cor)


# --- Porta (UPnP), IPs e lista da rede local ---------------------------------------

## UPnP (thread separada). Insiste: procura o roteador duas vezes (filtro de
## gateway e depois qualquer aparelho), tenta a porta com prazo (2 h) e depois
## permanente (alguns roteadores só aceitam um dos dois) e pergunta o IP de fora
## mesmo se a porta falhar, para saber se é CGNAT.
## motivo: "" (ok), "sem_upnp", "recusou", "cgnat".
func _upnp_abrir() -> void:
	var u := UPNP.new()
	var res := {"ok": false, "ip": "", "motivo": "sem_upnp"}
	var achou := false
	for filtro in ["InternetGatewayDevice", ""]:
		u.clear_devices()
		if u.discover(3000, 2, filtro) == UPNP.UPNP_RESULT_SUCCESS \
				and u.get_gateway() and u.get_gateway().is_valid_gateway():
			achou = true
			break
	if achou:
		res.motivo = "recusou"
		# Com prazo primeiro (2 h): se o jogo fechar sem apagar, a porta fecha sozinha.
		for prazo in [7200, 0]:
			if u.add_port_mapping(PORTA, PORTA, "Castelo de Bolo", "UDP", prazo) == UPNP.UPNP_RESULT_SUCCESS:
				res.ok = true
				res.motivo = ""
				break
		res.ip = u.query_external_address()
		if res.ip != "" and CodigoSala.ip_privado(res.ip):
			res.ok = false
			res.motivo = "cgnat"
	_upnp_fim.call_deferred(res, u)


func _upnp_fim(res: Dictionary, u: UPNP) -> void:
	if not online or not anfitriao:
		return
	if res.ok:
		_upnp = u
	var ip: String = res.ip
	if res.ok and ip != "":
		codigo_internet = CodigoSala.gerar(ip)
		upnp_texto = "Porta aberta: amigos de outras casas entram com o código."
	else:
		upnp_texto = {
			"cgnat": "Sua internet não recebe conexão de fora (CGNAT da operadora). Amigo de outra casa: usem o Radmin VPN (grátis) e o IP 26.x acima.",
			"recusou": "O roteador recusou abrir a porta. Amigo de outra casa: usem o Radmin VPN (grátis) e o IP 26.x acima.",
		}.get(res.motivo, "O roteador não respondeu ao pedido de abrir a porta (UPnP desligado nele?). Amigo de outra casa: usem o Radmin VPN (grátis) e o IP 26.x acima.")
		if not _tem_radmin():
			upnp_texto += " Depois de instalar o Radmin, crie a sala de novo."
	sala_mudou.emit()


func _tem_radmin() -> bool:
	for ip in codigos_lan:
		if ip.begins_with("26."):
			return true
	return false


func _ips_locais() -> Array[String]:
	var out: Array[String] = []
	for ip in IP.get_local_addresses():
		if ip.count(".") == 3 and not ip.begins_with("127.") and not ip.begins_with("169.254."):
			out.append(ip)
	# Radmin VPN (26.x) primeiro: é o que funciona entre casas.
	out.sort_custom(func(a: String, b: String) -> bool: return a.begins_with("26.") and not b.begins_with("26."))
	return out


## Lista da rede local: a tela "Jogar com amigos" chama enquanto está aberta.
func escutar_lan(ligar: bool) -> void:
	if ligar and _escuta == null:
		_escuta = PacketPeerUDP.new()
		if _escuta.bind(PORTA_LAN) != OK:
			_escuta = null  # outra cópia do jogo já escuta neste PC
	elif not ligar and _escuta:
		_escuta.close()
		_escuta = null
		salas_lan.clear()


func _process(delta: float) -> void:
	if _escuta:
		var mudou := false
		while _escuta.get_available_packet_count() > 0:
			var pk := _escuta.get_packet()
			var ip := _escuta.get_packet_ip()
			var d = JSON.parse_string(pk.get_string_from_utf8())
			if d is Dictionary and d.get("j") == "CDB":
				salas_lan[ip] = {"nome": str(d.get("n", "?")).left(14), "n": int(d.get("q", 1)), "versao": str(d.get("v", "")),
						"codigo": str(d.get("c", "")).left(9), "visto": Time.get_ticks_msec()}
				mudou = true
		for ip in salas_lan.keys():
			if Time.get_ticks_msec() - int(salas_lan[ip].visto) > 3500:
				salas_lan.erase(ip)
				mudou = true
		if mudou:
			salas_lan_mudaram.emit()
	_tick_rtc(delta)
	if not online or not anfitriao:
		return
	if _voltar_t > 0.0:
		_voltar_t -= delta
		if _voltar_t <= 0.0 and em_partida:
			voltar_para_sala()
	if _udp and not em_partida:
		_udp_t -= delta
		if _udp_t <= 0.0:
			_udp_t = 1.0
			var msg := JSON.stringify({"j": "CDB", "v": versao(), "n": meu_nome, "q": jogadores().size(), "c": codigo})
			_udp.put_packet(msg.to_utf8_buffer())
	_ping_t -= delta
	if _ping_t <= 0.0:
		_ping_t = 1.0
		for p in jogadores():
			if p != 1 and p in multiplayer.get_peers():
				_r_ping.rpc_id(p, Time.get_ticks_msec())
	if _auto_n > 0 and not em_partida and jogadores().size() >= _auto_n:
		if not _recomecar_teste:
			_auto_n = 0
		comecar()


# --- Conexão automática (WebRTC + Sinal) ---------------------------------------

func _entrar_rtc(nome: String, cod: String) -> bool:
	sair()
	meu_nome = nome
	_meu_rtc_id = randi_range(2, 2147483646)
	_rtc = WebRTCMultiplayerPeer.new()
	if _rtc.create_client(_meu_rtc_id) != OK:
		_rtc = null
		aviso.emit("Não deu para começar a conexão.", Color(1, 0.55, 0.5))
		return false
	multiplayer.multiplayer_peer = _rtc
	online = true
	anfitriao = false
	codigo = cod
	_procura_t = ESPERA_SALA
	_oi_t = 0.0
	_abrir_sinal()
	aviso.emit("Procurando a sala %s..." % cod, Color(1, 0.9, 0.6))
	return true


func _on_sinal_aberto() -> void:
	if anfitriao:
		codigo_internet = codigo
		upnp_texto = "Código pronto: mande para os amigos (funciona de qualquer casa)."
		sala_mudou.emit()
	else:
		_oi_t = 0.0  # manda o "oi" já


func _on_sinal_caiu() -> void:
	if not online:
		return
	if anfitriao:
		codigo_internet = ""
		upnp_texto = "Sem acesso ao quadro de recados (internet?). Tentando de novo..."
		sala_mudou.emit()
	# tenta de novo em seguida (o ntfy fecha conexões paradas)
	if codigo != "":
		_sinal.abrir.call_deferred(codigo)


func _tick_rtc(delta: float) -> void:
	if _rtc == null:
		return
	# Candidatos ICE saem em rajada: junta 0,25 s num recado só.
	_ice_t -= delta
	if _ice_t <= 0.0 and not _ice_pend.is_empty():
		_ice_t = 0.25
		var meu := 1 if anfitriao else _meu_rtc_id
		for p in _ice_pend:
			_sinal.enviar({"t": "ice", "de": meu, "para": p, "c": _ice_pend[p]})
		_ice_pend.clear()
	if anfitriao:
		for p in _con.keys():
			if _con[p].get_connection_state() == WebRTCPeerConnection.STATE_FAILED:
				_rtc.remove_peer(p)
				_con.erase(p)
		return
	# Amigo: repete o "oi" até o anfitrião responder; desiste depois de um tempo.
	if 1 in multiplayer.get_peers():
		_procura_t = 0.0
		if _reconectando:
			print("REDE voltou")
			_reconectando = false
			aviso_pendente = []
			aviso.emit("De volta à sala!", Color(0.7, 1, 0.75))
		return
	if _procura_t <= 0.0:
		return
	_procura_t -= delta
	_oi_t -= delta
	if _oi_t <= 0.0 and _sinal.esta_aberto() and not _con.has(1):
		_oi_t = 3.0
		_sinal.enviar({"t": "oi", "de": _meu_rtc_id, "v": versao()})
	var falhou: bool = _con.has(1) and _con[1].get_connection_state() == WebRTCPeerConnection.STATE_FAILED
	if _procura_t <= 0.0 or falhou:
		var msg := "Não deu para ligar direto com o anfitrião (rede muito fechada dos dois lados). Plano B: os dois no Radmin VPN e o mesmo código." if _con.has(1) \
				else "Não achei a sala %s. Confira o código e se o anfitrião está com a sala aberta." % codigo
		if _reconectando and falhou:
			# Voltando de uma queda: a ligação nova falhou, tenta outra do zero.
			_con[1].close()
			_con.erase(1)
			_rtc.remove_peer(1)
			_oi_t = 3.0
			return
		sair()
		aviso.emit(msg, Color(1, 0.55, 0.5))


func _nova_conexao(p: int) -> WebRTCPeerConnection:
	var c := WebRTCPeerConnection.new()
	c.initialize(ICE)
	var meu := 1 if anfitriao else _meu_rtc_id
	c.session_description_created.connect(func(tipo: String, sdp: String):
		c.set_local_description(tipo, sdp)
		_sinal.enviar({"t": "sdp", "de": meu, "para": p, "tipo": tipo, "sdp": sdp}))
	c.ice_candidate_created.connect(func(mid: String, idx: int, nome: String):
		if not _ice_pend.has(p):
			_ice_pend[p] = []
		_ice_pend[p].append([mid, idx, nome]))
	_con[p] = c
	_rtc.add_peer(c, p)
	return c


func _on_recado(d: Dictionary) -> void:
	if not online or _rtc == null:
		return
	var de := int(d.get("de", 0))
	var t := str(d.get("t", ""))
	if anfitriao:
		if de < 2:
			return
		if t == "oi":
			if _con.has(de):
				return
			if str(d.get("v", "")) != versao():
				_sinal.enviar({"t": "nao", "de": 1, "para": de, "m": "Versões diferentes do jogo (sala: %s). Baixem a mesma da \"ultima-versao\"." % versao()})
			elif em_partida:
				_sinal.enviar({"t": "nao", "de": 1, "para": de, "k": "partida", "m": "A partida já começou. Espere voltarem para a sala."})
			elif _con.size() >= MAX_JOGADORES - 1:
				_sinal.enviar({"t": "nao", "de": 1, "para": de, "m": "Sala cheia (%d)." % MAX_JOGADORES})
			else:
				_nova_conexao(de).create_offer()
			return
	elif int(d.get("para", 0)) != _meu_rtc_id or de != 1:
		return
	match t:
		"sdp":
			var c: WebRTCPeerConnection = _con.get(de)
			if c == null and not anfitriao:
				c = _nova_conexao(1)
			if c:
				c.set_remote_description(str(d.get("tipo", "")), str(d.get("sdp", "")))
				for cand in _ice_chegou.get(de, []):
					c.add_ice_candidate(cand[0], cand[1], cand[2])
				_ice_chegou.erase(de)
		"ice":
			var lista: Variant = d.get("c", [])
			if not lista is Array:
				return
			for cand in lista.slice(0, 32):
				if not cand is Array or cand.size() != 3:
					continue
				var cc := [str(cand[0]), int(cand[1]), str(cand[2]).left(300)]
				if _con.has(de):
					_con[de].add_ice_candidate(cc[0], cc[1], cc[2])
				else:
					if not _ice_chegou.has(de):
						_ice_chegou[de] = []
					_ice_chegou[de].append(cc)
		"nao":
			if _reconectando and str(d.get("k", "")) == "partida":
				aviso.emit("O anfitrião ainda está na partida. Quando ele for em Esc → Voltar à sala (todos), você entra sozinho.", Color(1, 0.8, 0.45))
				return  # continua mandando "oi" a cada 3 s
			var m := str(d.get("m", "O anfitrião recusou.")).left(160)
			sair()
			aviso.emit(m, Color(1, 0.55, 0.5))


@rpc("authority", "call_remote", "reliable")
func _r_ping(t: int) -> void:
	_r_pong.rpc_id(1, t)


@rpc("any_peer", "call_remote", "reliable")
func _r_pong(t: int) -> void:
	var p := multiplayer.get_remote_sender_id()
	if not anfitriao or not jogadores().has(p):
		return
	var ms := clampi(Time.get_ticks_msec() - t, 0, 5000)
	var antes := int(jogadores()[p].ping)
	var novo := ms if antes == 0 else roundi(antes * 0.7 + ms * 0.3)
	if absi(novo - antes) >= 5:
		jogadores()[p].ping = novo
		if not em_partida:
			_espalhar()
	else:
		jogadores()[p].ping = novo


# --- Lockstep --------------------------------------------------------------------

## Game chama ao montar a partida online (depois de criar as unidades).
func iniciar_partida(g: Game) -> void:
	game = g
	_tick = 1
	_hashes.clear()
	_acao.clear()
	_latch = 0
	_esperando = 0.0
	_espera_ini = 0
	_dessinc = false
	_macaco_rng.seed = hash(id())
	# Os primeiros quadros não têm comando de ninguém (o atraso ainda não passou).
	var vazio := {}
	for p in _ativos:
		vazio[p] = Comando.vazio_bytes()
	for t in range(1, atraso + 1):
		_quadros[t] = {"c": vazio.duplicate(), "ev": []}
	if anfitriao:
		_montar_quadros()  # comandos que chegaram enquanto a cena carregava


func _physics_process(delta: float) -> void:
	if not em_partida or game == null or not is_instance_valid(game):
		return
	if not macaco:
		_latch |= _toques()
	if not _quadros.has(_tick):
		get_tree().paused = true
		# Tempo de verdade (não o do jogo): esperar a rede é coisa do relógio de
		# parede, e com o jogo pausado o quadro do motor pode correr à toa.
		var agora := Time.get_ticks_msec()
		if _espera_ini == 0:
			_espera_ini = agora
		_esperando = (agora - _espera_ini) / 1000.0
		if DisplayServer.get_name() == "headless":
			OS.delay_msec(5)  # testes: o quadro parado não gasta o --quit-after à toa
		if _esperando >= ESPERA_AVISO and game.hud:
			game.hud.dica_rede("Esperando %s..." % _quem_falta())
		if anfitriao and _esperando >= ESPERA_LIMITE:
			_desistir_dos_lentos()
		elif not anfitriao and _esperando >= ESPERA_AMIGO:
			_on_servidor_caiu()  # nada do anfitrião há 30 s: a ligação morreu calada
		return
	if _esperando >= ESPERA_AVISO and game.hud:
		game.hud.dica_rede(game.dica_fim())
	_esperando = 0.0
	_espera_ini = 0
	get_tree().paused = false
	var q: Dictionary = _quadros[_tick]
	_quadros.erase(_tick)
	for ev in q.ev:
		if ev[0] == "saiu":
			game.humano_saiu(int(ev[1]))
	var ps: Array = q.c.keys()
	ps.sort()
	for p in ps:
		var c := Comando.de_bytes(q.c[p])
		game.comando_humano(int(p), c)
	# Resumo do estado ANTES deste quadro (= depois do anterior).
	if (_tick - 1) % HASH_A_CADA == 0 and _tick > 1:
		var h := game.hash_partes()
		if anfitriao:
			_hashes[_tick - 1] = h
		else:
			_r_hash.rpc_id(1, _tick - 1, h)
	_enviar(_tick + atraso, _amostrar(delta))
	_tick += 1
	if _cair_teste > 0 and _tick == _cair_teste and _con.has(1):
		_cair_teste = 0
		print("REDE teste: derrubando a ligação")
		_con[1].close()
	if _dessinc_teste > 0 and _tick == _dessinc_teste:
		_dessinc_teste = 0
		print("REDE teste: mexendo no estado")
		game.units[0].global_position.x += 0.5  # meio metro: o caos faz o resto


func _quem_falta() -> String:
	var t := _tick
	var falta: PackedStringArray = []
	if anfitriao:
		var tem: Dictionary = _cmds.get(t, {})
		for p in _ativos:
			if not tem.has(p):
				falta.append(str(jogadores().get(p, {}).get("nome", "?")))
	return ", ".join(falta) if not falta.is_empty() else "a conexão"


func _desistir_dos_lentos() -> void:
	_esperando = 0.0
	_espera_ini = 0
	var tem: Dictionary = _cmds.get(_proximo, {})
	for p in _ativos.duplicate():
		if p != 1 and not tem.has(p):
			_ativos.erase(p)
			_eventos.append(["saiu", p])
			if multiplayer.multiplayer_peer and p in multiplayer.get_peers():
				multiplayer.multiplayer_peer.disconnect_peer(p)
	_montar_quadros()


func _enviar(t: int, c: Comando) -> void:
	var b := c.para_bytes()
	if anfitriao:
		_receber_cmd(1, t, b)
	else:
		_r_cmd.rpc_id(1, t, b)


@rpc("any_peer", "call_remote", "reliable")
func _r_cmd(t: int, b: PackedByteArray) -> void:
	if anfitriao:
		_receber_cmd(multiplayer.get_remote_sender_id(), t, b)


func _receber_cmd(p: int, t: int, b: PackedByteArray) -> void:
	# Só o quadro esperado e poucos à frente, e só o tamanho de um Comando:
	# um amigo com jogo adulterado não enche a memória nem a rede dos outros.
	if t < _proximo or t > _proximo + 64 or p not in _ativos or b.size() != 17:
		return
	if not _cmds.has(t):
		_cmds[t] = {}
	_cmds[t][p] = b
	_montar_quadros()


func _montar_quadros() -> void:
	while true:
		var tem: Dictionary = _cmds.get(_proximo, {})
		var completo := true
		for p in _ativos:
			if not tem.has(p):
				completo = false
				break
		if not completo:
			return
		var c := {}
		for p in _ativos:
			c[p] = tem[p]
		var q := {"c": c, "ev": _eventos.duplicate()}
		_eventos.clear()
		_cmds.erase(_proximo)
		_quadros[_proximo] = q
		_r_quadro.rpc(_proximo, q)
		_proximo += 1


@rpc("authority", "call_remote", "reliable")
func _r_quadro(t: int, q: Dictionary) -> void:
	_quadros[t] = q


@rpc("any_peer", "call_remote", "reliable")
func _r_hash(t: int, h: PackedInt64Array) -> void:
	if not anfitriao or _dessinc or game == null or not is_instance_valid(game):
		return
	if _hashes.has(t) and _hashes[t] != h:
		var meu: PackedInt64Array = _hashes[t]
		var i := 0
		while i < mini(meu.size(), h.size()) and meu[i] == h[i]:
			i += 1
		var p := multiplayer.get_remote_sender_id()
		var quem := str(jogadores().get(p, {}).get("nome", "?"))
		var onde := game.descrever_parte(i)
		_r_dessinc.rpc(t, quem, onde)
		_r_dessinc(t, quem, onde)
	for k in _hashes.keys():
		if int(k) < t - HASH_A_CADA * 10:
			_hashes.erase(k)


## A partida se separou: cada PC passou a ver um jogo diferente (Ciclo 2.28d:
## o Julio e o amigo seguiram jogando sem saber). Não dá para juntar de volta
## no lockstep, então avisa grande e, em 5 s, todos voltam para a sala; de lá é
## só Começar de novo. O aviso diz onde separou, para consertar a causa.
@rpc("authority", "call_remote", "reliable")
func _r_dessinc(t: int, quem: String, onde: String) -> void:
	if _dessinc:
		return
	_dessinc = true
	push_warning("Rede: dessincronizou no quadro %d (%s): %s" % [t, quem, onde])
	print("DESSINC %d %s | %s" % [t, quem, onde])
	if game and is_instance_valid(game) and game.hud:
		game.hud.show_big("A partida se separou entre os PCs\nvoltando todos para a sala...", Color(1, 0.6, 0.5), VOLTAR_DESSINC + 1.0)
		game.hud.dica_rede("Dessincronizou com %s  ·  voltando para a sala em %d s" % [quem, int(VOLTAR_DESSINC)])
	_aviso_depois("A partida se separou entre os PCs (dessincronia com %s) e todos voltaram para a sala. Cliquem Começar para jogar de novo. Para o Claude: quadro %d, %s, versão %s." % [quem, t, onde, versao()], Color(1, 0.7, 0.5))
	if anfitriao:
		_voltar_t = VOLTAR_DESSINC


# --- Comando local ----------------------------------------------------------------

## Toques (apertar) desde o último quadro: o quadro pode ter ficado parado
## esperando a rede, e o aperto não pode se perder.
func _toques() -> int:
	var b := 0
	if Input.is_action_just_pressed("quick"):
		b |= Comando.RAPIDA
	if Input.is_action_just_pressed("power"):
		b |= Comando.PODER
	if Input.is_action_just_pressed("super"):
		b |= Comando.SUPER
	if Input.is_action_just_pressed("dodge"):
		b |= Comando.ESQUIVA
	if Input.is_action_just_pressed("interact"):
		b |= Comando.INTERAGE
	return b


## Painel da escolha (caminho/herói) ou trocar de time: vai no próximo comando.
func pedir_acao(acao: int, a := 0, b := 0) -> void:
	_acao = [acao, a, b]


func _amostrar(delta: float) -> Comando:
	var c := Comando.new()
	if macaco:
		_macaco(c, delta)
	elif game.player_brain and not game.hud_bloqueia_mouse():
		game.player_brain.amostrar(c)
	c.botoes |= _latch
	_latch = 0
	if c.mira.length_squared() < 0.0001:
		c.mira = _mira_ult
	_mira_ult = c.mira
	if not _acao.is_empty():
		c.acao = _acao[0]
		c.acao_a = _acao[1]
		c.acao_b = _acao[2]
		_acao.clear()
	return c


## Jogador de mentira para o teste em rede do CI (--autoplay): anda,
## bate, defende e solta poderes ao acaso com um sorteio só dele.
func _macaco(c: Comando, delta: float) -> void:
	_macaco_t -= delta
	if _macaco_t <= 0.0:
		_macaco_t = _macaco_rng.randf_range(0.4, 1.5)
		var a := _macaco_rng.randf() * TAU
		_macaco_dir = Vector2(cos(a), sin(a)) * (1.0 if _macaco_rng.randf() < 0.8 else 0.0)
	c.move = _macaco_dir
	var p := game.player
	if p:
		var alvo := p.global_position + Vector3(_macaco_dir.x, 0, _macaco_dir.y) * 6.0
		c.ponto = alvo
		if _macaco_dir.length() > 0.1:
			c.mira = _macaco_dir.normalized()
		# Metade do tempo vai para cima do inimigo mais perto e mira nele: o
		# teste precisa de humano acertando gente (tiro, golpe, poder), não só
		# andando sozinho pela base (Ciclo 2.28d).
		var inimigo: Unit = null
		var melhor := 40.0
		for u in game.units:
			if u.alive and u.team != p.team:
				var d := u.global_position.distance_to(p.global_position)
				if d < melhor:
					melhor = d
					inimigo = u
		if inimigo and _macaco_rng.randf() < 0.5:
			var to := inimigo.global_position - p.global_position
			to.y = 0.0
			if to.length() > 0.1:
				c.mira = Vector2(to.x, to.z).normalized()
				c.move = c.mira if melhor > p.stats.attack_range * 0.8 else Vector2.ZERO
			c.ponto = inimigo.global_position
			c.alvo = game.units.find(inimigo)
	if _macaco_rng.randf() < 0.3:
		c.botoes |= Comando.ATAQUE
	elif _macaco_rng.randf() < 0.05:
		c.botoes |= Comando.DEFESA
	for b in [Comando.RAPIDA, Comando.PODER, Comando.SUPER, Comando.ESQUIVA, Comando.INTERAGE]:
		if _macaco_rng.randf() < 0.01:
			c.botoes |= b
