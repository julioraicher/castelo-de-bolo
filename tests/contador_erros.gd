extends Logger
## Conta os erros do motor e de script enquanto um teste roda (caça 2026-11-19, TS-01).
## Na 4.7 um SCRIPT ERROR aborta só a função em que aconteceu: quem chamou segue
## e o processo sairia com código 0, então o CI ficaria verde com o teste quebrado.
## Uso: var c = load("res://tests/contador_erros.gd").instalar()  ...  c.erros
## Avisos (push_warning) não contam. Os logs chegam de qualquer thread: Mutex.

var erros: Array[String] = []
var _trava := Mutex.new()


static func instalar() -> Logger:
	var c: Logger = load("res://tests/contador_erros.gd").new()
	OS.add_logger(c)
	return c


func _log_error(function: String, file: String, line: int, code: String, rationale: String,
		_editor_notify: bool, error_type: int, _pilha: Array[ScriptBacktrace]) -> void:
	if error_type == ERROR_TYPE_WARNING:
		return
	var texto := rationale if rationale != "" else code
	_trava.lock()
	erros.append("%s:%d (%s) %s" % [file, line, function, texto])
	_trava.unlock()


func _log_message(_message: String, _error: bool) -> void:
	pass


## Resumo para o fim do teste: lista os erros e devolve quantos foram.
func relatar(rotulo: String) -> int:
	_trava.lock()
	var lista := erros.duplicate()
	_trava.unlock()
	for e in lista:
		print("%s: ERRO DURANTE O TESTE: %s" % [rotulo, e])
	return lista.size()
