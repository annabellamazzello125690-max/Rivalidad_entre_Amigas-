
extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

func _physics_process(delta: float) -> float:
	# Si no está en el suelo, le aplicamos gravedad para que caiga
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Manejar el salto cuando apretás la barra espaciadora
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Leer las teclas de dirección para saber hacia dónde querés moverte
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	# 4. Ejecutar el movimiento físico chocando contra las paredes
	move_and_slide()
