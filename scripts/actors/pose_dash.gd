class_name PoseDash
extends SkeletonModifier3D
## Pose do corpo por cima da animação (Personagens 2.0 + Ciclo 2.34). Mexe só
## em três lugares do esqueleto KayKit e o resto segue pela hierarquia:
##  - braços (`peso` no dash "ninja", `bracos` correndo pela personalidade):
##    jogados para trás e para baixo, retos, como quem corre cortando o vento;
##  - peito (`coluna`, rad): + curva o tronco para a frente, − estufa o peito;
##  - cabeça (`ergue` para cima/baixo, `rola` de lado), em rad.
## Os valores vêm de Unit a cada quadro (Personalidade). Só visual.

var peso := 0.0
var bracos := 0.0
var coluna := 0.0
var ergue := 0.0
var rola := 0.0
var _bracos := PackedInt32Array()
var _antebracos := PackedInt32Array()
var _peito := -1
var _cabeca := -1


func _process_modification_with_delta(_delta: float) -> void:
	var sk := get_skeleton()
	if sk == null:
		return
	if _bracos.is_empty():
		for lado in [".l", ".r"]:
			_bracos.append(sk.find_bone("upperarm" + lado))
			_antebracos.append(sk.find_bone("lowerarm" + lado))
		_peito = sk.find_bone("chest")
		_cabeca = sk.find_bone("head")
	# Frente do boneco = +z no esqueleto KayKit: girar em volta de +x leva o
	# eixo y do osso para +z, ou seja, curva para a frente.
	if absf(coluna) > 0.001 and _peito >= 0:
		var gp := sk.get_bone_global_pose(_peito)
		sk.set_bone_global_pose(_peito, Transform3D(Basis(Vector3.RIGHT, coluna) * gp.basis, gp.origin))
	if (absf(ergue) > 0.001 or absf(rola) > 0.001) and _cabeca >= 0:
		var gp := sk.get_bone_global_pose(_cabeca)
		var giro := Basis(Vector3.RIGHT, -ergue) * Basis(Vector3.BACK, rola)
		sk.set_bone_global_pose(_cabeca, Transform3D(giro * gp.basis, gp.origin))
	var w := maxf(peso, bracos)
	if w <= 0.001:
		return
	for i in 2:
		var b := _bracos[i]
		if b < 0:
			continue
		# Alvo atrás (-z), baixo e um pouco para fora do corpo.
		var sx := 1.0 if i == 0 else -1.0
		var alvo := Vector3(0.28 * sx, -0.55, -1.0).normalized()
		var gp := sk.get_bone_global_pose(b)
		var dir := gp.basis.y.normalized()
		var q := Quaternion(dir, alvo).slerp(Quaternion.IDENTITY, 1.0 - w) if dir.dot(alvo) > -0.999 else Quaternion.IDENTITY
		sk.set_bone_global_pose(b, Transform3D(Basis(q) * gp.basis, gp.origin))
		# Antebraço esticado (cotovelo quase reto).
		var a := _antebracos[i]
		if a >= 0:
			sk.set_bone_pose_rotation(a, sk.get_bone_pose_rotation(a).slerp(Quaternion.IDENTITY, w * 0.8))
