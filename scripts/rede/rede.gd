extends Node
## Autoload "Rede" (Ciclo 2.28): jogar com amigos.
##
## Sala: um de vocês é o anfitrião (servidor ENet no próprio PC); o jogo
## pede ao roteador para abrir a porta (UPnP) e mostra um código. Na mesma
## rede (ou no Radmin VPN) a sala aparece sozinha na lista (aviso UDP).
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
var _dessinc := false
var _macaco_rng := RandomNumberGenerator.new()
var _macaco_dir := Vector2.ZERO
var _macaco_t := 0.0
var _mira_ult := Vector2(0, 1)

var _enet: ENetMultiplayerPeer
var _udp: PacketPeerUDP
var _udp_t := 0.0
var _escuta: PacketPeerUDP
var _upnp: UPNP
var _upnp_thread: Thread
var _ping_t := 0.0
var _auto_n := 0          # --hospedar-teste=N: começa sozinho com N jogadores
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
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--hospedar-teste="):
			_auto_n = int(arg.trim_prefix("--hospedar-teste="))
			hospedar.call_deferred(meu_nome, false)
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
	if anfitriao:
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
	Menus.pular_inicio = true
	Game.sandbox_pedido = false
	Game.time_pedido = int(eu().get("time", 0))
	get_tree().paused = false
	get_tree().reload_current_scene()


@rpc("authority", "call_remote", "reliable")
func _r_voltar() -> void:
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


func _on_peer_entrou(_p: int) -> void:
	pass  # espera o "olá" com nome e versão


func _on_peer_saiu(p: int) -> void:
	if not anfitriao:
		return
	var nome: String = jogadores().get(p, {}).get("nome", "Alguém")
	if em_partida:
		if p in _ativos:
			_ativos.erase(p)
			_eventos.append(["saiu", p])
			_montar_quadros()
	else:
		jogadores().erase(p)
		_espalhar()
	aviso.emit("%s saiu." % nome, Color(1, 0.8, 0.5))


func _on_conectou() -> void:
	_r_ola.rpc_id(1, meu_nome, versao())


func _on_falhou() -> void:
	aviso.emit("Não achei a sala. Confira o código; se for de outra casa, o anfitrião talvez precise do Radmin VPN.", Color(1, 0.55, 0.5))
	sair()


func _on_servidor_caiu() -> void:
	var estava := em_partida
	sair()
	aviso.emit("O anfitrião fechou a sala.", Color(1, 0.55, 0.5))
	if estava:
		Menus.abrir_sala = true
		get_tree().paused = false
		get_tree().reload_current_scene()


# --- Porta (UPnP), IPs e lista da rede local ---------------------------------------

func _upnp_abrir() -> void:
	var u := UPNP.new()
	var res := {"ok": false, "ip": ""}
	if u.discover(2000, 2, "InternetGatewayDevice") == UPNP.UPNP_RESULT_SUCCESS \
			and u.get_gateway() and u.get_gateway().is_valid_gateway():
		var r := u.add_port_mapping(PORTA, PORTA, "Castelo de Bolo", "UDP", 0)
		res.ok = r == UPNP.UPNP_RESULT_SUCCESS
		res.ip = u.query_external_address()
	_upnp_fim.call_deferred(res, u)


func _upnp_fim(res: Dictionary, u: UPNP) -> void:
	if not online or not anfitriao:
		return
	if res.ok:
		_upnp = u
	var ip: String = res.ip
	if res.ok and ip != "" and not CodigoSala.ip_privado(ip):
		codigo_internet = CodigoSala.gerar(ip)
		upnp_texto = "Porta aberta: amigos de outras casas entram com o código."
	elif ip != "" and CodigoSala.ip_privado(ip):
		upnp_texto = "Seu provedor não deixa receber conexão (CGNAT). Amigo de outra casa: usem o Radmin VPN e o código dele."
	else:
		upnp_texto = "O roteador não abriu a porta sozinho. Amigo de outra casa: usem o Radmin VPN (grátis) e o código dele."
	sala_mudou.emit()


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
				salas_lan[ip] = {"nome": str(d.get("n", "?")), "n": int(d.get("q", 1)), "versao": str(d.get("v", "")), "visto": Time.get_ticks_msec()}
				mudou = true
		for ip in salas_lan.keys():
			if Time.get_ticks_msec() - int(salas_lan[ip].visto) > 3500:
				salas_lan.erase(ip)
				mudou = true
		if mudou:
			salas_lan_mudaram.emit()
	if not online or not anfitriao:
		return
	if _udp and not em_partida:
		_udp_t -= delta
		if _udp_t <= 0.0:
			_udp_t = 1.0
			var msg := JSON.stringify({"j": "CDB", "v": versao(), "n": meu_nome, "q": jogadores().size()})
			_udp.put_packet(msg.to_utf8_buffer())
	_ping_t -= delta
	if _ping_t <= 0.0 and _enet:
		_ping_t = 1.0
		var mudou_ping := false
		for p in jogadores():
			if p == 1 or p not in multiplayer.get_peers():
				continue
			var pp := _enet.get_peer(p)
			if pp:
				var ms := int(pp.get_statistic(ENetPacketPeer.PEER_ROUND_TRIP_TIME))
				if absi(ms - int(jogadores()[p].ping)) >= 5:
					jogadores()[p].ping = ms
					mudou_ping = true
		if mudou_ping and not em_partida:
			_espalhar()
	if _auto_n > 0 and not em_partida and jogadores().size() >= _auto_n:
		_auto_n = 0
		comecar()


