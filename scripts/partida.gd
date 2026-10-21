extends Node2D

const PONTOS_PARA_VENCER: int = 5
const INTERVALO_REDE: float = 1.0 / 30.0

const SUAVIZACAO: float = 15.0

var recebeu_primeiro_estado: bool = false

var alvo_bola: Vector2 = Vector2.ZERO
var alvo_y_esquerda: float = 324.0
var alvo_y_direita: float = 324.0

var pontos_esquerda: int = 0
var pontos_direita: int = 0

var partida_iniciada: bool = false
var partida_encerrada: bool = false
var conexao_perdida: bool = false

var direcao_convidado: float = 0.0
var tempo_rede: float = 0.0
var texto_resultado: String = ""

var pausada: bool = false
var quem_pausou: int = 0
var tela_configuracoes: Control


var em_contagem: bool = false
var tempo_contagem: float = 0.0
var ultimo_numero: int = 3

var dialogo_saida: ConfirmationDialog

@onready var bola = $Bola
@onready var raquete_esquerda = $RaqueteEsquerda
@onready var raquete_direita = $RaqueteDireita

@onready var placar: Label = $HUD/Interface/Placar
@onready var mensagem: Label = $HUD/Mensagem

@onready var nome_esquerda: Label = $HUD/Interface/NomeEsquerda
@onready var nome_direita: Label = $HUD/Interface/NomeDireita

@onready var controles_esquerda: HBoxContainer = $HUD/Interface/ControlesEsquerda
@onready var controles_direita: HBoxContainer = $HUD/Interface/ControlesDireita

@onready var kbd_direita_cima = $HUD/Interface/ControlesDireita/Subir
@onready var kbd_direita_baixo = $HUD/Interface/ControlesDireita/Descer

@onready var painel_pausa: Control = $HUD/Pausa

@onready var descricao_pausa: Label = $HUD/Pausa/Centralizador/Painel/MargemInterna/Conteudo/Descricao

@onready var continuar: Button = $HUD/Pausa/Centralizador/Painel/MargemInterna/Conteudo/Continuar

@onready var configurar_pausa: Button = $HUD/Pausa/Centralizador/Painel/MargemInterna/Conteudo/Configurar

@onready var voltar_menu: Button = $HUD/Pausa/Centralizador/Painel/MargemInterna/Conteudo/VoltarMenu

@onready var contagem: Control = $HUD/Contagem
@onready var contagem_label: Label = $HUD/Contagem/Label

func _ready() -> void:
	Audio.tocar_musica_partida()
	
	configurar_hud()
	atualizar_placar()
	mensagem.text = "Preparando partida..."
	
	painel_pausa.hide()

	continuar.pressed.connect(_ao_continuar)
	configurar_pausa.pressed.connect(_abrir_configuracoes_pausa)
	voltar_menu.pressed.connect(_confirmar_saida)

	if eh_local():
		bola.ponto_marcado.connect(_ao_marcar_ponto)
		iniciar_partida()
		return

	Network.conexao_encerrada.connect(_ao_perder_conexao)

	if multiplayer.is_server():
		bola.ponto_marcado.connect(_ao_marcar_ponto)
	else:
		Network.avisar_partida_pronta.call_deferred()

func _process(delta: float) -> void:
	if eh_local():
		return
	
	if conexao_perdida:
		return

	if pausada:
		return

	if multiplayer.is_server():
		return

	if not recebeu_primeiro_estado:
		return

	var peso := 1.0 - exp(-SUAVIZACAO * delta)

	bola.position = bola.position.lerp(alvo_bola, peso)

	raquete_esquerda.position.y = lerpf(
		raquete_esquerda.position.y,
		alvo_y_esquerda,
		peso
	)

	raquete_direita.position.y = lerpf(
		raquete_direita.position.y,
		alvo_y_direita,
		peso
	)


func _physics_process(delta: float) -> void:
	if conexao_perdida:
		return

	if em_contagem:
		if eh_local() or multiplayer.is_server():
			processar_contagem(delta)

		return

	if pausada:
		return

	# Mantenha abaixo o processamento que já existia.
	if eh_local():
		processar_local(delta)
		return

	if multiplayer.is_server():
		processar_host(delta)
	else:
		processar_convidado(delta)
		
func configurar_hud() -> void:
	if eh_local():
		nome_esquerda.text = "Jogador 1"
		nome_direita.text = "Jogador 2"

		controles_esquerda.show()
		controles_direita.show()
		return

	var sou_host := multiplayer.is_server()

	nome_esquerda.text = "Você" if sou_host else "Adversário"
	nome_direita.text = "Adversário" if sou_host else "Você"

	controles_esquerda.visible = sou_host
	controles_direita.visible = not sou_host

	# Na LAN, o convidado usa seus controles do jogador 1.
	kbd_direita_cima.acao = &"mover_cima"
	kbd_direita_baixo.acao = &"mover_baixo"

	kbd_direita_cima.atualizar_texto()
	kbd_direita_baixo.atualizar_texto()


