extends Node

@export var raquete_esquerda: CharacterBody2D
@export var raquete_direita: CharacterBody2D
@export var bola: CharacterBody2D

@export var limite_superior: float = 104.0
@export var limite_inferior: float = 544.0
@export var metade_altura_raquete: float = 55.0


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(bola):
		return

	var alvo_y := clampf(
		bola.global_position.y,
		limite_superior + metade_altura_raquete,
		limite_inferior - metade_altura_raquete
	)

	seguir_bola(raquete_esquerda, alvo_y)
	seguir_bola(raquete_direita, alvo_y)


func seguir_bola(
	raquete: CharacterBody2D,
	alvo_y: float
) -> void:
	if not is_instance_valid(raquete):
		return

	raquete.global_position.y = alvo_y