# --- Lockstep --------------------------------------------------------------------

## Game chama ao montar a partida online (depois de criar as unidades).
func iniciar_partida(g: Game) -> void:
	game = g
	_tick = 1
	_quadros.clear()
	_cmds.clear()
	_hashes.clear()
	_eventos.clear()
	_acao.clear()
	_latch = 0
	_esperando = 0.0
	_dessinc = false
	_macaco_rng.seed = hash(id())
	_ativos.clear()
	for p in jogadores():
		_ativos.append(int(p))
	_ativos.sort()
	# Os primeiros quadros não têm comando de ninguém (o atraso ainda não passou).
	var vazio := {}
	for p in _ativos:
		vazio[p] = Comando.vazio_bytes()
	for t in range(1, atraso + 1):
		_quadros[t] = {"c": vazio.duplicate(), "ev": []}
	_proximo = atraso + 1


func _physics_process(delta: float) -> void:
	if not em_partida or game == null or not is_instance_valid(game):
		return
	if not macaco:
		_latch |= _toques()
	if not _quadros.has(_tick):
		get_tree().paused = true
		_esperando += delta
		if _esperando >= ESPERA_AVISO and game.hud:
			game.hud.dica_rede("Esperando %s..." % _quem_falta())
		if anfitriao and _esperando >= ESPERA_LIMITE:
			_desistir_dos_lentos()
		return
	if _esperando >= ESPERA_AVISO and game.hud:
		game.hud.dica_rede(game.dica_fim())
	_esperando = 0.0
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
		var h := game.hash_estado()
		if anfitriao:
			_hashes[_tick - 1] = h
		else:
			_r_hash.rpc_id(1, _tick - 1, h)
	_enviar(_tick + atraso, _amostrar(delta))
	_tick += 1


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
	var tem: Dictionary = _cmds.get(_proximo, {})
	for p in _ativos.duplicate():
		if p != 1 and not tem.has(p):
			_ativos.erase(p)
			_eventos.append(["saiu", p])
			if _enet:
				_enet.disconnect_peer(p)
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
	if t < _proximo or p not in _ativos:
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
func _r_hash(t: int, h: int) -> void:
	if not anfitriao or _dessinc:
		return
	if _hashes.has(t) and int(_hashes[t]) != h:
		var p := multiplayer.get_remote_sender_id()
		_r_dessinc.rpc(t, str(jogadores().get(p, {}).get("nome", "?")))
		_r_dessinc(t, str(jogadores().get(p, {}).get("nome", "?")))
	for k in _hashes.keys():
		if int(k) < t - HASH_A_CADA * 10:
			_hashes.erase(k)


@rpc("authority", "call_remote", "reliable")
func _r_dessinc(t: int, quem: String) -> void:
	if _dessinc:
		return
	_dessinc = true
	push_warning("Rede: dessincronizou no quadro %d (%s)" % [t, quem])
	print("DESSINC %d %s" % [t, quem])
	if game and game.hud:
		game.hud.show_big("A partida dessincronizou com %s\n(conte para o Claude: quadro %d)" % [quem, t], Color(1, 0.6, 0.5), 6.0)


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
	if _macaco_rng.randf() < 0.3:
		c.botoes |= Comando.ATAQUE
	elif _macaco_rng.randf() < 0.05:
		c.botoes |= Comando.DEFESA
	for b in [Comando.RAPIDA, Comando.PODER, Comando.SUPER, Comando.ESQUIVA, Comando.INTERAGE]:
		if _macaco_rng.randf() < 0.01:
			c.botoes |= b
