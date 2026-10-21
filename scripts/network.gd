extends Node

signal sala_criada
signal jogador_conectado
signal conexao_confirmada
signal conexao_falhou
signal conexao_encerrada

const PORTA: int = 7000

var peer: ENetMultiplayerPeer
var convidado_id: int = 0

var partida_convidado_pronta: bool = false


func _ready() -> void:
	multiplayer.peer_connected.connect(_ao_conectar_jogador)
	multiplayer.peer_disconnected.connect(_ao_desconectar_jogador)
	multiplayer.connected_to_server.connect(_ao_conectar_servidor)
	multiplayer.connection_failed.connect(_ao_falhar_conexao)
	multiplayer.server_disconnected.connect(_ao_perder_servidor)


func criar_sala() -> Error:
	partida_convidado_pronta = false
	
	peer = ENetMultiplayerPeer.new()

	var erro := peer.create_server(PORTA, 1)

	if erro != OK:
		peer = null
		return erro

	multiplayer.multiplayer_peer = peer
	sala_criada.emit()
	return OK


func entrar_sala(ip: String) -> Error:
	peer = ENetMultiplayerPeer.new()

	var erro := peer.create_client(ip, PORTA)

	if erro != OK:
		peer = null
		return erro

	multiplayer.multiplayer_peer = peer
	return OK


func desconectar() -> void:
	if peer != null:
		peer.close()

	multiplayer.multiplayer_peer = null
	peer = null
	convidado_id = 0


func _ao_conectar_jogador(id: int) -> void:
	if multiplayer.is_server():
		convidado_id = id
		jogador_conectado.emit()


func _ao_desconectar_jogador(id: int) -> void:
	if id == convidado_id:
		convidado_id = 0
		conexao_encerrada.emit()


func _ao_conectar_servidor() -> void:
	conexao_confirmada.emit()


func _ao_falhar_conexao() -> void:
	desconectar()
	conexao_falhou.emit()


func _ao_perder_servidor() -> void:
	desconectar()
	conexao_encerrada.emit()
	
func avisar_cliente_pronto() -> void:
	_cliente_pronto.rpc_id(1)


@rpc("any_peer", "call_remote", "reliable")
func _cliente_pronto() -> void:
	if not multiplayer.is_server():
		return

	var remetente := multiplayer.get_remote_sender_id()

	if remetente != convidado_id:
		return

	_abrir_partida.rpc()


@rpc("authority", "call_local", "reliable")
func _abrir_partida() -> void:
	get_tree().change_scene_to_file.call_deferred(
		"res://scenes/partida.tscn"
	)


func avisar_partida_pronta() -> void:
	_confirmar_partida_pronta.rpc_id(1)


@rpc("any_peer", "call_remote", "reliable")
func _confirmar_partida_pronta() -> void:
	if not multiplayer.is_server():
		return

	if multiplayer.get_remote_sender_id() != convidado_id:
		return

	partida_convidado_pronta = true
