extends Node

@export_group("Interface")
@export var som_hover: AudioStream
@export var som_clique: AudioStream

@export_group("Partida")
@export var som_parede: AudioStream
@export var som_raquete: AudioStream
@export var som_contagem: AudioStream
@export var som_ponto: AudioStream

@export_group("Música")
# Mantém o campo antigo como música do menu.
@export var musica_fundo: AudioStream
@export var musica_partida: AudioStream

@export_range(-40.0, 0.0) var volume_musica_db: float = -20.0
@export_range(0.1, 2.0) var duracao_fade: float = 0.6

const VOLUME_SILENCIO: float = -60.0
const REDUCAO_PAUSA: float = 8.0

var player_hover: AudioStreamPlayer
var player_clique: AudioStreamPlayer
var player_parede: AudioStreamPlayer
var player_raquete: AudioStreamPlayer
var player_contagem: AudioStreamPlayer
var player_ponto: AudioStreamPlayer

var player_menu: AudioStreamPlayer
var player_partida: AudioStreamPlayer

var musica_atual: AudioStreamPlayer
var tween_musica: Tween
var musica_em_pausa: bool = false


func _ready() -> void:
	player_hover = criar_player("Interface", -14.0)
	player_clique = criar_player("Interface", -10.0)

	player_parede = criar_player("Efeitos", -10.0)
	player_raquete = criar_player("Efeitos", -8.0)
	player_contagem = criar_player("Efeitos", -10.0)
	player_ponto = criar_player("Efeitos", -8.0)

	player_menu = criar_player("Musica", VOLUME_SILENCIO)
	player_partida = criar_player("Musica", VOLUME_SILENCIO)
	

	player_menu.max_polyphony = 1
	player_partida.max_polyphony = 1

	player_menu.stream = musica_fundo
	player_partida.stream = musica_partida

	get_tree().node_added.connect(_ao_adicionar_no)
	registrar_botoes(get_tree().root)

	tocar_musica_menu()


func criar_player(
	bus: String,
	volume: float
) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()

	if OS.has_feature("web"):
		player.playback_type = AudioServer.PLAYBACK_TYPE_STREAM

	player.bus = bus
	player.volume_db = volume
	player.max_polyphony = 8

	add_child(player)

	return player
	
# BOTÕES

func registrar_botoes(no: Node) -> void:
	if no is Button:
		conectar_botao(no)

	for filho in no.get_children():
		registrar_botoes(filho)


func _ao_adicionar_no(no: Node) -> void:
	if no is Button:
		conectar_botao.call_deferred(no)


func conectar_botao(botao: Button) -> void:
	if not is_instance_valid(botao):
		return

	var callback_hover := _ao_hover.bind(botao)

	if not botao.mouse_entered.is_connected(callback_hover):
		botao.mouse_entered.connect(callback_hover)

	if not botao.pressed.is_connected(tocar_clique):
		botao.pressed.connect(tocar_clique)


func _ao_hover(botao: Button) -> void:
	if botao.disabled or not botao.is_visible_in_tree():
		return

	reproduzir(player_hover, som_hover)


func tocar_clique() -> void:
	reproduzir(player_clique, som_clique)


func reproduzir(
	player: AudioStreamPlayer,
	stream: AudioStream
) -> void:
	if stream == null:
		return

	player.stream = stream
	player.play()


func tocar_ponto() -> void:
	if multiplayer.multiplayer_peer != null:
		if multiplayer.is_server():
			_reproduzir_ponto.rpc()
		return

	_reproduzir_ponto()


@rpc("authority", "call_local", "reliable")
func _reproduzir_ponto() -> void:
	reproduzir(player_ponto, som_ponto)

# IMPACTOS

func tocar_parede(
	sincronizar: bool = true,
	volume_db: float = -10.0
) -> void:
	disparar_impacto(false, sincronizar, volume_db)


func tocar_raquete(
	sincronizar: bool = true,
	volume_db: float = -8.0
) -> void:
	disparar_impacto(true, sincronizar, volume_db)


func disparar_impacto(
	foi_raquete: bool,
	sincronizar: bool,
	volume_db: float
) -> void:
	var conectado := multiplayer.multiplayer_peer != null

	if sincronizar and conectado:
		if multiplayer.is_server():
			_reproduzir_impacto.rpc(
				foi_raquete,
				volume_db
			)
		return

	_reproduzir_impacto(foi_raquete, volume_db)

func tocar_contagem() -> void:
	reproduzir(player_contagem, som_contagem)


@rpc("authority", "call_local", "unreliable")
func _reproduzir_impacto(
	foi_raquete: bool,
	volume_db: float
) -> void:
	if foi_raquete:
		player_raquete.volume_db = volume_db
		reproduzir(player_raquete, som_raquete)
	else:
		player_parede.volume_db = volume_db
		reproduzir(player_parede, som_parede)


# MÚSICA

func tocar_musica_menu() -> void:
	musica_em_pausa = false
	trocar_musica(player_menu)


func tocar_musica_partida() -> void:
	musica_em_pausa = false
	trocar_musica(player_partida)


func trocar_musica(destino: AudioStreamPlayer) -> void:
	if destino.stream == null:
		return

	musica_atual = destino

	if not destino.playing:
		destino.volume_db = VOLUME_SILENCIO
		destino.play()

	atualizar_volume_musica(duracao_fade)


func definir_pausa_musica(valor: bool) -> void:
	musica_em_pausa = valor
	atualizar_volume_musica(0.25)


func atualizar_volume_musica(duracao: float) -> void:
	if musica_atual == null:
		return

	if tween_musica != null:
		tween_musica.kill()

	var volume_destino := volume_musica_db

	if musica_em_pausa:
		volume_destino -= REDUCAO_PAUSA

	var outro: AudioStreamPlayer = player_partida

	if musica_atual == player_partida:
		outro = player_menu

	tween_musica = create_tween()
	tween_musica.set_parallel(true)

	tween_musica.tween_property(
		musica_atual,
		"volume_db",
		volume_destino,
		duracao
	)

	tween_musica.tween_property(
		outro,
		"volume_db",
		VOLUME_SILENCIO,
		duracao
	)

	tween_musica.chain().tween_callback(outro.stop)