func eh_local() -> bool:
	return Configuracoes.modo == Configuracoes.Modo.LOCAL


func processar_local(delta: float) -> void:
	if partida_encerrada:
		return

	var direcao_jogador1 := Input.get_axis(
		"mover_cima",
		"mover_baixo"
	)

	var direcao_jogador2 := Input.get_axis(
		"jogador2_cima",
		"jogador2_baixo"
	)

	raquete_esquerda.mover(direcao_jogador1, delta)
	raquete_direita.mover(direcao_jogador2, delta)

func processar_host(delta: float) -> void:
	if not partida_iniciada:
		if not Network.partida_convidado_pronta:
			return

		iniciar_partida()

	if not partida_encerrada:
		var direcao_host := Input.get_axis(
			"mover_cima",
			"mover_baixo"
		)

		raquete_esquerda.mover(direcao_host, delta)
		raquete_direita.mover(direcao_convidado, delta)

	tempo_rede += delta

	if tempo_rede >= INTERVALO_REDE:
		tempo_rede = 0.0
		enviar_estado()


func processar_convidado(delta: float) -> void:
	tempo_rede += delta

	if tempo_rede < INTERVALO_REDE:
		return

	tempo_rede = 0.0

	var direcao := Input.get_axis(
		"mover_cima",
		"mover_baixo"
	)

	_receber_comando.rpc_id(1, direcao)


@rpc("any_peer", "call_remote", "unreliable_ordered", 1)
func _receber_comando(direcao: float) -> void:
	if not multiplayer.is_server():
		return

	if multiplayer.get_remote_sender_id() != Network.convidado_id:
		return

	direcao_convidado = clampf(direcao, -1.0, 1.0)


func enviar_estado() -> void:
	_receber_estado.rpc_id(
		Network.convidado_id,
		bola.position,
		raquete_esquerda.position.y,
		raquete_direita.position.y,
		pontos_esquerda,
		pontos_direita,
		partida_encerrada,
		texto_resultado
	)


@rpc("authority", "call_remote", "unreliable_ordered", 2)
func _receber_estado(
	posicao_bola: Vector2,
	y_esquerda: float,
	y_direita: float,
	placar_esquerda: int,
	placar_direita: int,
	encerrada: bool,
	resultado: String
) -> void:
	if multiplayer.is_server():
		return
		
	if pausada:
		return	

	var mudou_placar := (
		pontos_esquerda != placar_esquerda
		or pontos_direita != placar_direita
	)

	var reiniciou_partida := (
		partida_encerrada and not encerrada
	)

	alvo_bola = posicao_bola
	alvo_y_esquerda = y_esquerda
	alvo_y_direita = y_direita

	# Aplica imediatamente mudanças que representam
	# um reposicionamento, como o saque após um ponto.
	if not recebeu_primeiro_estado or reiniciou_partida:
		bola.position = alvo_bola
		raquete_esquerda.position.y = alvo_y_esquerda
		raquete_direita.position.y = alvo_y_direita
	elif mudou_placar:
		bola.position = alvo_bola

	recebeu_primeiro_estado = true

	pontos_esquerda = placar_esquerda
	pontos_direita = placar_direita
	partida_encerrada = encerrada
	partida_iniciada = true

	atualizar_placar()

	if partida_encerrada:
		mensagem.text = resultado + "\nAguardando o host reiniciar."
	else:
		mensagem.text = ""

func iniciar_partida() -> void:
	partida_iniciada = true
	partida_encerrada = false

	pontos_esquerda = 0
	pontos_direita = 0
	direcao_convidado = 0.0
	texto_resultado = ""

	raquete_esquerda.position.y = 324.0
	raquete_direita.position.y = 324.0

	mensagem.text = ""
	atualizar_placar()
	bola.reiniciar()


func _ao_marcar_ponto(lado: String) -> void:
	if partida_encerrada or conexao_perdida:
		return

	if lado == "esquerda":
		pontos_esquerda += 1
	elif lado == "direita":
		pontos_direita += 1
	else:
		return

	Audio.tocar_ponto()
	atualizar_placar()

	if pontos_esquerda >= PONTOS_PARA_VENCER:
		encerrar_partida("Jogador da esquerda venceu!")
	elif pontos_direita >= PONTOS_PARA_VENCER:
		encerrar_partida("Jogador da direita venceu!")
	else:
		bola.reiniciar()


