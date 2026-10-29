extends Node
## Autoload "Settings": preferências do jogador (volume, tela cheia,
## dificuldade...). Salvas em user://configuracoes.cfg, então valem para
## a próxima vez que o jogo abrir. No navegador ficam no próprio navegador.

signal changed

const PATH := "user://configuracoes.cfg"
const DIFFICULTIES := ["Fácil", "Normal", "Difícil"]

var music_volume := 0.6      # 0..1
var sfx_volume := 0.9        # 0..1
var fullscreen := false
var camera_shake := true
var damage_numbers := true
var difficulty := 1          # índice em DIFFICULTIES


func _ready() -> void:
	_ensure_bus("Musica")
	_ensure_bus("Efeitos")
	_load()
	apply()


## Multiplicador do tempo de reação dos bots INIMIGOS (maior = mais lentos).
func bot_reaction_mult() -> float:
	return [1.9, 1.0, 0.55][difficulty]


## Dano causado pelos bots inimigos, relativo ao normal.
func bot_damage_mult() -> float:
	return [0.7, 1.0, 1.2][difficulty]


func apply() -> void:
	_set_bus_volume("Musica", music_volume)
	_set_bus_volume("Efeitos", sfx_volume)
	if OS.get_name() != "Web":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
	changed.emit()


func save() -> void:
	var f := ConfigFile.new()
	for key in ["music_volume", "sfx_volume", "fullscreen", "camera_shake", "damage_numbers", "difficulty"]:
		f.set_value("jogo", key, get(key))
	f.save(PATH)


func _load() -> void:
	var f := ConfigFile.new()
	if f.load(PATH) != OK:
		return
	for key in ["music_volume", "sfx_volume", "fullscreen", "camera_shake", "damage_numbers", "difficulty"]:
		if f.has_section_key("jogo", key):
			set(key, f.get_value("jogo", key))


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)
		AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")


func _set_bus_volume(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(linear, 0.0001)))
	AudioServer.set_bus_mute(idx, linear <= 0.001)
