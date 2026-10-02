extends Node

# Estados equivalentes al enum de Unity
enum EstadoJuego { MENU, JUGANDO, PAUSA, GAME_OVER, VICTORIA }

# Valores snapshot (último valor conocido)
var vida_actual: int = 100
var vida_maxima: int = 100
var puntos: int = 0
var estado: EstadoJuego = EstadoJuego.MENU

# Señales (equivalentes a los Action<> y eventos de C#)
signal vida_cambio(actual: int, maxima: int)
signal puntos_cambio(puntuacion: int)
signal estado_cambio(nuevo_estado: EstadoJuego)

func publicar_vida(actual: int, maxima: int) -> void:
	vida_actual = actual
	vida_maxima = maxima
	vida_cambio.emit(actual, maxima)

func publicar_puntos(nueva_puntuacion: int) -> void:
	puntos = nueva_puntuacion
	puntos_cambio.emit(nueva_puntuacion)
	
func publicar_estado(nuevo_estado: EstadoJuego) -> void:
	estado = nuevo_estado
	estado_cambio.emit(nuevo_estado)
