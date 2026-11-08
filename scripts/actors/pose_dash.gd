class_name PoseDash
extends SkeletonModifier3D
## Corrida ninja do dash (Personagens 2.0): depois da animação, joga os dois
## braços para trás e para baixo, retos, como quem corre cortando o vento.
## `peso` 0..1 vem de Unit (sobe no começo do dash e desce no fim). Mexe só no
## braço de cima; antebraço e mão seguem pela hierarquia.

var peso := 0.0
var _bracos := PackedInt32Array()
var _antebracos := PackedInt32Array()


func _process_modification_with_delta(_delta: float) -> void:
	var sk := get_skeleton()
	if sk == null or peso <= 0.001:
		return
	if _bracos.is_empty():
		for lado in [".l", ".r"]:
			_bracos.append(sk.find_bone("upperarm" + lado))
			_antebracos.append(sk.find_bone("lowerarm" + lado))
	for i in 2:
		var b := _bracos[i]
		if b < 0:
			continue
		# Frente do boneco = +z no esqueleto KayKit: alvo atrás (-z), baixo e
		# um pouco para fora do corpo.
		var sx := 1.0 if i == 0 else -1.0
		var alvo := Vector3(0.28 * sx, -0.55, -1.0).normalized()
		var gp := sk.get_bone_global_pose(b)
		var dir := gp.basis.y.normalized()
		var q := Quaternion(dir, alvo).slerp(Quaternion.IDENTITY, 1.0 - peso) if dir.dot(alvo) > -0.999 else Quaternion.IDENTITY
		sk.set_bone_global_pose(b, Transform3D(Basis(q) * gp.basis, gp.origin))
		# Antebraço esticado (cotovelo quase reto).
		var a := _antebracos[i]
		if a >= 0:
			sk.set_bone_pose_rotation(a, sk.get_bone_pose_rotation(a).slerp(Quaternion.IDENTITY, peso * 0.8))
