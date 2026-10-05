extends Control

@onready var barra_vida = $BarraVida
@onready var texto_vida: Label = $TextoVida
@onready var texto_puntuacion: Label = $TextoPuntuacion

func _ready() -> void:
	# 1. Configurar filtros de ratón para que no bloqueen los clics de ataque
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if barra_vida:
		barra_vida.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if texto_vida:
		texto_vida.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if texto_puntuacion:
		texto_puntuacion.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# 2. Suscripción al bus de eventos
	EventosJuego.vida_cambio.connect(actualizar_vida)
	EventosJuego.puntos_cambio.connect(actualizar_puntuacion)

	# 3. Pull del snapshot inicial
	actualizar_vida(EventosJuego.vida_actual, EventosJuego.vida_maxima)
	actualizar_puntuacion(EventosJuego.puntos)

func actualizar_vida(actual: int, maxima: int) -> void:
	if barra_vida:
		barra_vida.max_value = maxima
		barra_vida.value = actual
	if texto_vida:
		texto_vida.text = str(actual) + " / " + str(maxima)

func actualizar_puntuacion(puntos: int) -> void:
	if texto_puntuacion:
		texto_puntuacion.text = "Puntos: " + str(puntos)
