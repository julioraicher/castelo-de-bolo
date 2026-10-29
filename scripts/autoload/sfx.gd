extends Node
## Autoload "Sfx": toca efeitos sonoros e a música.
## Uso: Sfx.play("hit", posicao_3d)  ou  Sfx.play_ui("score").
## Os sons ficam em res://assets/audio/<nome>.wav (gerados por tools/gerar_sons.py).

const SOUNDS := ["swing", "hit", "shoot", "magic", "heal", "pickup", "hat", "eat", "death", "score", "alarm", "dodge", "win", "lose"]
const POOL_SIZE := 24

var _streams := {}
var _pool: Array[AudioStreamPlayer3D] = []
var _next := 0
var _ui: AudioStreamPlayer
var _music: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # música e sons do menu tocam com o jogo pausado
	for s in SOUNDS:
		var path := "res://assets/audio/%s.wav" % s
		if ResourceLoader.exists(path):
			_streams[s] = load(path)
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


func play(sound: String, at: Vector3, pitch_jitter := 0.08) -> void:
	if not _streams.has(sound):
		return
	var p := _pool[_next]
	_next = (_next + 1) % POOL_SIZE
	p.stream = _streams[sound]
	p.global_position = at
	p.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	p.play()


func play_ui(sound: String) -> void:
	if _streams.has(sound):
		_ui.stream = _streams[sound]
		_ui.play()


func start_music() -> void:
	var path := "res://assets/audio/music.wav"
	if ResourceLoader.exists(path) and not _music.playing:
		# O loop vem da importação (music.wav.import: loop_mode=2, "Forward"), que funciona
		# igual no .exe e no navegador. Religar no sinal finished deixava um
		# buraco e, no navegador, podia nem tocar de novo.
		_music.stream = load(path)
		_music.play()
