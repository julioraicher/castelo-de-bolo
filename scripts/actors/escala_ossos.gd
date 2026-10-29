class_name EscalaOssos
extends SkeletonModifier3D
## Muda a escala de alguns ossos depois da animação (ex.: cabeça menor).
## Roda a cada quadro porque a animação reescreve a pose dos ossos.

## nome do osso -> escala uniforme
var escalas := {}
var _idx := {}


func _process_modification_with_delta(_delta: float) -> void:
	var sk := get_skeleton()
	if sk == null:
		return
	if _idx.is_empty():
		for nome in escalas:
			_idx[sk.find_bone(nome)] = escalas[nome]
	for b in _idx:
		if b >= 0:
			sk.set_bone_pose_scale(b, Vector3.ONE * float(_idx[b]))
