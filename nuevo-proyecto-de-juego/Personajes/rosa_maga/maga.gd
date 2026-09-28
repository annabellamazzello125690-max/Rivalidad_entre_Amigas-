extends CharacterBody3D

const VELOCIDAD = 5.0

# Cámara
const SENSIBILIDAD_MOUSE = 0.003
const LIMITE_ARRIBA = 30.0
const LIMITE_ABAJO = -60.0

# Animaciones
const ANIM_QUIETA = "anim_iddle"
const ANIM_CAMINAR = "anim_walk"

@onready var pivote_camara: Node3D = $PivoteCamara

var anim_player: AnimationPlayer


func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	anim_player = find_child("AnimationPlayer", true, false)


func _unhandled_input(event):
	# Girar cámara con el mouse
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		pivote_camara.rotation.y -= event.relative.x * SENSIBILIDAD_MOUSE
		pivote_camara.rotation.x -= event.relative.y * SENSIBILIDAD_MOUSE
		pivote_camara.rotation.x = clamp(pivote_camara.rotation.x, deg_to_rad(LIMITE_ABAJO), deg_to_rad(LIMITE_ARRIBA))

	# ESC libera el mouse, un clic lo vuelve a capturar
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event is InputEventMouseButton and event.pressed and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func reproducir(nombre: String):
	if anim_player == null or not anim_player.has_animation(nombre):
		return
	if anim_player.current_animation != nombre:
		anim_player.play(nombre)


func _physics_process(delta: float):
	# Gravedad
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		velocity.y = 0.0

	# Movimiento con WASD/flechas, relativo a hacia dónde mira la cámara
	var input_dir := Input.get_vector("mover a la izquierda", "mover a la derecha", "mover arriba", "mover abajo")
	var base_camara := Basis(Vector3.UP, pivote_camara.rotation.y)
	var direccion := (base_camara * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direccion:
		velocity.x = direccion.x * VELOCIDAD
		velocity.z = direccion.z * VELOCIDAD
		reproducir(ANIM_CAMINAR)
	else:
		velocity.x = move_toward(velocity.x, 0, VELOCIDAD)
		velocity.z = move_toward(velocity.z, 0, VELOCIDAD)
		reproducir(ANIM_QUIETA)

	move_and_slide()
	
	
	
	
	
