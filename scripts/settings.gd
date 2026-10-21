extends Control

var acao_em_edicao: String = ""
var botoes: Dictionary = {}

const NOMES: Dictionary = {
	"mover_cima": "Jogador 1 — Subir",
	"mover_baixo": "Jogador 1 — Descer",
	"jogador2_cima": "Jogador 2 — Subir",
	"jogador2_baixo": "Jogador 2 — Descer"
}

const ACOES_CURTAS: Dictionary = {
	"mover_cima": "Subir",
	"mover_baixo": "Descer",
	"jogador2_cima": "Subir",
	"jogador2_baixo": "Descer"
}

@onready var aviso: Label = $Margem/Conteudo/Aviso

signal fechar_solicitado

var aberta_na_partida: bool = false


func _ready() -> void:
	botoes = {
		"mover_cima":
			$Margem/Conteudo/Jogadores/PainelJ1/MargemJ1/ColunaJ1/J1Cima,

		"mover_baixo":
			$Margem/Conteudo/Jogadores/PainelJ1/MargemJ1/ColunaJ1/J1Baixo,

		"jogador2_cima":
			$Margem/Conteudo/Jogadores/PainelJ2/MargemJ2/ColunaJ2/J2Cima,

		"jogador2_baixo":
			$Margem/Conteudo/Jogadores/PainelJ2/MargemJ2/ColunaJ2/J2Baixo
	}

	for acao in botoes:
		var botao: Button = botoes[acao]

		botao.pressed.connect(
			_iniciar_edicao.bind(acao)
		)

		botao.focus_mode = Control.FOCUS_NONE

	var restaurar: Button = $Margem/Conteudo/Rodape/Restaurar
	var voltar: Button = $Margem/Conteudo/Rodape/Voltar

	restaurar.focus_mode = Control.FOCUS_NONE
	voltar.focus_mode = Control.FOCUS_NONE

	restaurar.pressed.connect(_restaurar)
	voltar.pressed.connect(_voltar)

	atualizar_botoes()

func atualizar_botoes() -> void:
	for acao in botoes:
		var botao: Button = botoes[acao]

		botao.text = "%s: %s" % [
			ACOES_CURTAS[acao],
			Configuracoes.nome_tecla(acao)
		]

func _iniciar_edicao(acao: String) -> void:
	acao_em_edicao = acao
	atualizar_botoes()

	var botao: Button = botoes[acao]
	botao.text = "%s: …" % ACOES_CURTAS[acao]

	aviso.text = "Pressione uma tecla. Esc cancela."

func _input(event: InputEvent) -> void:
	if acao_em_edicao.is_empty():
		return

	if not event is InputEventKey:
		return

	if not event.pressed or event.echo:
		return

	get_viewport().set_input_as_handled()

	if event.keycode == KEY_ESCAPE:
		acao_em_edicao = ""
		aviso.text = ""
		atualizar_botoes()
		return

	var tecla: int = event.physical_keycode

	if tecla == 0:
		tecla = event.keycode

	if tecla in [KEY_ENTER, KEY_KP_ENTER]:
		aviso.text = "Enter está reservado. Escolha outra tecla."
		return

	for outra_acao in botoes:
		if outra_acao == acao_em_edicao:
			continue

		if Configuracoes.obter_tecla(outra_acao) == tecla:
			aviso.text = "Essa tecla já está em uso em: %s." % NOMES[outra_acao]
			return

	Configuracoes.definir_tecla(acao_em_edicao, tecla)
	Configuracoes.salvar()

	acao_em_edicao = ""
	aviso.text = "Controle salvo!"
	atualizar_botoes()


func _restaurar() -> void:
	acao_em_edicao = ""
	Configuracoes.restaurar_padrao()
	atualizar_botoes()
	aviso.text = "Controles padrão restaurados."


func _voltar() -> void:
	if aberta_na_partida:
		fechar_solicitado.emit()
		return

	get_tree().change_scene_to_file(
		"res://scenes/menu.tscn"
	)
