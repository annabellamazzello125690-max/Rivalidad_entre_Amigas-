extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

# Sistema de vida de la maga
var vida_maxima: int = 100
var vida_actual: int = 100

func _ready():
	# Nos aseguramos de arrancar con la vida al máximo
	vida_actual = vida_maxima
	print("¡Maga lista! Vida actual: ", vida_actual)

func _physics_process(delta: float):
	# 1. Aplicar gravedad si no está en el suelo
	if not is_on_floor():
		velocity += get_gravity() * delta

	# 2. Manejar salto
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# 3. Movimiento con WASD o flechas
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

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
