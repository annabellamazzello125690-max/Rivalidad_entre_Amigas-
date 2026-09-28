extends CharacterBody3D

const VELOCIDAD = 5.0
const VELOCIDAD_SALTO = 4.5
const SENSIBILIDAD_RATON = 0.003

# Nombres para las animaciones
const ANIM_QUIETA = "iddleanim_"
const ANIM_CAMINAR = "walkanim_"
const ANIM_SALTO = "jumpanim_"

var gravedad = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var visual: Node3D = get_node_or_null("student")
@onready var pivote_camara: Node3D = $PivoteCamara
@onready var camara: Camera3D = find_child("Camera3D", true, false)
@onready var spring_arm: SpringArm3D = find_child("SpringArm3D", true, false)
var anim_player: AnimationPlayer

func _ready() -> void:
	anim_player = find_child("AnimationPlayer", true, false)
	# Capturar y ocultar el cursor dentro de la ventana de juego
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if spring_arm:
		spring_arm.add_excluded_object(get_rid())

func _unhandled_input(event: InputEvent) -> void:
	# Liberar o capturar el cursor con la tecla Escape
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# Rotar la cámara con el movimiento del ratón
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * SENSIBILIDAD_RATON)
		
		if spring_arm:
			spring_arm.rotate_x(-event.relative.y * SENSIBILIDAD_RATON)
			spring_arm.rotation.x = clampf(spring_arm.rotation.x, -0.6, 0.5)

func reproducir(anim: String) -> void:
	if anim_player and anim_player.has_animation(anim):
		if anim_player.current_animation != anim:
			anim_player.play(anim)

func _physics_process(delta: float) -> void:
	# 1. Gravedad
	if not is_on_floor():
		velocity.y -= gravedad * delta

	# 2. Salto
	if Input.is_action_just_pressed("ui_accept") and is_on_floor(): # Usa espacio por defecto o la acción de salto
		velocity.y = VELOCIDAD_SALTO

	# 3. Capturar entrada de movimiento (Soporta teclado y mandos)
	# Asegúrate de tener configurados los inputs o usa las acciones por defecto de Godot
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# 4. Calcular dirección relativa al PivoteCamara
	var direccion := Vector3.ZERO
	if pivote_camara:
		var cam_forward := -pivote_camara.global_transform.basis.z
		var cam_right := pivote_camara.global_transform.basis.x
		cam_forward.y = 0.0
		cam_right.y = 0.0
		cam_forward = cam_forward.normalized()
		cam_right = cam_right.normalized()

		direccion = (cam_right * input_dir.x + cam_forward * input_dir.y).normalized()
	else:
		direccion = Vector3(input_dir.x, 0.0, input_dir.y).normalized()

	# 5. Desplazamiento y rotación visual
	if direccion != Vector3.ZERO:
		velocity.x = direccion.x * VELOCIDAD
		velocity.z = direccion.z * VELOCIDAD

		if visual:
			var angulo_objetivo = atan2(direccion.x, direccion.z)
			visual.global_rotation.y = lerp_angle(visual.global_rotation.y, angulo_objetivo, delta * 12.0)
	else:
		velocity.x = move_toward(velocity.x, 0.0, VELOCIDAD)
		velocity.z = move_toward(velocity.z, 0.0, VELOCIDAD)

	# 6. Reproducir animaciones según el estado
	if not is_on_floor():
		reproducir(ANIM_SALTO)
	elif direccion != Vector3.ZERO:
		reproducir(ANIM_CAMINAR)
	else:
		reproducir(ANIM_QUIETA)

	# 7. Mover
	move_and_slide()
