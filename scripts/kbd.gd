extends PanelContainer

@export var acao: StringName = &"mover_cima"
@export var texto_fixo: String = ""
@export var acompanhar_input: bool = true
@export var cor_destaque: Color = Color("#5B9DFF")

var estilo: StyleBoxFlat
var estava_pressionada: bool = false

@onready var tecla: Label = $Tecla


func _ready() -> void:
	# Cada instância precisa de seu próprio estilo.
	estilo = get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	add_theme_stylebox_override("panel", estilo)

	atualizar_texto()
	atualizar_visual(false)


func _process(_delta: float) -> void:
	var pressionada := false

	if acompanhar_input and InputMap.has_action(acao):
		pressionada = Input.is_action_pressed(acao)

	if pressionada != estava_pressionada:
		atualizar_visual(pressionada)


func atualizar_texto() -> void:
	if not texto_fixo.is_empty():
		tecla.text = texto_fixo
		return

	tecla.text = Configuracoes.nome_tecla(String(acao))


func atualizar_visual(pressionada: bool) -> void:
	estava_pressionada = pressionada

	if pressionada:
		estilo.bg_color = cor_destaque
		estilo.border_color = cor_destaque
		tecla.add_theme_color_override(
			"font_color",
			Color("#0B1220")
		)
	else:
		estilo.bg_color = Color("#0B1220")
		estilo.border_color = Color("#9AA8BC")
		tecla.add_theme_color_override(
			"font_color",
			Color("#F3F6FC")
		)
