extends Node

# Señales para avisarle al menú que se oculte o muestre errores
signal conexion_establecida
signal error_de_conexion(mensaje: String)

const PUERTO_DEFAULT: int = 7777
const IP_DEFAULT: String = "127.0.0.1"

# Cargar las escenas de las diferentes colegialas
@export var escena_personaje_1: PackedScene = preload("res://Personajes/guerrera_3d.tscn")
@export var escena_personaje_2: PackedScene = preload("res://Personajes/espadachina_3d.tscn")

var jugadores_conectados: Dictionary = {}

func _ready() -> void:
	multiplayer.peer_connected.connect(_al_conectar_par)
	multiplayer.peer_disconnected.connect(_al_desconectar_par)
	multiplayer.connected_to_server.connect(_conexion_exitosa)
	multiplayer.connection_failed.connect(_al_fallar_conexion)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		# Solo dejamos Escape para el mouse; H y C ya no hacen falta
		if event.keycode == KEY_ESCAPE:
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			else:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func iniciar_host_sin_spawn(puerto: int = PUERTO_DEFAULT) -> bool:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null

	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(puerto, 4)
	if error != OK:
		printerr("> Error al iniciar Host: ", error)
		error_de_conexion.emit("Error al abrir puerto " + str(puerto))
		return false
		
	multiplayer.multiplayer_peer = peer
	print("> [RED] Servidor iniciado con éxito en puerto ", puerto, ". Esperando en el menú...")
	conexion_establecida.emit()
	return true

func conectar_cliente(ip: String = IP_DEFAULT, puerto: int = PUERTO_DEFAULT) -> void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
		
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(ip, puerto)
	if error != OK:
		printerr("> Error al conectar al Host: ", error)
		error_de_conexion.emit("IP o puerto inválido")
		return
		
	multiplayer.multiplayer_peer = peer
	print("> [RED] Conectando como CLIENTE a ", ip, ":", puerto, "...")

func _conexion_exitosa() -> void:
	print("> [RED] ¡Conectado al servidor con éxito!")
	conexion_establecida.emit()

func _al_fallar_conexion() -> void:
	print("> [RED] Falló la conexión con el servidor.")
	multiplayer.multiplayer_peer = null
	error_de_conexion.emit("No se pudo conectar al host.")

# Conexión/desconexión de pares (señales locales del motor, no llevan @rpc)
func _al_conectar_par(id_peer: int) -> void:
	print("> [RED] Nuevo jugador conectado con ID: ", id_peer)
	jugadores_conectados[id_peer] = true

func _al_desconectar_par(id_peer: int) -> void:
	print("> [RED] Jugador desconectado con ID: ", id_peer)
	jugadores_conectados.erase(id_peer)
	var mapa_escuela = get_tree().root.get_node_or_null("Escuela")
	if mapa_escuela and mapa_escuela.has_node(str(id_peer)):
		mapa_escuela.get_node(str(id_peer)).queue_free()

@rpc("call_local", "reliable")
func cargar_partida_escuela() -> void:
	# 1. Cargamos la escena 3D de la escuela en ambas máquinas
	get_tree().change_scene_to_file("res://escenas/escuela.tscn")
	
	# 2. Esperamos a que la escena se instancie y entre al árbol
	await get_tree().process_frame
	await get_tree().process_frame
	
	# 3. Solo el servidor ordena a todos spawnear los personajes
	if multiplayer.is_server():
		spawnear_personaje.rpc(1, 1)
		for peer_id in multiplayer.get_peers():
			spawnear_personaje.rpc(peer_id, 2)
@rpc("call_local", "reliable")
func spawnear_personaje(peer_id: int, tipo_personaje: int) -> void:
	# Si la escuela aún no terminó de cambiar, esperamos un instante a que entre al árbol
	if not get_tree().root.has_node("Escuela"):
		await get_tree().process_frame

	var mapa_escuela = get_tree().root.get_node_or_null("Escuela")
	if not mapa_escuela and get_tree().current_scene and get_tree().current_scene.name == "Escuela":
		mapa_escuela = get_tree().current_scene
		
	if not mapa_escuela:
		printerr("ERROR: No se encontró el mapa de la Escuela en la escena.")
		return
	# Si ya existe en este árbol local, salimos para evitar duplicados
	if mapa_escuela.has_node(str(peer_id)):
		return
		
	var escena_a_crear = escena_personaje_1 if tipo_personaje == 1 else escena_personaje_2
	var nuevo_pj = escena_a_crear.instantiate()
	nuevo_pj.name = str(peer_id)
	
	# Posiciones de spawn
	if tipo_personaje == 1:
		nuevo_pj.position = Vector3(0, 1.0, 0)
	else:
		nuevo_pj.position = Vector3(2.0, 1.0, -2.0)
		
	# Asignar la autoridad de red al peer correspondiente
	nuevo_pj.set_multiplayer_authority(peer_id)
	mapa_escuela.add_child(nuevo_pj)
	
	# --- ACTIVAR CÁMARA LOCAL ---
	var cam = nuevo_pj.find_child("Camera3D", true, false)
	if cam:
		cam.current = (peer_id == multiplayer.get_unique_id())
		
	print(">>> ¡PERSONAJE SPAWNEADO! ID: ", peer_id, " (Tipo: ", tipo_personaje, ") en Escuela.")
