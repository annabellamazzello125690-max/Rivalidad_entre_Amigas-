extends CharacterBody3D

const VELOCIDAD = 5.0
const VELOCIDAD_SALTO = 4.5

# vida de la maga
var vida_maxima: int = 100
var vida_actual: int = 100

func _ready():
	# vida al máximo
	vida_actual = vida_maxima
	print("¡Maga lista! Vida actual: ", vida_actual)

func _physics_process(delta: float):
	# 1. Aplicar gravedad si no está en el suelo
	if not is_on_floor():
		velocity += get_gravity() * delta

	# 2. Manejar salto usando tu acción personalizada "saltar"
	if Input.is_action_just_pressed("saltar") and is_on_floor():
		velocity.y = VELOCIDAD_SALTO

	# 3. Movimiento usando tus acciones personalizadas del mapa de entrada
	var input_dir := Input.get_vector("mover a la izquierda", "mover a la derecha", "mover arriba", "mover abajo")
	var direccion := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direccion:
		velocity.x = direccion.x * VELOCIDAD
		velocity.z = direccion.z * VELOCIDAD
	else:
		velocity.x = move_toward(velocity.x, 0, VELOCIDAD)
		velocity.z = move_toward(velocity.z, 0, VELOCIDAD)

	# 4. Ejecutar el movimiento físico
	move_and_slide()

# Función para recibir daño (resta vida)
func recibir_dano(cantidad: int):
	vida_actual -= cantidad
	print("¡Auch! La maga recibió daño. Vida restante: ", vida_actual)
	
	if vida_actual <= 0:
		vida_actual = 0
		morir()

# Función de muerte
func morir():
	print("La maga se ha desmayado...")
	# Aquí más adelante podemos activar la animación 'anim_dying' o reiniciar la escena
