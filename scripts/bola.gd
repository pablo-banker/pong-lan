extends CharacterBody2D

signal ponto_marcado(lado: String)

@export var velocidade_inicial: float = 400.0
@export var velocidade_maxima: float = 800.0
@export var aumento_por_rebatida: float = 25.0

const CENTRO: Vector2 = Vector2(576.0, 324.0)
const LIMITE_ESQUERDO: float = -20.0
const LIMITE_DIREITO: float = 1172.0

var em_jogo: bool = false

var pausada: bool = false
var tempo_para_saque: float = 0.0


func _ready() -> void:
	em_jogo = false
	velocity = Vector2.ZERO
	position = CENTRO


func _physics_process(delta: float) -> void:
	var modo_local := (
		Configuracoes.modo == Configuracoes.Modo.LOCAL
	)

	if not modo_local and not multiplayer.is_server():
		return

	if pausada:
		return

	if tempo_para_saque > 0.0:
		tempo_para_saque -= delta

		if tempo_para_saque <= 0.0:
			sortear_direcao()
			em_jogo = true

		return

	if not em_jogo:
		return

	var colisao := move_and_collide(velocity * delta)

	if colisao:
		var objeto := colisao.get_collider()

		if objeto is CharacterBody2D:
			rebater_na_raquete(objeto)
			Audio.tocar_raquete()
		else:
			velocity = velocity.bounce(colisao.get_normal())
			Audio.tocar_parede()

	verificar_ponto()


func rebater_na_raquete(raquete: CharacterBody2D) -> void:
	# Perto do centro: trajetória mais horizontal.
	# Perto das pontas: trajetória mais inclinada.
	var distancia_do_centro := position.y - raquete.position.y
	var impacto := clampf(distancia_do_centro / 55.0, -1.0, 1.0)
	var angulo := impacto * deg_to_rad(60.0)

	# A bola deve sair na direção contrária à raquete.
	var direcao_horizontal: float = 1.0

	if velocity.x > 0.0:
		direcao_horizontal = -1.0

	var nova_velocidade := minf(
		velocity.length() + aumento_por_rebatida,
		velocidade_maxima
	)

	velocity = Vector2(
		cos(angulo) * direcao_horizontal,
		sin(angulo)
	) * nova_velocidade


func verificar_ponto() -> void:
	if position.x < LIMITE_ESQUERDO:
		registrar_ponto("direita")
	elif position.x > LIMITE_DIREITO:
		registrar_ponto("esquerda")


func registrar_ponto(lado: String) -> void:
	em_jogo = false
	velocity = Vector2.ZERO
	ponto_marcado.emit(lado)



func reiniciar() -> void:
	em_jogo = false
	velocity = Vector2.ZERO
	position = CENTRO
	tempo_para_saque = 1.0

func sortear_direcao() -> void:
	var direcao_horizontal: float = 1.0

	if randf() < 0.5:
		direcao_horizontal = -1.0

	# Evita um saque completamente horizontal.
	var angulo := randf_range(deg_to_rad(15.0), deg_to_rad(35.0))

	if randf() < 0.5:
		angulo = -angulo

	velocity = Vector2(
		cos(angulo) * direcao_horizontal,
		sin(angulo)
	) * velocidade_inicial
