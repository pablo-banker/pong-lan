extends Node

enum Modo {
	LOCAL,
	LAN
}

var modo: Modo = Modo.LOCAL

const CAMINHO: String = "user://configuracoes.cfg"

const TECLAS_PADRAO: Dictionary = {
	"mover_cima": KEY_W,
	"mover_baixo": KEY_S,
	"jogador2_cima": KEY_UP,
	"jogador2_baixo": KEY_DOWN
}


func _ready() -> void:
	carregar()


func definir_tecla(acao: String, tecla: int) -> void:
	if not InputMap.has_action(acao):
		InputMap.add_action(acao)

	InputMap.action_erase_events(acao)

	var evento := InputEventKey.new()
	evento.physical_keycode = tecla

	InputMap.action_add_event(acao, evento)


func obter_tecla(acao: String) -> int:
	for evento in InputMap.action_get_events(acao):
		if evento is InputEventKey:
			if evento.physical_keycode != 0:
				return evento.physical_keycode

			return evento.keycode

	return 0


func nome_tecla(acao: String) -> String:
	var tecla := obter_tecla(acao)

	if tecla == 0:
		return "Sem tecla"

	return OS.get_keycode_string(tecla)


func salvar() -> void:
	var arquivo := ConfigFile.new()

	for acao in TECLAS_PADRAO:
		arquivo.set_value("controles", acao, obter_tecla(acao))

	var erro := arquivo.save(CAMINHO)

	if erro != OK:
		push_warning("Não foi possível salvar os controles.")


func carregar() -> void:
	var arquivo := ConfigFile.new()
	arquivo.load(CAMINHO)

	for acao in TECLAS_PADRAO:
		var tecla: int = int(
			arquivo.get_value(
				"controles",
				acao,
				TECLAS_PADRAO[acao]
			)
		)

		definir_tecla(acao, tecla)


func restaurar_padrao() -> void:
	for acao in TECLAS_PADRAO:
		definir_tecla(acao, TECLAS_PADRAO[acao])

	salvar()
