class_name Sinal
extends Node
## Quadro de recados da conexão automática (Ciclo 2.28c). Antes de ligar
## direto (WebRTC), anfitrião e amigo trocam meia dúzia de recados: "oi",
## a descrição da conexão (SDP) e os endereços candidatos (ICE). Os recados
## passam pelo ntfy.sh (serviço público de avisos, sem conta) num tópico
## tirado do código da sala, CIFRADOS com uma chave tirada do mesmo código:
## o ntfy só vê lixo e não guarda nada (Cache: no). Quem não tem o código
## não acha o tópico, não lê e não forja recado (HMAC).
## Testes: --sinal-dir=DIR troca o ntfy por arquivos numa pasta (sem internet).

signal recado(d: Dictionary)
signal aberto
signal caiu

const SERVIDOR := "ntfy.sh"

var _topico := ""
var _chave := PackedByteArray()
var _chave_mac := PackedByteArray()
var _ws: WebSocketPeer
var _aberto := false
var _fila: Array[String] = []
var _http: HTTPRequest
var _enviando := false
var _dir := ""
var _vistos := {}
var _poll_t := 0.0
var _crypto := Crypto.new()


static func _sha(texto: String) -> PackedByteArray:
	var h := HashingContext.new()
	h.start(HashingContext.HASH_SHA256)
	h.update(texto.to_utf8_buffer())
	return h.finish()


## Tópico e chaves só dependem do código (as 8 letras, sem traço).
func abrir(codigo: String) -> void:
	fechar()
	var c := codigo.to_upper().replace("-", "")
	_topico = "cdb1_" + _sha("cdb1-topico:" + c).hex_encode().left(24)
	_chave = _sha("cdb1-chave:" + c)
	_chave_mac = _sha("cdb1-mac:" + c)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--sinal-dir="):
			_dir = arg.trim_prefix("--sinal-dir=").path_join(_topico)
	if _dir != "":
		DirAccess.make_dir_recursive_absolute(_dir)
		for f in DirAccess.get_files_at(_dir):
			_vistos[f] = true  # recado velho de outra rodada não conta
		_aberto = true
		aberto.emit.call_deferred()
		return
	_ws = WebSocketPeer.new()
	_ws.connect_to_url("wss://%s/%s/ws" % [SERVIDOR, _topico])
	if _http == null:
		_http = HTTPRequest.new()
		_http.timeout = 10.0
		_http.request_completed.connect(_on_enviado)
		add_child(_http)


func fechar() -> void:
	if _ws:
		_ws.close()
	_ws = null
	_aberto = false
	_fila.clear()
	_enviando = false
	if _http:
		_http.cancel_request()
	_dir = ""
	_vistos.clear()


func esta_aberto() -> bool:
	return _aberto


func enviar(d: Dictionary) -> void:
	if _topico == "":
		return
	var txt := _cifrar(JSON.stringify(d).to_utf8_buffer())
	if _dir != "":
		var nome := "%d_%d.txt" % [Time.get_ticks_usec(), randi() % 100000]
		var f := FileAccess.open(_dir.path_join(nome + ".tmp"), FileAccess.WRITE)
		if f:
			f.store_string(txt)
			f.close()
			DirAccess.rename_absolute(_dir.path_join(nome + ".tmp"), _dir.path_join(nome))
		return
	_fila.append(txt)
	_mandar_proximo()


func _mandar_proximo() -> void:
	if _enviando or _fila.is_empty() or _http == null:
		return
	_enviando = true
	var corpo: String = _fila.pop_front()
	var cab := PackedStringArray(["Cache: no", "Firebase: no", "Content-Type: text/plain"])
	if _http.request("https://%s/%s" % [SERVIDOR, _topico], cab, HTTPClient.METHOD_POST, corpo) != OK:
		_enviando = false


func _on_enviado(_res: int, _codigo: int, _cab: PackedStringArray, _corpo: PackedByteArray) -> void:
	_enviando = false
	_mandar_proximo()


func _process(delta: float) -> void:
	if _dir != "":
		_poll_t -= delta
		if _poll_t > 0.0:
			return
		_poll_t = 0.05
		var fs := Array(DirAccess.get_files_at(_dir))
		fs.sort()
		for f: String in fs:
			if f.ends_with(".tmp") or _vistos.has(f):
				continue
			_vistos[f] = true
			_ler(FileAccess.get_file_as_string(_dir.path_join(f)))
		return
	if _ws == null:
		return
	_ws.poll()
	match _ws.get_ready_state():
		WebSocketPeer.STATE_OPEN:
			if not _aberto:
				_aberto = true
				aberto.emit()
			while _ws.get_available_packet_count() > 0:
				var m = JSON.parse_string(_ws.get_packet().get_string_from_utf8())
				if m is Dictionary and m.get("event") == "message":
					_ler(str(m.get("message", "")))
		WebSocketPeer.STATE_CLOSED:
			_ws = null
			_aberto = false
			caiu.emit()


func _ler(txt: String) -> void:
	var bruto := _decifrar(txt.strip_edges())
	if bruto.is_empty():
		return
	var d = JSON.parse_string(bruto.get_string_from_utf8())
	if d is Dictionary:
		recado.emit(d)


# --- Cifra: AES-256-CBC + HMAC-SHA256 (16 bytes), tudo em base64 -----------------

func _cifrar(dados: PackedByteArray) -> String:
	var pad := 16 - dados.size() % 16
	for i in pad:
		dados.append(pad)
	var iv := _crypto.generate_random_bytes(16)
	var aes := AESContext.new()
	aes.start(AESContext.MODE_CBC_ENCRYPT, _chave, iv)
	var ct := aes.update(dados)
	aes.finish()
	var corpo := iv + ct
	var mac := _crypto.hmac_digest(HashingContext.HASH_SHA256, _chave_mac, corpo).slice(0, 16)
	return Marshalls.raw_to_base64(corpo + mac)


func _decifrar(txt: String) -> PackedByteArray:
	if txt.length() > 8000:
		return PackedByteArray()
	var b := Marshalls.base64_to_raw(txt)
	if b.size() < 48 or (b.size() - 32) % 16 != 0:
		return PackedByteArray()
	var corpo := b.slice(0, b.size() - 16)
	var mac := _crypto.hmac_digest(HashingContext.HASH_SHA256, _chave_mac, corpo).slice(0, 16)
	if not _crypto.constant_time_compare(mac, b.slice(b.size() - 16)):
		return PackedByteArray()  # sem a chave (ou adulterado): ignora
	var aes := AESContext.new()
	aes.start(AESContext.MODE_CBC_DECRYPT, _chave, corpo.slice(0, 16))
	var pt := aes.update(corpo.slice(16))
	aes.finish()
	var pad := pt[pt.size() - 1] if pt.size() > 0 else 0
	if pad < 1 or pad > 16:
		return PackedByteArray()
	return pt.slice(0, pt.size() - pad)
