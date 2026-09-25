extends CharacterBody3D

const VELOCIDAD = 5.0
const VELOCIDAD_SALTO = 4.5
const VELOCIDAD_GIRO = 10.0

# Cámara
const SENSIBILIDAD_MOUSE = 0.003
const SENSIBILIDAD_JOYSTICK = 3.0
const LIMITE_ARRIBA = 30.0
const LIMITE_ABAJO = -60.0

# Disparo
const TIEMPO_RECARGA = 0.4   # segundos entre disparos

# Nombres de las animaciones
const ANIM_QUIETA = "anim_iddle"
const ANIM_CAMINAR = "anim_walk"
const ANIM_SALTO = "anim_jump"
const ANIM_MUERTE = "anim_dying"

# vida de la maga
var vida_maxima: int = 100
var vida_actual: int = 100
var esta_muerta: bool = false
var puede_disparar: bool = true

var anim_player: AnimationPlayer

@onready var pivote_camara: Node3D = $PivoteCamara
@onready var modelo: Node3D = $merchantpr

func _ready():
	vida_actual = vida_maxima
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	anim_player = find_child("AnimationPlayer", true, false)
	if anim_player:
		print("Animaciones disponibles: ", anim_player.get_animation_list())
	else:
		print("¡No encontré el AnimationPlayer!")
	print("¡Maga lista! Vida actual: ", vida_actual)

func _unhandled_input(event):
	# Girar cámara con el mouse
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		girar_camara(event.relative.x * SENSIBILIDAD_MOUSE, event.relative.y * SENSIBILIDAD_MOUSE)

	# ESC libera el mouse
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

# Si el mouse está libre, un clic lo vuelve a capturar (y no dispara)
	if event is InputEventMouseButton and event.pressed and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return

	# Disparo con la acción del Mapa de Entrada
	if event.is_action_pressed("disparo") and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		disparar()

func girar_camara(horizontal: float, vertical: float):
	pivote_camara.rotation.y -= horizontal
	pivote_camara.rotation.x -= vertical
	pivote_camara.rotation.x = clamp(
		pivote_camara.rotation.x,
		deg_to_rad(LIMITE_ABAJO),
		deg_to_rad(LIMITE_ARRIBA)
	)

func disparar():
	if esta_muerta or not puede_disparar:
		return
	puede_disparar = false

	# La bola sale hacia donde mira la cámara
	var camara := get_viewport().get_camera_3d()
	var dir: Vector3 = -camara.global_transform.basis.z
	modelo.rotaciony =  atan2(dir.x , dir.z)
	#animacion de ataque


	

	# La maga mira hacia donde dispara
	modelo.rotation.y = atan2(dir.x, dir.z)

	await get_tree().create_timer(TIEMPO_RECARGA).timeout
	puede_disparar = true

func reproducir(nombre: String):
	if anim_player == null:
		return
	if not anim_player.has_animation(nombre):
		return
	if anim_player.current_animation != nombre:
		anim_player.play(nombre)

func _physics_process(delta: float):
	if esta_muerta:
		return

	# Girar cámara con el stick derecho del joystick
	var stick := Input.get_vector("camara joystick izquierda", "camara joystick derecha", "camara joystick arriba", "camara joystick abajo")
	if stick != Vector2.ZERO:
		girar_camara(stick.x * SENSIBILIDAD_JOYSTICK * delta, stick.y * SENSIBILIDAD_JOYSTICK * delta)

	# 1. Gravedad
	if not is_on_floor():
		velocity += get_gravity() * delta

	# 2. Salto
	if Input.is_action_just_pressed("saltar") and is_on_floor():
		velocity.y = VELOCIDAD_SALTO
		reproducir(ANIM_SALTO)

	# 3. Movimiento (relativo a hacia dónde mira la cámara)
	var input_dir := Input.get_vector("mover a la izquierda", "mover a la derecha", "mover arriba", "mover abajo")
	var base_camara := Basis(Vector3.UP, pivote_camara.rotation.y)
	var direccion := (base_camara * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direccion:
		velocity.x = direccion.x * VELOCIDAD
		velocity.z = direccion.z * VELOCIDAD

		var angulo_objetivo = atan2(direccion.x, direccion.z)
		modelo.rotation.y = lerp_angle(modelo.rotation.y, angulo_objetivo, VELOCIDAD_GIRO * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, VELOCIDAD)
		velocity.z = move_toward(velocity.z, 0, VELOCIDAD)

	# 4. Elegir animación
	if not is_on_floor():
		reproducir(ANIM_SALTO)
	elif direccion:
		reproducir(ANIM_CAMINAR)
	else:
		reproducir(ANIM_QUIETA)

	# 5. Mover
	move_and_slide()

func recibir_dano(cantidad: int):
	vida_actual -= cantidad
	print("¡Auch! La maga recibió daño. Vida restante: ", vida_actual)
	if vida_actual <= 0:
		vida_actual = 0
		morir()

func morir():
	esta_muerta = true
	print("La maga se ha desmayado...")
	reproducir(ANIM_MUERTE)
	
	
	
	
