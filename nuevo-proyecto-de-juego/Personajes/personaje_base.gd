class_name PersonajeBase
extends CharacterBody3D

@export var vida_maxima: int = 100
var vida_actual: int = 100
var esta_muerta: bool = false
var anim_muerte: String = "anim_dying"
const VELOCIDAD = 5.0
const VELOCIDAD_SALTO = 4.5
const SENSIBILIDAD_RATON = 0.003

@export_group("Animaciones")
@export var anim_quieta: String = "iddleanim_"
@export var anim_caminar: String = "walkanim_"
@export var anim_salto: String = "jumpanim_"


var gravedad = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var visual: Node3D = get_node_or_null("knightpr") if get_node_or_null("knightpr") else get_node_or_null("studentpr")
@onready var pivote_camara: Node3D = find_child("PivoteCamara", true, false)
@onready var spring_arm: SpringArm3D = find_child("SpringArm3D", true, false)
@onready var camara: Camera3D = find_child("Camera3D", true, false)
var anim_player: AnimationPlayer

func _ready() -> void:
	vida_actual = vida_maxima
	anim_player = find_child("AnimationPlayer", true, false)
	
	# Excluir el cuerpo del personaje del SpringArm para que no choque la cámara consigo mismo
	if spring_arm:
		spring_arm.add_excluded_object(get_rid())

	# --- AUTORIDAD DE RED ---
	var soy_el_dueno: bool = is_multiplayer_authority()
	
	# Solo el dueño publica su vida al HUD local
	if soy_el_dueno:
		EventosJuego.publicar_vida(vida_actual, vida_maxima)
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# Solo activa la cámara de tu pantalla
	if camara:
		camara.current = soy_el_dueno

	# Solo lee mouse y teclado si es tu personaje
	set_process_unhandled_input(soy_el_dueno)
func _unhandled_input(event: InputEvent) -> void:
	if not multiplayer.has_multiplayer_peer() or not is_multiplayer_authority():
		return
	# Liberar o volver a capturar el cursor con Escape
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			else:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# Capturar con clic izquierdo si estaba libre
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# Rotar la cámara solo si el cursor está capturado
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if pivote_camara:
			pivote_camara.rotate_y(-event.relative.x * SENSIBILIDAD_RATON)
		else:
			rotate_y(-event.relative.x * SENSIBILIDAD_RATON)
		
		if spring_arm:
			spring_arm.rotate_x(-event.relative.y * SENSIBILIDAD_RATON)
			spring_arm.rotation.x = clampf(spring_arm.rotation.x, -0.6, 0.5)
func reproducir(anim: String) -> void:
	if anim_player and anim_player.has_animation(anim):
		if anim_player.current_animation != anim:
			anim_player.play(anim)

func _physics_process(delta: float) -> void:
	# Si este personaje no me pertenece a mí, no le aplico mis teclas
	if not multiplayer.has_multiplayer_peer() or not is_multiplayer_authority():
		return
	if esta_muerta:
		if not is_on_floor():
			velocity.y -= gravedad * delta
			move_and_slide()
		return
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
			var angulo_objetivo = atan2(direccion.x, direccion.z)
			visual.rotation.y = lerp_angle(visual.rotation.y, angulo_objetivo, delta * 12.0)
	else:
		velocity.x = move_toward(velocity.x, 0.0, VELOCIDAD)
		velocity.z = move_toward(velocity.z, 0.0, VELOCIDAD)

	# 6. Reproducir animaciones según el estado
	if not is_on_floor():
		reproducir(anim_salto)
	elif direccion != Vector3.ZERO:
		reproducir(anim_caminar)
	else:
		reproducir(anim_quieta)

	# 7. Mover
	move_and_slide()
	
func recibir_dano(cantidad: int) -> void:
	if esta_muerta or cantidad <= 0:
		return
	vida_actual = clampi(vida_actual - cantidad, 0, vida_maxima)
	print("Vida: ", vida_actual, "/", vida_maxima)
	EventosJuego.publicar_vida(vida_actual, vida_maxima)
	if vida_actual <= 0:
		morir()

func curar(cantidad: int) -> void:
	if esta_muerta or cantidad <= 0:
		return
	vida_actual = clampi(vida_actual + cantidad, 0, vida_maxima)
	print("Vida: ", vida_actual, "/", vida_maxima)
	EventosJuego.publicar_vida(vida_actual, vida_maxima)
func morir() -> void:
	esta_muerta = true
	velocity = Vector3.ZERO
	print("El personaje ha muerto.")
	reproducir(anim_muerte)
	GameManager.game_over()
