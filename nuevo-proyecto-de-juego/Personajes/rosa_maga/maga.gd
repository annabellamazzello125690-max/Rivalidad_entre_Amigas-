extends PersonajeBase


func _ready() -> void:
	# Ajustamos los nombres de las animaciones de la Maga
	anim_quieta = "anim_iddle"
	anim_caminar = "anim_walk"
	anim_salto = "anim_jump"
	anim_muerte = "anim_dying"
	
	# Llamamos al inicio base
	super._ready()
	
	
	
	
