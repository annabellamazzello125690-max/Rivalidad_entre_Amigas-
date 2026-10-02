extends Control

@onready var barra_vida = $BarraVida
@onready var texto_vida: Label = $TextoVida
@onready var texto_puntuacion: Label = $TextoPuntuacion

func _ready() -> void:
	# Suscripción al bus de eventos
	EventosJuego.vida_cambio.connect(actualizar_vida)
	EventosJuego.puntos_cambio.connect(actualizar_puntuacion)

	# Pull del snapshot inicial
	actualizar_vida(EventosJuego.vida_actual, EventosJuego.vida_maxima)
	actualizar_puntuacion(EventosJuego.puntos)

func actualizar_vida(actual: int, maxima: int) -> void:
	barra_vida.max_value = maxima
	barra_vida.value = actual
	texto_vida.text = str(actual) + " / " + str(maxima)

func actualizar_puntuacion(puntos: int) -> void:
	texto_puntuacion.text = "Puntos: " + str(puntos)
