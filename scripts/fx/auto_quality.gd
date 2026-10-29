class_name AutoQuality
extends Node
## Mede o FPS no começo da partida e, se ficar abaixo de MIN_FPS, baixa um
## nível de qualidade gráfica e mede de novo, até ficar bom ou chegar na
## Mínima. Desliga em Esc > Configurações > Qualidade automática.

const WARMUP := 2.0    # s ignorados (carregamento, shaders compilando)
const WINDOW := 3.0    # s de medição em cada nível
const MIN_FPS := 40.0

var hud: Hud
var _t := 0.0
var _frames := 0


func _process(delta: float) -> void:
	if not Settings.auto_quality or get_tree().paused:
		return
	_t += delta
	if _t < WARMUP:
		return
	_frames += 1
	if _t < WARMUP + WINDOW:
		return
	var fps := _frames / WINDOW
	if fps >= MIN_FPS or Settings.quality == 0:
		set_process(false)  # está bom (ou não há mais o que baixar)
		return
	Settings.quality -= 1
	Settings.apply()
	Settings.save()
	if hud:
		hud.show_big("Qualidade: %s (%d FPS)\nmude em Esc > Configurações" % [Settings.QUALITIES[Settings.quality], int(fps)], Color(1, 0.9, 0.6), 2.0)
	_t = 0.0
	_frames = 0
