extends Node
## Autoload "Settings": preferências do jogador (volume, tela cheia,
## dificuldade...). Salvas em user://configuracoes.cfg, então valem para
## a próxima vez que o jogo abrir. No navegador ficam no próprio navegador.

signal changed

const PATH := "user://configuracoes.cfg"
const DIFFICULTIES := ["Fácil", "Normal", "Difícil"]
const QUALITIES := ["Mínima", "Baixa", "Média", "Alta"]
const KEYS := ["music_volume", "sfx_volume", "fullscreen", "camera_shake", "damage_numbers", "difficulty", "quality", "show_fps", "theme", "auto_quality"]

var music_volume := 0.8      # 0..1
var sfx_volume := 0.9        # 0..1
var fullscreen := false
var camera_shake := true
var damage_numbers := true
var difficulty := 1          # índice em DIFFICULTIES
## Índice em QUALITIES. No navegador começa em Média (WebGL é mais lento).
var quality := 2 if OS.get_name() == "Web" else 3
## Baixa a qualidade sozinho se o FPS ficar baixo no começo da partida (AutoQuality).
var auto_quality := true
var show_fps := false
var theme := 0               # índice em GameConfig.themes


func _ready() -> void:
	# Os canais vêm de res://default_bus_layout.tres (carregado antes de tudo,
	# inclusive no navegador). Criar aqui é só um plano B.
	_ensure_bus("Musica")
	_ensure_bus("Efeitos")
	_load()
	apply()


## Multiplicador do tempo de reação dos bots INIMIGOS (maior = mais lentos).
func bot_reaction_mult() -> float:
	return [1.9, 1.0, 0.75][difficulty]


## Dano causado pelos bots inimigos, relativo ao normal.
func bot_damage_mult() -> float:
	return [0.7, 1.0, 1.05][difficulty]


func apply() -> void:
	_set_bus_volume("Musica", music_volume)
	_set_bus_volume("Efeitos", sfx_volume)
	_apply_quality_viewport()
	if OS.get_name() != "Web":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
	changed.emit()


func save() -> void:
	var f := ConfigFile.new()
	for key in KEYS:
		f.set_value("jogo", key, get(key))
	f.save(PATH)


func _load() -> void:
	var f := ConfigFile.new()
	if f.load(PATH) != OK:
		return
	for key in KEYS:
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


## Parte da qualidade que vale para a janela inteira. Sombras e brilho ficam
## na Arena, que escuta o sinal `changed`.
func _apply_quality_viewport() -> void:
	if not is_inside_tree():
		return
	var vp := get_viewport()
	vp.msaa_3d = Viewport.MSAA_2X if quality == 3 else Viewport.MSAA_DISABLED
	# Renderiza o 3D numa resolução menor e amplia. Pixels pintados ∝ escala²:
	# 0,75 -> 56% dos pixels; 0,5 -> 25%. Ajuda muito quando a GPU é o gargalo.
	vp.scaling_3d_scale = [0.5, 0.75, 1.0, 1.0][quality]
