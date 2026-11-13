extends Node
## Autoload "Sfx": toca efeitos sonoros e a música.
## Uso: Sfx.play("hit", posicao_3d)  ou  Sfx.play_ui("score").
## Os sons ficam em res://assets/audio/<nome>.ogg ou .wav (.ogg ganha se os dois existirem).
## Variações: <nome>_2.ogg, <nome>_3.ogg... tocam sorteadas (o golpe não soa sempre igual).
## Trocar um som: tools/sons/trocar_som.sh (ver .claude/skills/efeitos-sonoros/SKILL.md).

const SOUNDS := ["swing", "hit", "shoot", "magic", "heal", "pickup", "hat", "eat", "death", "score", "alarm", "dodge", "win", "lose", "block", "power", "power_ready",
	"lancar_metal", "pavio", "fogo", "luz", "sombra", "tinido", "flecha_chao", "brasa", "sino", "implosao", "explosao", "poder_boom", "nivel", "captura",
	"besta_virote", "besta_devolve", "torreta_pronta", "torreta_cai", "catapulta_arma", "catapulta_lanca", "catapulta_meteoro",
	# Assinatura por classe (ClassStats.som_*) e eventos que estavam mudos.
	"samurai_poder", "samurai_final", "sombra_entra", "sombra_sai", "ninja_poder", "ninja_final",
	"kitsune_poder", "kitsune_super", "luz_poder", "sombra_poder", "mutirao", "super_maior",
	"madeira_golpe", "renascer", "corte_critico",
	# Reanimar (Ciclo 2.18): pano arrastando no chão e o "voltou" com sino.
	"reanimar_arrasto", "reanimado",
	# Camada do kit de magia (Ciclo 2.20): um som curto por elemento.
	"magia_selo", "magia_fogo", "magia_vento", "magia_luz", "magia_estouro",
	# Heróis raros (Ciclo 2.23): tools/sons/sintetizar_herois.py + Kenney.
	"papel", "agua", "grasnido", "flauta",
	# Assinatura das 14 classes que estavam no som genérico (2.25c): gerar_sons.py assinaturas2.
	"armadilheiro_poder", "armadilheiro_super", "armadilheiro_final", "arqueiro_yumi_poder", "arqueiro_yumi_super", "arqueiro_yumi_final", "bombardeiro_poder", "bombardeiro_super", "bombardeiro_final", "ronin_oni_poder", "ronin_oni_super", "ronin_oni_final", "sumotori_poder", "sumotori_super", "sumotori_final", "kappa_poder", "kappa_super", "kappa_final", "yamabushi_poder", "yamabushi_super", "yamabushi_final", "karasu_tengu_poder", "karasu_tengu_super", "karasu_tengu_final", "onmyoji_poder", "onmyoji_super", "onmyoji_final", "komuso_poder", "komuso_super", "komuso_final", "mujina_poder", "mujina_super", "mujina_final", "tennin_poder", "tennin_super", "tennin_final",
	"sohei_poder", "sohei_super", "sohei_final", "kusarigama_poder", "kusarigama_super", "kusarigama_final",
	"kitsune_final", "kitsune_luz_final", "kitsune_sombria_final",
	# Heróis 2.27 (Ochimusha, Shishimai, Jorogumo): gerar_sons.py herois227.
	"ochimusha_poder", "ochimusha_super", "ochimusha_final", "ochimusha_fantasma", "ochimusha_flecha", "ochimusha_onibi", "ochimusha_caidos",
	"shishimai_poder", "shishimai_super", "shishimai_final", "shishimai_mordida", "shishimai_sino", "shishimai_taiko", "shishimai_festa",
	"jorogumo_poder", "jorogumo_super", "jorogumo_final", "jorogumo_teia", "jorogumo_fios", "jorogumo_casulo", "seda", "seda_gruda",
	# Heróis 2.27b
	"kodama_poder", "kodama_super", "kodama_final", "kodama_semente", "kodama_brota", "kodama_raizes", "kodama_bosque", "kodama_cai", "kodama_floresta",
	"kaminari_kozo_poder", "kaminari_kozo_super", "kaminari_kozo_final", "kaminari_choque", "kaminari_carga", "kaminari_trovao", "kaminari_relampago", "kaminari_tambor"]
const POOL_SIZE := 32

const MAX_VARIACOES := 8

var _streams := {}  # nome -> Array[AudioStream] (1 ou mais variações)
var _pool: Array[AudioStreamPlayer3D] = []
var _next := 0
var _ui: AudioStreamPlayer
var _music: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # música e sons do menu tocam com o jogo pausado
	for s in SOUNDS:
		var lista: Array[AudioStream] = []
		var base: AudioStream = _carregar("res://assets/audio/%s" % s)
		if base:
			lista.append(base)
		for i in range(2, MAX_VARIACOES + 1):
			var v: AudioStream = _carregar("res://assets/audio/%s_%d" % [s, i])
			if v == null:
				break
			lista.append(v)
		if not lista.is_empty():
			_streams[s] = lista
	for i in POOL_SIZE:
		var p := AudioStreamPlayer3D.new()
		p.bus = "Efeitos"
		p.unit_size = 18.0
		p.max_db = 3.0
		add_child(p)
		_pool.append(p)
	_ui = AudioStreamPlayer.new()
	_ui.bus = "Efeitos"
	add_child(_ui)
	_music = AudioStreamPlayer.new()
	_music.bus = "Musica"
	_music.volume_db = 0.0  # a música gerada já é baixinha; atenuar mais a fazia sumir
	add_child(_music)


func _carregar(sem_extensao: String) -> AudioStream:
	for ext in [".ogg", ".wav"]:
		if ResourceLoader.exists(sem_extensao + ext):
			return load(sem_extensao + ext)
	return null


func _sortear(sound: String) -> AudioStream:
	var lista: Array = _streams[sound]
	return lista[randi() % lista.size()]


## pitch < 1 = mais grave (golpe pesado), > 1 = mais agudo (acerto leve/de longe).
func play(sound: String, at: Vector3, pitch_jitter := 0.08, pitch := 1.0, volume_db := 0.0) -> void:
	if not _streams.has(sound):
		return
	var p := _pool[_next]
	_next = (_next + 1) % POOL_SIZE
	p.stream = _sortear(sound)
	p.global_position = at
	p.pitch_scale = pitch + randf_range(-pitch_jitter, pitch_jitter)
	p.volume_db = volume_db
	p.play()


func has(sound: String) -> bool:
	return _streams.has(sound)


func play_ui(sound: String) -> void:
	if _streams.has(sound):
		_ui.stream = _sortear(sound)
		_ui.play()


## Morte súbita: a mesma música, um pouco mais rápida e aguda.
func musica_tensa(liga: bool) -> void:
	if _music:
		_music.pitch_scale = 1.12 if liga else 1.0


func start_music() -> void:
	musica_tensa(false)
	var path := "res://assets/audio/music.wav"
	if ResourceLoader.exists(path) and not _music.playing:
		# O loop vem da importação (music.wav.import: loop_mode=2, "Forward"), que funciona
		# igual no .exe e no navegador. Religar no sinal finished deixava um
		# buraco e, no navegador, podia nem tocar de novo.
		_music.stream = load(path)
		_music.play()
