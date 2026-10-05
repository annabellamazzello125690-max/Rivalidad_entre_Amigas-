extends PersonajeBase

const ANIM_ATAQUE = "golpe_normal/golpe"
var atacando: bool = false

func _ready() -> void:
	visual = get_node_or_null("studentpr")
	super._ready()
	
	# Aseguramos que el cliente tome control activo si es su personaje
	if is_multiplayer_authority():
		set_process_unhandled_input(true)
		if camara:
			camara.current = true

func _unhandled_input(event: InputEvent) -> void:
# Verificación previa de conexión para no consultar autoridad en vacío
	if not multiplayer.has_multiplayer_peer() or not is_multiplayer_authority():
		return

	super._unhandled_input(event)
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not atacando:
			ejecutar_ataque.rpc()

@rpc("call_local", "reliable")
func ejecutar_ataque() -> void:
	atacando = true
	velocity.x = 0.0
	velocity.z = 0.0
	
	if anim_player and anim_player.has_animation(ANIM_ATAQUE):
		reproducir(ANIM_ATAQUE)
		await anim_player.animation_finished
	else:
		# Fallback por si la animación no existe o tiene otro nombre
		await get_tree().create_timer(0.4).timeout
	
	atacando = false

func _physics_process(delta: float) -> void:
	if not multiplayer.has_multiplayer_peer() or not is_multiplayer_authority():
		return

	if atacando:
		if not is_on_floor():
			velocity.y -= gravedad * delta
		move_and_slide()
		return
	
	super._physics_process(delta)
