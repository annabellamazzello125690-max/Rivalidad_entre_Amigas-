extends CharacterBody3D

const VELOCIDAD = 5.0
const VELOCIDAD_SALTO = 4.5
const SENSIBILIDAD_RATON = 0.003

# Nombres exactos encontrados en tu modelo
const ANIM_QUIETA = "iddleanim_"
const ANIM_CAMINAR = "walkanim_"
const ANIM_SALTO = "jumpanim_"
const ANIM_ATAQUE = "combate/gope_normal"

var gravedad = ProjectSettings.get_setting("physics/3d/default_gravity")
var atacando: bool = false

@onready var colision_espada: CollisionShape3D = find_child("CollisionShape3D", true, false) # O la ruta a la colisión del arma
@onready var visual: Node3D = get_node_or_null("knightpr")
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
	# Liberar el cursor si se presiona la tecla Escape
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# Rotar la cámara con el movimiento del ratón
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# Giro horizontal
		rotate_y(-event.relative.x * SENSIBILIDAD_RATON)
		
		# Giro vertical sin bloqueo
		if spring_arm:
			spring_arm.rotate_x(-event.relative.y * SENSIBILIDAD_RATON)
			spring_arm.rotation.x = clampf(spring_arm.rotation.x, -0.6, 0.5)
		
		# Atacar con el clic izquierdo del ratón
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not atacando and is_on_floor():
			ejecutar_ataque()

func ejecutar_ataque() -> void:
	atacando = true
	velocity.x = 0.0
	velocity.z = 0.0
	reproducir(ANIM_ATAQUE)
	
	# Si tienes AnimationPlayer con señal animation_finished, puedes usar await:
	if anim_player and anim_player.has_animation(ANIM_ATAQUE):
		await anim_player.animation_finished
	else:
		await get_tree().create_timer(0.4).timeout # Tiempo de respaldo si no encuentra la animación
	
	atacando = false

# Asegúrate de conectar la señal de fin de animación en _ready si prefieres:
func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == ANIM_ATAQUE:
		atacando = false

func reproducir(anim: String) -> void:
	if anim_player and anim_player.has_animation(anim):
		if anim_player.current_animation != anim:
			anim_player.play(anim)

func _physics_process(delta: float) -> void:

	# 1. Gravedad
	if not is_on_floor():
		velocity.y -= gravedad * delta
	if atacando:
		move_and_slide()
		return

	# 2. Salto
	if Input.is_key_pressed(KEY_SPACE) and is_on_floor():
		velocity.y = VELOCIDAD_SALTO

	# 3. Teclas W, A, S, D
	var input_x := 0.0
	var input_z := 0.0

	if Input.is_key_pressed(KEY_D):
		input_x += 1.0  # Derecha
	if Input.is_key_pressed(KEY_A):
		input_x -= 1.0  # Izquierda
	if Input.is_key_pressed(KEY_W):
		input_z += 1.0  # Adelante
	if Input.is_key_pressed(KEY_S):
		input_z -= 1.0  # Atrás

	# 4. Calcular dirección relativa al PivoteCamara
	var direccion := Vector3.ZERO
	if pivote_camara:
		var cam_forward := -pivote_camara.global_transform.basis.z
		var cam_right := pivote_camara.global_transform.basis.x
		cam_forward.y = 0.0
		cam_right.y = 0.0
		cam_forward = cam_forward.normalized()
		cam_right = cam_right.normalized()

		direccion = (cam_right * input_x + cam_forward * input_z).normalized()
	else:
		direccion = Vector3(input_x, 0.0, -input_z).normalized()

	# 5. Desplazamiento y rotación visual
	if direccion != Vector3.ZERO:
		velocity.x = direccion.x * VELOCIDAD
		velocity.z = direccion.z * VELOCIDAD

		if visual:
			# Usamos global_rotation para que coincida con el espacio del mundo
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
