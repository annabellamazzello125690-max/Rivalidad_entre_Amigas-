extends CharacterBody3D

const VELOCIDAD = 5.0
const VELOCIDAD_SALTO = 4.5

# Nombres de las animaciones (tienen que ser IGUALES a los del AnimationPlayer)
const ANIM_QUIETA = "anim_idle"
const ANIM_CAMINAR = "anim_walk"
const ANIM_SALTO = "anim_jump"
const ANIM_MUERTE = "anim_dying"

# vida de la maga
var vida_maxima: int = 100
var vida_actual: int = 100
var esta_muerta: bool = false

var anim_player: AnimationPlayer

func _ready():
	vida_actual = vida_maxima
	# Busca el AnimationPlayer en cualquier lugar dentro de la maga
	anim_player = find_child("AnimationPlayer", true, false)
	if anim_player:
		print("Animaciones disponibles: ", anim_player.get_animation_list())
	else:
		print("¡No encontré el AnimationPlayer!")
	print("¡Maga lista! Vida actual: ", vida_actual)

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

	# 1. Gravedad
	if not is_on_floor():
		velocity += get_gravity() * delta

	# 2. Salto
	if Input.is_action_just_pressed("saltar") and is_on_floor():
		velocity.y = VELOCIDAD_SALTO
		reproducir(ANIM_SALTO)

	# 3. Movimiento
	var input_dir := Input.get_vector("mover a la izquierda", "mover a la derecha", "mover arriba", "mover abajo")
	var direccion := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direccion:
		velocity.x = direccion.x * VELOCIDAD
		velocity.z = direccion.z * VELOCIDAD
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
