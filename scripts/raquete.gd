@tool
extends CharacterBody2D

@export var velocidade: float = 450.0

@export var cor: Color = Color("#5B9DFF"):
	set(valor):
		cor = valor

		if is_node_ready():
			atualizar_cor()

const METADE_ALTURA: float = 55.0
const TOPO_QUADRA: float = 104.0
const BASE_QUADRA: float = 544.0


func _ready() -> void:
	var glow := $Glow as ColorRect

	if glow.material is ShaderMaterial:
		glow.material = glow.material.duplicate()

	atualizar_cor()


func atualizar_cor() -> void:
	var poligono := $Polygon2D as Polygon2D
	var glow := $Glow as ColorRect

	poligono.color = cor
	glow.color = cor

	var material_glow := glow.material as ShaderMaterial

	if material_glow:
		material_glow.set_shader_parameter("cor", cor)


func mover(direcao: float, delta: float) -> void:
	direcao = clampf(direcao, -1.0, 1.0)

	position.y += direcao * velocidade * delta

	position.y = clampf(
		position.y,
		TOPO_QUADRA + METADE_ALTURA,
		BASE_QUADRA - METADE_ALTURA
	)
