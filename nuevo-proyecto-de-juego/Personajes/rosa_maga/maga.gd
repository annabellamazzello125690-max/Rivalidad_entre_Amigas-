extends PersonajeBase

# Configuración específica de la Maga
const VELOCIDAD_GIRO = 10.0
const TIEMPO_RECARGA = 0.4   # segundos entre disparos
var puede_disparar: bool = true

@onready var modelo: Node3D = $merchantpr

func _ready() -> void:
	# super._ready() llama al _ready original del PersonajeBase para que configure la vida y el mouse
	super._ready()
	
	if anim_player:
		print("Animaciones disponibles: ", anim_player.get_animation_list())
	else:
		print("¡No encontré el AnimationPlayer!")
	print("¡Maga lista! Vida actual: ", vida_actual)

func _unhandled_input(event: InputEvent) -> void:
	# El giro del mouse y la tecla ESC ya los maneja el PersonajeBase, 
	# pero aquí agregamos el extra exclusivo de la Maga: disparar con clic y recapturar el mouse.
	if event is InputEventMouseButton and event.pressed and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return

	if event.is_action_pressed("disparo") and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		disparar()

func disparar() -> void:
	if esta_muerta or not puede_disparar:
		return
	puede_disparar = false

	# La bola sale hacia donde mira la cámara
	var cam := get_viewport().get_camera_3d()
	if cam:
		var dir: Vector3 = -cam.global_transform.basis.z
		# La maga mira hacia donde dispara
		if modelo:
			modelo.rotation.y = atan2(dir.x, dir.z)

	await get_tree().create_timer(TIEMPO_RECARGA).timeout
	puede_disparar = true
	
	
	
	
