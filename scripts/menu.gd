extends Node2D

@export_group("Grupos")
@export var opcoes_iniciais: Control
@export var opcoes_jogar: Control

@export_group("Menu inicial")
@export var jogar: Button
@export var configurar: Button
@export var sair: Button

@export_group("Opções de jogo")
@export var jogar_local: Button
@export var criar_sala: Button
@export var entrar_sala: Button
@export var voltar: Button

@export_group("Painel de conexão")
@export var conexao: Control
@export var titulo_conexao: Label
@export var descricao: Label
@export var ip_local: LineEdit
@export var endereco_ip: LineEdit
@export var status: Label
@export var conectar: Button
@export var cancelar: Button

var conectando: bool = false
var criando_sala: bool = false


func _ready() -> void:
	Audio.tocar_musica_menu()
	
	jogar.pressed.connect(_abrir_opcoes_jogar)
	configurar.pressed.connect(_ao_configurar)
	sair.pressed.connect(_ao_sair)

	jogar_local.pressed.connect(_ao_jogar_local)
	criar_sala.pressed.connect(_ao_criar_sala)
	entrar_sala.pressed.connect(_abrir_entrada)
	voltar.pressed.connect(_abrir_menu_inicial)

	conectar.pressed.connect(_ao_conectar)
	cancelar.pressed.connect(_fechar_conexao)
	endereco_ip.text_submitted.connect(_ao_confirmar_ip)

	Network.sala_criada.connect(_ao_sala_criada)
	Network.jogador_conectado.connect(_ao_jogador_conectado)
	Network.conexao_confirmada.connect(_ao_conexao_confirmada)
	Network.conexao_falhou.connect(_ao_conexao_falhou)
	Network.conexao_encerrada.connect(_ao_conexao_encerrada)

	conexao.hide()
	definir_menu_bloqueado(false)
	_abrir_menu_inicial()


func _abrir_menu_inicial() -> void:
	opcoes_jogar.hide()
	opcoes_iniciais.show()
	jogar.grab_focus()


func _abrir_opcoes_jogar() -> void:
	if OS.has_feature("web"):
		_ao_jogar_local()
		return
	
	opcoes_iniciais.hide()
	opcoes_jogar.show()
	jogar_local.grab_focus()


func _ao_jogar_local() -> void:
	Network.desconectar()
	Configuracoes.modo = Configuracoes.Modo.LOCAL

	get_tree().change_scene_to_file(
		"res://scenes/partida.tscn"
	)


func _ao_configurar() -> void:
	get_tree().change_scene_to_file(
		"res://scenes/settings.tscn"
	)


func _ao_sair() -> void:
	get_tree().quit()


func _preparar_painel() -> void:
	conectando = false
	status.text = ""
	cancelar.text = "Voltar"

	conectar.disabled = false
	endereco_ip.editable = true

	definir_menu_bloqueado(true)
	conexao.show()


func _ao_criar_sala() -> void:
	_preparar_painel()
	criando_sala = true

	titulo_conexao.text = "Criar sala LAN"
	descricao.text = "Compartilhe seu IP com o outro jogador."

	ip_local.text = obter_ips_locais()
	ip_local.show()

	endereco_ip.hide()
	conectar.hide()
	cancelar.text = "Cancelar sala"

	Configuracoes.modo = Configuracoes.Modo.LAN

	var erro := Network.criar_sala()

	if erro != OK:
		status.text = "Não foi possível criar a sala: %s" % error_string(erro)

	cancelar.grab_focus()


func _abrir_entrada() -> void:
	_preparar_painel()
	criando_sala = false

	titulo_conexao.text = "Entrar na sala LAN"
	descricao.text = "Informe o IP do host na mesma rede."

	ip_local.hide()
	endereco_ip.show()
	conectar.show()
	endereco_ip.grab_focus()


func _ao_conectar() -> void:
	if conectando or criando_sala:
		return

	var ip := endereco_ip.text.strip_edges()

	if not ip.is_valid_ip_address():
		status.text = "Informe um endereço IP válido."
		return

	conectando = true
	conectar.disabled = true
	endereco_ip.editable = false
	status.text = "Conectando..."
	cancelar.text = "Cancelar"

	Configuracoes.modo = Configuracoes.Modo.LAN

	var erro := Network.entrar_sala(ip)

	if erro != OK:
		status.text = "Não foi possível conectar: %s" % error_string(erro)
		_liberar_tentativa()


func _ao_confirmar_ip(_texto: String) -> void:
	_ao_conectar()


func _ao_sala_criada() -> void:
	status.text = "Aguardando outro jogador..."


func _ao_jogador_conectado() -> void:
	status.text = "Jogador conectado! Preparando partida..."


func _ao_conexao_confirmada() -> void:
	status.text = "Conectado! Abrindo a partida..."
	Network.avisar_cliente_pronto()


func _ao_conexao_falhou() -> void:
	status.text = "Sala não encontrada. Confira o IP."
	_liberar_tentativa()


func _ao_conexao_encerrada() -> void:
	Network.desconectar()
	status.text = "A conexão foi encerrada."
	_liberar_tentativa()


func _liberar_tentativa() -> void:
	conectando = false
	conectar.disabled = false
	endereco_ip.editable = true
	cancelar.text = "Voltar"

	if endereco_ip.visible:
		endereco_ip.grab_focus()


func _fechar_conexao() -> void:
	Network.desconectar()

	conectando = false
	criando_sala = false

	conexao.hide()
	definir_menu_bloqueado(false)
	_abrir_opcoes_jogar()


func definir_menu_bloqueado(bloqueado: bool) -> void:
	jogar.disabled = bloqueado
	configurar.disabled = bloqueado
	sair.disabled = bloqueado

	jogar_local.disabled = bloqueado
	criar_sala.disabled = bloqueado
	entrar_sala.disabled = bloqueado
	voltar.disabled = bloqueado


func obter_ips_locais() -> String:
	var enderecos: PackedStringArray = []

	for ip in IP.get_local_addresses():
		if ip.contains(":"):
			continue

		if ip.begins_with("127."):
			continue

		if ip.begins_with("169.254."):
			continue

		if ip == "0.0.0.0":
			continue

		enderecos.append(ip)

	if enderecos.is_empty():
		return "Nenhum IPv4 encontrado"

	return ", ".join(enderecos)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return

	if conexao.visible:
		_fechar_conexao()
	elif opcoes_jogar.visible:
		_abrir_menu_inicial()
	else:
		return

	get_viewport().set_input_as_handled()
