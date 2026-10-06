extends PersonajeBase

const ANIM_ATAQUE = "combate/golpe_normal"
var atacando: bool = false

func _unhandled_input(event: InputEvent) -> void:
	if not multiplayer.has_multiplayer_peer() or not is_multiplayer_authority():
		return

	# Ejecuta la rotación de cámara y ESC de PersonajeBase
	super._unhandled_input(event)
	
	# Atacar con el clic izquierdo del ratón
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not atacando:
			ejecutar_ataque.rpc()
@rpc("call_local", "reliable")
func ejecutar_ataque() -> void:
	atacando = true
	velocity.x = 0.0
	velocity.z = 0.0
	reproducir(ANIM_ATAQUE)
	
	if anim_player and anim_player.has_animation(ANIM_ATAQUE):
		reproducir(ANIM_ATAQUE)
		await anim_player.animation_finished
	else:
		await get_tree().create_timer(0.4).timeout
	
	atacando = false

func _physics_process(delta: float) -> void:
# Corta si el peer aún no inició o ya se desconectó
	if not multiplayer.has_multiplayer_peer() or not is_multiplayer_authority():
		return
	if atacando:
		if not is_on_floor():
			velocity.y -= gravedad * delta
		move_and_slide()
		return
	
	# Si no ataca, corre la física completa de PersonajeBase
	super._physics_process(delta)
