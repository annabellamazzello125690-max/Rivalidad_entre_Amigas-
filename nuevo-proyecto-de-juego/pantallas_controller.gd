extends Control

@onready var menu_inicio: Control = $MenuInicio
@onready var hud: Control = $HUD
@onready var pantalla_game_over: Control = $PantallaGameOver
@onready var pantalla_victoria: Control = $PantallaVictoria

@onready var boton_jugar: Button = $MenuInicio/BotonJugar
@onready var boton_reiniciar_derrota: Button = $PantallaGameOver/GameOver/BotonReiniciar
@onready var boton_reiniciar_victoria: Button = $PantallaVictoria/ColorRect/BotonReiniciar

func _ready() -> void:
	# Conectar botones
	if boton_jugar:
		boton_jugar.pressed.connect(_al_pulsar_jugar)
	if boton_reiniciar_derrota:
		boton_reiniciar_derrota.pressed.connect(GameManager.reiniciar_juego)
	if boton_reiniciar_victoria:
		boton_reiniciar_victoria.pressed.connect(GameManager.reiniciar_juego)

	# Suscribirse al evento del bus
	EventosJuego.estado_cambio.connect(cambiar_pantalla)

	# Estado inicial
	cambiar_pantalla(EventosJuego.estado)

func _al_pulsar_jugar() -> void:
	print("¡Click en JUGAR! Iniciando combate...")
	GameManager.iniciar_juego()

func cambiar_pantalla(estado: EventosJuego.EstadoJuego) -> void:
	var es_menu: bool = (estado == EventosJuego.EstadoJuego.MENU)
	var es_jugando: bool = (estado == EventosJuego.EstadoJuego.JUGANDO or estado == EventosJuego.EstadoJuego.PAUSA)
	var es_game_over: bool = (estado == EventosJuego.EstadoJuego.GAME_OVER)
	var es_victoria: bool = (estado == EventosJuego.EstadoJuego.VICTORIA)

	menu_inicio.visible = es_menu
	hud.visible = es_jugando
	pantalla_game_over.visible = es_game_over
	pantalla_victoria.visible = es_victoria

	if es_jugando:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
