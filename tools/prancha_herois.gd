extends "res://tools/prancha_personagens.gd"
## Prancha dos heróis raros (Ciclo 2.23): cada herói de perto em 4 ângulos
## (frente, 3/4, lado, costas), uma imagem por herói (13 desde o 2.27b), e uma fileira no fim
## ao lado de Samurai, Ninja e Kitsune na câmera do jogo.
## Uso: xvfb-run ... -s tools/prancha_herois.gd -- DIR [ids,separados]

var herois := ["sumotori", "kappa", "yamabushi", "karasu_tengu", "mujina", "onmyoji", "tennin", "komuso", "ochimusha", "shishimai", "jorogumo", "kodama", "kaminari_kozo"]


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		dir = args[0]
	if args.size() > 1:
		herois = Array(args[1].split(","))
	DirAccess.make_dir_recursive_absolute(dir)
	_montar_herois()


func _montar_herois() -> void:
	root.size = Vector2i(1280, 720)
	cena = Node3D.new()
	root.add_child(cena)
	_ambiente()
	for h in herois.size():
		var chao := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(60, 30)
		chao.mesh = pm
		chao.position.x = h * 100
		chao.material_override = Fx_plano(Color(0.02, 0.022, 0.045))
		cena.add_child(chao)
	var angulos := [0.0, -PI * 0.25, -PI * 0.5, PI]
	for h in herois.size():
		var cls: Resource = load("res://config/classes/%s.tres" % herois[h])
		for v in 4:
			var b := _boneco(cls, AZUL)
			b.position = Vector3(h * 100 + (v - 1.5) * 1.9, 0, 0)
			b.rotation.y = angulos[v]
	var grupo := ["guerreiro", "arqueiro", "kitsune"] + herois
	for i in grupo.size():
		var cls: Resource = load("res://config/classes/%s.tres" % grupo[i])
		for t in 2:
			var b := _boneco(cls, AZUL if t == 0 else VERMELHO)
			b.position = Vector3(3000 + (i - (grupo.size() - 1) / 2.0) * 2.6, 0, (t - 0.5) * 3.5)
			b.rotation.y = PI if t == 1 else 0.0
	cam = Camera3D.new()
	cena.add_child(cam)
	await _quadros(8)
	for h in herois.size():
		cam.fov = 30
		cam.position = Vector3(h * 100, 1.6, 9.5)
		cam.look_at(Vector3(h * 100, 1.1, 0))
		await _salvar("%s.png" % herois[h])
	cam.fov = 42
	cam.position = Vector3(3000, 19, 17)
	cam.look_at(Vector3(3000, 0, 0))
	await _salvar("jogo.png")
	quit()
