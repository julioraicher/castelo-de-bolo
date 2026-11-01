class_name TutorialClipe
extends TextureRect
## "GIF" do tutorial: sequência de quadros JPG (00.jpg, 01.jpg...) numa pasta.
## Godot não lê GIF; quadros importados funcionam no navegador e no .exe.
## Os quadros só carregam na 1ª vez que a aba abre e tocam em loop.

const MAX_QUADROS := 80

var pasta := ""
var fps := 10.0
var _quadros: Array[Texture2D] = []
var _carregado := false
var _t := 0.0


static func novo(p_pasta: String, tam: Vector2, p_fps: float) -> TutorialClipe:
	var c := TutorialClipe.new()
	c.pasta = p_pasta
	c.fps = p_fps
	c.custom_minimum_size = tam
	c.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	c.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	c.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.set_process(false)
	return c


func _quadro(i: int) -> String:
	return "%s/%02d.jpg" % [pasta, i]


func tem_quadros() -> bool:
	return ResourceLoader.exists(_quadro(0))


func tocar(sim: bool) -> void:
	if sim and not _carregado:
		_carregado = true
		for i in MAX_QUADROS:
			if not ResourceLoader.exists(_quadro(i)):
				break
			_quadros.append(load(_quadro(i)))
		if not _quadros.is_empty():
			texture = _quadros[0]
	set_process(sim and _quadros.size() > 1)


func _process(delta: float) -> void:
	_t += delta
	texture = _quadros[int(_t * fps) % _quadros.size()]
