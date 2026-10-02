extends Node

var puntuacion: int = 0
var items_recolectados: int = 0
@export var items_totales: int = 8

func _ready() -> void:
	iniciar_menu()

func iniciar_menu() -> void:
	EventosJuego.publicar_estado(EventosJuego.EstadoJuego.MENU)

func iniciar_juego() -> void:
	puntuacion = 0
	items_recolectados = 0
	EventosJuego.publicar_puntos(0)
	EventosJuego.publicar_estado(EventosJuego.EstadoJuego.JUGANDO)

func reiniciar_juego() -> void:
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()

func sumar_puntos(cantidad: int) -> void:
	puntuacion += cantidad
	EventosJuego.publicar_puntos(puntuacion)

func game_over() -> void:
	EventosJuego.publicar_estado(EventosJuego.EstadoJuego.GAME_OVER)

func victoria() -> void:
	EventosJuego.publicar_estado(EventosJuego.EstadoJuego.VICTORIA)

func pausar() -> void:
	if EventosJuego.estado == EventosJuego.EstadoJuego.JUGANDO:
		Engine.time_scale = 0.0
		EventosJuego.publicar_estado(EventosJuego.EstadoJuego.PAUSA)
	elif EventosJuego.estado == EventosJuego.EstadoJuego.PAUSA:
		Engine.time_scale = 1.0
		EventosJuego.publicar_estado(EventosJuego.EstadoJuego.JUGANDO)
