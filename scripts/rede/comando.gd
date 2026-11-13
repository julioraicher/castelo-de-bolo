class_name Comando
extends RefCounted
## Um quadro de intenções de um jogador humano (Ciclo 2.28, multiplayer).
## É tudo o que viaja pela rede no lockstep: cada PC roda a partida inteira e
## só recebe isto dos outros. Os números vão "quantizados" (inteiros), e o
## próprio dono também aplica a versão quantizada: assim todos os PCs usam os
## mesmos bits (um float de diferença dessincroniza em segundos: caos).
##
## Formato (17 bytes): botões u8 · move x,z s8 · mira dir x,z s16 ·
## ponto da mira x,y,z s16 (cm) · alvo s8 (índice em game.units, -1) ·
## ação u8 · ação a u8 · ação b u8.

const ATAQUE := 1
const DEFESA := 2
const RAPIDA := 4     # Q
const PODER := 8      # E
const SUPER := 16     # R
const ESQUIVA := 32   # espaço
const INTERAGE := 64  # F apertado agora
const SEGURA_F := 128 # F segurado (reanimar, desistir)

## Ações raras (uma por quadro): escolha de caminho/herói no painel e troca
## de time no meio da partida.
enum Acao { NADA, CAMINHO, HEROI, TROCAR_TIME }

var botoes := 0
var move := Vector2.ZERO        # -1..1
var mira := Vector2(0, 1)       # direção (x, z), normalizada ao aplicar
var ponto := Vector3.ZERO
var alvo := -1
var acao := Acao.NADA
var acao_a := 0
var acao_b := 0


func tem(b: int) -> bool:
	return botoes & b != 0


func para_bytes() -> PackedByteArray:
	var s := StreamPeerBuffer.new()
	s.put_u8(botoes)
	s.put_8(_q8(move.x))
	s.put_8(_q8(move.y))
	s.put_16(_q16(mira.x))
	s.put_16(_q16(mira.y))
	s.put_16(_cm(ponto.x))
	s.put_16(_cm(ponto.y))
	s.put_16(_cm(ponto.z))
	s.put_8(clampi(alvo, -1, 127))
	s.put_u8(acao)
	s.put_u8(clampi(acao_a, 0, 255))
	s.put_u8(clampi(acao_b, 0, 255))
	return s.data_array


static func de_bytes(b: PackedByteArray) -> Comando:
	var c := Comando.new()
	if b.size() < 17:
		return c
	var s := StreamPeerBuffer.new()
	s.data_array = b
	c.botoes = s.get_u8()
	c.move = Vector2(s.get_8() / 127.0, s.get_8() / 127.0)
	c.mira = Vector2(s.get_16() / 32767.0, s.get_16() / 32767.0)
	c.ponto = Vector3(s.get_16() / 100.0, s.get_16() / 100.0, s.get_16() / 100.0)
	c.alvo = s.get_8()
	c.acao = s.get_u8() as Acao
	c.acao_a = s.get_u8()
	c.acao_b = s.get_u8()
	return c


## A versão que todos os PCs vão usar (ida e volta pelos bytes).
func quantizado() -> Comando:
	return Comando.de_bytes(para_bytes())


static func vazio_bytes() -> PackedByteArray:
	return Comando.new().para_bytes()


static func _q8(v: float) -> int:
	return clampi(roundi(v * 127.0), -127, 127)


static func _q16(v: float) -> int:
	return clampi(roundi(v * 32767.0), -32767, 32767)


static func _cm(v: float) -> int:
	return clampi(roundi(v * 100.0), -32767, 32767)
