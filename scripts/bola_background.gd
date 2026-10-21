extends CharacterBody2D

@export var velocidade: float = 400.0
@export var centro: Vector2 = Vector2(576.0, 324.0)

@export var limite_esquerdo: float = -20.0
@export var limite_direito: float = 1172.0


func _ready() -> void:
	reiniciar()


func _physics_process(delta: float) -> void:
	var colisao := move_and_collide(velocity * delta)

	if colisao:
		var objeto := colisao.get_collider()

		velocity = velocity.bounce(colisao.get_normal())

		if objeto is CharacterBody2D:
			Audio.tocar_raquete(false, -22.0)
		else:
			Audio.tocar_parede(false, -24.0)

	if (
		position.x < limite_esquerdo
		or position.x > limite_direito
	):
		reiniciar()


func reiniciar() -> void:
	position = centro

	var sentido: float = 1.0

	if randf() < 0.5:
		sentido = -1.0

	velocity = Vector2(
		sentido,
		randf_range(-0.6, 0.6)
	).normalized() * velocidade
