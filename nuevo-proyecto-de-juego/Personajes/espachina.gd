extends PersonajeBase
func _ready() -> void:
	anim_quieta = "anim_iddle"
	anim_caminar = "anim_walk"
	anim_salto = "anim_jump"
	anim_muerte = "anim_dying"
	super._ready()
