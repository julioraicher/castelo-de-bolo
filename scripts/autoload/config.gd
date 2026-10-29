extends Node
## Autoload "Config": acessível de qualquer script como `Config.cfg`.
## Também registra os controles (InputMap) e dá o tema e as cores dos times.

const TEAM_BLUE := 0
const TEAM_RED := 1
const TEAM_NAMES := ["Azul", "Vermelho"]

## Camadas de física (veja Projeto > Configurações > Nomes de camadas).
const LAYER_WORLD := 1
const LAYER_UNITS := 2
const LAYER_ITEMS := 4
const LAYER_PROJECTILES := 8

## Lista de controles mostrada na tela "Como jogar" e no menu de pausa.
## Se mudar uma tecla em _setup_input(), atualize aqui também.
const CONTROLS := [
	["W A S D", "andar"],
	["Mouse", "mirar"],
	["Clique esquerdo", "atacar"],
	["Clique direito (segurar)", "Guerreiro bloqueia · Arqueiro carrega o tiro · Clérigo cura"],
	["Q", "poder especial (quando o medidor de Glacê enche)"],
	["Espaço ou Shift", "esquivar (rolamento rápido)"],
	["E", "pegar chapéu, pegar/soltar a princesa"],
	["Esc ou P", "pausar, ver controles e configurações"],
	["F ou F11", "tela cheia"],
	["R", "reiniciar a partida"],
]

var cfg: GameConfig = preload("res://config/game_config.tres")


func _ready() -> void:
	_setup_input()


## Tema escolhido em Esc > Configurações (lista em game_config.tres > Mundo).
func theme() -> ThemeConfig:
	return cfg.themes[clampi(Settings.theme, 0, cfg.themes.size() - 1)]


func team_color(team: int) -> Color:
	return theme().team_colors[team]


func _setup_input() -> void:
	# Teclas registradas por código para ficarem visíveis num lugar só.
	# Você também pode editar em Projeto > Configurações do Projeto > Mapa de Entrada.
	_bind_keys("move_up", [KEY_W, KEY_UP])
	_bind_keys("move_down", [KEY_S, KEY_DOWN])
	_bind_keys("move_left", [KEY_A, KEY_LEFT])
	_bind_keys("move_right", [KEY_D, KEY_RIGHT])
	_bind_keys("interact", [KEY_E])
	_bind_keys("dodge", [KEY_SPACE, KEY_SHIFT])
	_bind_keys("restart", [KEY_R])
	_bind_keys("power", [KEY_Q])
	_bind_keys("pause", [KEY_ESCAPE, KEY_P])
	_bind_keys("fullscreen", [KEY_F, KEY_F11])
	_bind_mouse("attack", MOUSE_BUTTON_LEFT)
	_bind_mouse("skill", MOUSE_BUTTON_RIGHT)


func _bind_keys(action: StringName, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)


func _bind_mouse(action: StringName, button: MouseButton) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	InputMap.action_add_event(action, ev)
