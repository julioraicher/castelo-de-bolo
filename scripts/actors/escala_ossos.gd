class_name EscalaOssos
extends SkeletonModifier3D
## Muda a escala de alguns ossos depois da animação (cabeça menor, mãos maiores,
## pernas mais compridas). Roda a cada quadro porque a animação reescreve a pose.
## Valor float = escala uniforme; Vector3 = escala por eixo do osso (y = ao longo
## do osso no esqueleto KayKit). `subir_quadril` compensa pernas mais compridas
## (senão os pés afundam no chão).

## nome do osso -> float ou Vector3
var escalas := {}
var subir_quadril := 0.0
var _idx := {}
var _quadril := -1


func _process_modification_with_delta(_delta: float) -> void:
	var sk := get_skeleton()
	if sk == null:
		return
	if _idx.is_empty():
		for nome in escalas:
			var v = escalas[nome]
			_idx[sk.find_bone(nome)] = v if v is Vector3 else Vector3.ONE * float(v)
		_quadril = sk.find_bone("hips")
	for b in _idx:
		if b >= 0:
			sk.set_bone_pose_scale(b, _idx[b])
	if subir_quadril != 0.0 and _quadril >= 0:
		sk.set_bone_pose_position(_quadril, sk.get_bone_pose_position(_quadril) + Vector3(0, subir_quadril, 0))
