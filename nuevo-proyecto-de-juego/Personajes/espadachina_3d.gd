extends PersonajeBase
const ANIM_ATAQUE = "golpe_normal/golpe"
var atacando: bool = false

func _ready() -> void:
	# Asignar su modelo real para que visual no sea null
	visual = get_node_or_null("studentpr")
	super._ready()
	
func _unhandled_input(event: InputEvent) -> void:
	# Ejecuta la rotación de cámara y ESC de PersonajeBase
	super._unhandled_input(event)
	
	# Atacar con el clic izquierdo del ratón
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not atacando and is_on_floor():
			ejecutar_ataque()

func ejecutar_ataque() -> void:
	atacando = true
	velocity.x = 0.0
	velocity.z = 0.0
	reproducir(ANIM_ATAQUE)
	
	if anim_player and anim_player.has_animation(ANIM_ATAQUE):
		await anim_player.animation_finished
	else:
		await get_tree().create_timer(0.4).timeout
	
	atacando = false

func _physics_process(delta: float) -> void:
	# Si está atacando, frena el movimiento
	if atacando:
		if not is_on_floor():
			velocity.y -= gravedad * delta
		move_and_slide()
		return
	
	# Si no ataca, corre la física completa de PersonajeBase
	super._physics_process(delta)
