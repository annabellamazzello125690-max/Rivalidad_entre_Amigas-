extends CharacterBody3D

const VELOCIDAD = 5.0
const VELOCIDAD_SALTO = 4.5

# Nombres exactos encontrados en tu modelo
const ANIM_QUIETA = "iddleanim_"
const ANIM_CAMINAR = "walkanim_"
const ANIM_SALTO = "jumpanim_"

var gravedad = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var visual: Node3D = get_node_or_null("knightpr")
var anim_player: AnimationPlayer

func _ready() -> void:
	anim_player = find_child("AnimationPlayer", true, false)

func reproducir(anim: String) -> void:
	if anim_player and anim_player.has_animation(anim):
		if anim_player.current_animation != anim:
			anim_player.play(anim)

func _physics_process(delta: float) -> void:
	# 1. Gravedad
	if not is_on_floor():
		velocity.y -= gravedad * delta

	# 2. Salto
	if Input.is_key_pressed(KEY_SPACE) and is_on_floor():
		velocity.y = VELOCIDAD_SALTO

	# 3. Teclas W, A, S, D
	var input_x := 0.0
	var input_z := 0.0

	if Input.is_key_pressed(KEY_D):
		input_x += 1.0
	if Input.is_key_pressed(KEY_A):
		input_x -= 1.0
	if Input.is_key_pressed(KEY_W):
		input_z += 1.0
	if Input.is_key_pressed(KEY_S):
		input_z -= 1.0

	# 4. Dirección relativa a la cámara
	var direccion := Vector3.ZERO
	var camara := get_viewport().get_camera_3d()

	if camara:
		var cam_forward := -camara.global_transform.basis.z
		var cam_right := camara.global_transform.basis.x
		cam_forward.y = 0.0
		cam_right.y = 0.0
		cam_forward = cam_forward.normalized()
		cam_right = cam_right.normalized()

		direccion = (cam_right * input_x + cam_forward * input_z).normalized()
	else:
		direccion = Vector3(input_x, 0.0, -input_z).normalized()

	# 5. Movimiento y rotación
	if direccion != Vector3.ZERO:
		velocity.x = direccion.x * VELOCIDAD
		velocity.z = direccion.z * VELOCIDAD

		if visual:
			var angulo_objetivo = atan2(direccion.x, direccion.z)
			visual.rotation.y = lerp_angle(visual.rotation.y, angulo_objetivo, delta * 12.0)
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
