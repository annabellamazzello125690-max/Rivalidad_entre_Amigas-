extends PersonajeBase

const ANIM_ATAQUE = "combate/golpe_normal"

func _ready() -> void:
	visual = get_node_or_null("knightpr")
	super._ready()
	
	# Aseguramos que el jugador tome control activo si es su personaje
	if is_multiplayer_authority():
		set_process_unhandled_input(true)
		if camara:
			camara.current = true

func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return

	# Ejecuta la rotación de cámara y ESC de PersonajeBase
	super._unhandled_input(event)
	
	# Atacar con el clic izquierdo del ratón
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not atacando:
			ejecutar_ataque()

func ejecutar_ataque() -> void:
	if not atacando and not esta_muerta:
		ejecutar_ataque_red.rpc()

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
