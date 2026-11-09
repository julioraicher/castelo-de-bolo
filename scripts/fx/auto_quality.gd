class_name AutoQuality
extends Node
## Mede o FPS no começo da partida e baixa a qualidade até ficar bom.
## Na Alta (Ciclo 2.19, "Alta dinâmica"): antes de cair para a Média, desliga
## itens DENTRO da Alta, do menos visível ao mais visível (Settings.ALTA_AJUSTES:
## resolução 80% -> sem glow -> sem contorno no cenário), medindo de novo a cada
## degrau. A meta da Alta é segurar 30 FPS (mede com folga: 32). Abaixo da Alta
## vale a meta antiga de 40. Desliga em Esc > Configurações > Qualidade automática.

const WARMUP := 2.0    # s ignorados (carregamento, shaders compilando)
const WINDOW := 3.0    # s de medição em cada nível
const MIN_FPS := 40.0
const MIN_FPS_ALTA := 32.0  # mira 30 com folga de medição

var hud: Hud
var _t := 0.0
var _frames := 0


## Próximo degrau depois de (quality, ajuste): primeiro os ajustes da Alta,
## depois os níveis. Devolve o mesmo par quando não há mais o que baixar.
static func degrau(quality: int, ajuste: int) -> Vector2i:
	if quality == 3 and ajuste < Settings.ALTA_AJUSTES.size() - 1:
		return Vector2i(3, ajuste + 1)
	if quality > 0:
		return Vector2i(quality - 1, 0)
	return Vector2i(0, ajuste)


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
	var alvo := MIN_FPS_ALTA if Settings.quality == 3 else MIN_FPS
	var prox := degrau(Settings.quality, Settings.alta_ajuste)
	if fps >= alvo or prox == Vector2i(Settings.quality, Settings.alta_ajuste):
		set_process(false)  # está bom (ou não há mais o que baixar)
		return
	Settings.quality = prox.x
	Settings.alta_ajuste = prox.y
	Settings.apply()
	Settings.save()
	if hud:
		var msg := "Alta dinâmica: %s (%d FPS)" % [Settings.ALTA_AJUSTES[Settings.alta_ajuste], int(fps)] \
				if Settings.quality == 3 \
				else "Gráficos: %s (%d FPS)" % [Settings.QUALITIES[Settings.quality], int(fps)]
		hud.show_big(msg + "\nMude em Esc › Configurações", Color(1, 0.9, 0.6), 2.0)
	_t = 0.0
	_frames = 0