func atualizar_placar() -> void:
	placar.text = "%d : %d" % [
		pontos_esquerda,
		pontos_direita
	]


func encerrar_partida(resultado: String) -> void:
	partida_encerrada = true
	texto_resultado = resultado

	bola.em_jogo = false
	bola.velocity = Vector2.ZERO

	mensagem.text = resultado + "\nPressione Enter para jogar novamente."


func _unhandled_input(event: InputEvent) -> void:
	if is_instance_valid(tela_configuracoes):
		return
		
	if is_instance_valid(dialogo_saida):
		return	

	if conexao_perdida:
		if event.is_action_pressed("ui_accept"):
			_sair_para_menu()
		return

	if event.is_action_pressed("ui_cancel"):
		solicitar_pausa(not pausada)
		get_viewport().set_input_as_handled()
		return

	if pausada:
		return

	if not eh_local() and not multiplayer.is_server():
		return

	if partida_encerrada and event.is_action_pressed("ui_accept"):
		iniciar_partida()

func _ao_perder_conexao() -> void:
	_fechar_configuracoes_pausa()
	em_contagem = false
	contagem.hide()
	painel_pausa.hide()
	conexao_perdida = true
	bola.em_jogo = false
	bola.velocity = Vector2.ZERO

	Network.desconectar()

	mensagem.text = "O outro jogador desconectou.\nPressione Enter para voltar ao menu."


func solicitar_pausa(valor: bool) -> void:
	if conexao_perdida or partida_encerrada:
		return

	if not partida_iniciada or em_contagem:
		return

	if eh_local():
		if valor:
			_aplicar_pausa(true, 0)
		elif pausada:
			_iniciar_contagem()
	elif multiplayer.is_server():
		_definir_pausa_host(valor, 1)
	else:
		_pedir_pausa.rpc_id(1, valor)

@rpc("any_peer", "call_remote", "reliable")
func _pedir_pausa(valor: bool) -> void:
	if not multiplayer.is_server():
		return

	var remetente := multiplayer.get_remote_sender_id()

	if remetente != Network.convidado_id:
		return

	_definir_pausa_host(valor, remetente)


func _definir_pausa_host(valor: bool, solicitante: int) -> void:
	if conexao_perdida or partida_encerrada:
		return

	if not partida_iniciada or em_contagem:
		return

	if valor:
		if pausada:
			return

		_sincronizar_pausa.rpc(
			true,
			solicitante,
			bola.position,
			raquete_esquerda.position.y,
			raquete_direita.position.y
		)
	else:
		if not pausada or quem_pausou != solicitante:
			return

		_iniciar_contagem.rpc()

@rpc("authority", "call_local", "reliable")
func _sincronizar_pausa(
	valor: bool,
	responsavel: int,
	posicao_bola: Vector2,
	y_esquerda: float,
	y_direita: float
) -> void:
	bola.position = posicao_bola
	raquete_esquerda.position.y = y_esquerda
	raquete_direita.position.y = y_direita

	# Mantém os alvos da interpolação na posição congelada.
	alvo_bola = posicao_bola
	alvo_y_esquerda = y_esquerda
	alvo_y_direita = y_direita

	_aplicar_pausa(valor, responsavel)


func _aplicar_pausa(valor: bool, responsavel: int) -> void:
	pausada = valor
	quem_pausou = responsavel
	bola.pausada = valor
	direcao_convidado = 0.0
	Audio.definir_pausa_musica(valor)

	if not valor:
		em_contagem = false
		tempo_contagem = 0.0
		contagem.hide()

		_fechar_configuracoes_pausa()
		painel_pausa.hide()
		return

	var posso_continuar := (
		eh_local()
		or multiplayer.get_unique_id() == quem_pausou
	)

	continuar.disabled = not posso_continuar

	if eh_local():
		descricao_pausa.text = "Pressione Esc para continuar."
	elif posso_continuar:
		descricao_pausa.text = "Você pausou a partida."
	else:
		descricao_pausa.text = "Aguardando o outro jogador continuar."

	painel_pausa.show()

	if posso_continuar:
		continuar.grab_focus()
	else:
		configurar_pausa.grab_focus()

func _abrir_configuracoes_pausa() -> void:
	if is_instance_valid(tela_configuracoes):
		return

	tela_configuracoes = preload(
		"res://scenes/settings.tscn"
	).instantiate()

	tela_configuracoes.aberta_na_partida = true
	tela_configuracoes.fechar_solicitado.connect(
		_fechar_configuracoes_pausa
	)

	$HUD.add_child(tela_configuracoes)


