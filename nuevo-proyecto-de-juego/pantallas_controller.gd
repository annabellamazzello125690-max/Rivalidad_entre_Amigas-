extends Control

@onready var menu_inicio: Control = get_node_or_null("MenuInicio")
@onready var hud: Control = get_node_or_null("HUD")
@onready var pantalla_game_over: Control = get_node_or_null("PantallaGameOver")
@onready var pantalla_victoria: Control = get_node_or_null("PantallaVictoria")

@onready var boton_jugar: Button = get_node_or_null("MenuInicio/VBoxContainer/BotonJugar")
@onready var boton_reiniciar_derrota: Button = get_node_or_null("PantallaGameOver/GameOver/BotonReiniciar")
@onready var boton_reiniciar_victoria: Button = get_node_or_null("PantallaVictoria/ColorRect/BotonReiniciar")

func _ready() -> void:
	# 1. Conexiones seguras de botones
	if boton_jugar and not boton_jugar.pressed.is_connected(_al_pulsar_jugar):
		boton_jugar.pressed.connect(_al_pulsar_jugar)
	if boton_reiniciar_derrota and not boton_reiniciar_derrota.pressed.is_connected(GameManager.reiniciar_juego):
		boton_reiniciar_derrota.pressed.connect(GameManager.reiniciar_juego)
	if boton_reiniciar_victoria and not boton_reiniciar_victoria.pressed.is_connected(GameManager.reiniciar_juego):
		boton_reiniciar_victoria.pressed.connect(GameManager.reiniciar_juego)

	# 2. Suscripción al bus de eventos
	if not EventosJuego.estado_cambio.is_connected(cambiar_pantalla):
		EventosJuego.estado_cambio.connect(cambiar_pantalla)

	# 3. Lógica automática de pantallas:
	# Si ya estamos dentro del mapa de la escuela, forzamos combate (HUD).
	# Si estamos en cualquier otra escena (menú), mostramos el menú de inicio.
	if get_tree().current_scene and get_tree().current_scene.name == "Escuela":
		mostrar_solo("HUD")
	else:
		mostrar_solo("MENU")

	# Si es el cliente en el lobby, deshabilitamos el botón hasta que el host inicie
	if boton_jugar and multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
		boton_jugar.disabled = true
		boton_jugar.text = "Esperando al Host..."

func _al_pulsar_jugar() -> void:
	if boton_jugar:
		boton_jugar.disabled = true

	if multiplayer.has_multiplayer_peer():
		if multiplayer.is_server():
			print("¡Host inició el combate! Sincronizando con todos...")
			RedManager.cargar_partida_escuela.rpc()
	else:
		mostrar_solo("HUD")
		GameManager.iniciar_juego()

# Función que apaga TODO y enciende SOLO lo que se le pide
func mostrar_solo(nombre_pantalla: String) -> void:
	if menu_inicio:
		menu_inicio.visible = (nombre_pantalla == "MENU")
	if hud:
		hud.visible = (nombre_pantalla == "HUD")
	if pantalla_game_over:
		pantalla_game_over.visible = (nombre_pantalla == "GAME_OVER")
	if pantalla_victoria:
		pantalla_victoria.visible = (nombre_pantalla == "VICTORIA")

	if nombre_pantalla == "HUD":
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func cambiar_pantalla(estado: EventosJuego.EstadoJuego) -> void:
	match estado:
		EventosJuego.EstadoJuego.MENU:
			mostrar_solo("MENU")
		EventosJuego.EstadoJuego.JUGANDO, EventosJuego.EstadoJuego.PAUSA:
			mostrar_solo("HUD")
		EventosJuego.EstadoJuego.GAME_OVER:
			mostrar_solo("GAME_OVER")
		EventosJuego.EstadoJuego.VICTORIA:
			mostrar_solo("VICTORIA")