func _fechar_configuracoes_pausa() -> void:
	if not is_instance_valid(tela_configuracoes):
		return

	$HUD.remove_child(tela_configuracoes)
	tela_configuracoes.queue_free()
	tela_configuracoes = null

	atualizar_kbds()


func atualizar_kbds() -> void:
	var interface := $HUD/Interface

	interface.get_node(
		"ControlesEsquerda/Subir"
	).atualizar_texto()

	interface.get_node(
		"ControlesEsquerda/Descer"
	).atualizar_texto()

	interface.get_node(
		"ControlesDireita/Subir"
	).atualizar_texto()

	interface.get_node(
		"ControlesDireita/Descer"
	).atualizar_texto()
	
func _confirmar_saida() -> void:
	if is_instance_valid(dialogo_saida):
		return
		
	$HUD/Pausa/Centralizador.hide()

	dialogo_saida = ConfirmationDialog.new()

	dialogo_saida.theme = preload("res://ui/themes/tema.tres")

	# Remove a barra de título e a moldura padrão.
	dialogo_saida.borderless = true
	dialogo_saida.unresizable = true
	dialogo_saida.exclusive = true

	dialogo_saida.dialog_text = (
		"Voltar ao menu?\nA partida atual será encerrada."
	)

	dialogo_saida.ok_button_text = "Sair da partida"
	dialogo_saida.cancel_button_text = "Cancelar"

	# Fundo do diálogo.
	var estilo := StyleBoxFlat.new()

	estilo.bg_color = Color("#151F30")
	estilo.border_color = Color("#2A3850")

	estilo.set_border_width_all(1)
	estilo.set_corner_radius_all(8)

	estilo.content_margin_left = 24.0
	estilo.content_margin_right = 24.0
	estilo.content_margin_top = 24.0
	estilo.content_margin_bottom = 24.0

	dialogo_saida.add_theme_stylebox_override("panel", estilo)

	var texto := dialogo_saida.get_label()

	texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto.add_theme_font_size_override("font_size", 20)
	texto.add_theme_color_override(
		"font_color",
		Color("#F3F6FC")
	)

	var botao_sair := dialogo_saida.get_ok_button()
	var botao_cancelar := dialogo_saida.get_cancel_button()

	botao_sair.custom_minimum_size = Vector2(190, 48)
	botao_cancelar.custom_minimum_size = Vector2(190, 48)

	botao_sair.add_theme_font_size_override("font_size", 18)
	botao_cancelar.add_theme_font_size_override("font_size", 18)

	$HUD.add_child(dialogo_saida)

	dialogo_saida.confirmed.connect(_ao_confirmar_saida)
	dialogo_saida.canceled.connect(_fechar_dialogo_saida)

	dialogo_saida.popup_centered(Vector2i(480, 200))

	# A opção inicialmente selecionada preserva a partida.
	botao_cancelar.grab_focus()


func _sair_para_menu() -> void:
	if not eh_local():
		Network.desconectar()

	get_tree().change_scene_to_file(
		"res://scenes/menu.tscn"
	)

func _ao_continuar() -> void:
	solicitar_pausa(false)


@rpc("authority", "call_local", "reliable")
func _iniciar_contagem() -> void:
	em_contagem = true
	tempo_contagem = 3.0
	ultimo_numero = 3

	pausada = true
	bola.pausada = true
	direcao_convidado = 0.0

	_fechar_configuracoes_pausa()
	painel_pausa.hide()

	contagem.show()
	_mostrar_numero(3)

	get_viewport().gui_release_focus()


func processar_contagem(delta: float) -> void:
	tempo_contagem = maxf(tempo_contagem - delta, 0.0)

	if tempo_contagem <= 0.0:
		if eh_local():
			_aplicar_pausa(false, 0)
		else:
			_sincronizar_pausa.rpc(
				false,
				0,
				bola.position,
				raquete_esquerda.position.y,
				raquete_direita.position.y
			)

		return

	var numero := int(ceil(tempo_contagem))

	if numero != ultimo_numero:
		ultimo_numero = numero

		if eh_local():
			_mostrar_numero(numero)
		else:
			_mostrar_numero.rpc(numero)

func _ao_confirmar_saida() -> void:
	_fechar_dialogo_saida()
	_sair_para_menu()


func _fechar_dialogo_saida() -> void:
	if not is_instance_valid(dialogo_saida):
		return

	dialogo_saida.hide()
	dialogo_saida.queue_free()
	dialogo_saida = null

	if pausada and not conexao_perdida:
		$HUD/Pausa/Centralizador.show()
		voltar_menu.grab_focus()
		

@rpc("authority", "call_local", "reliable")
func _mostrar_numero(numero: int) -> void:
	contagem_label.text = str(numero)
	Audio.tocar_contagem()
