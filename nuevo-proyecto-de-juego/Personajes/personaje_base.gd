class_name PersonajeBase
extends CharacterBody3D

@export var vida_maxima: int = 100
var vida_actual: int = 100
var esta_muerta: bool = false
var atacando: bool = false
@export var dano_ataque: int = 20
@export var rango_ataque: float = 2.5
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
	if spring_arm:
		spring_arm.add_excluded_object(get_rid())

	# NO apagamos set_process_unhandled_input para que siempre escuche
	if is_multiplayer_authority():
		EventosJuego.publicar_vida(vida_actual, vida_maxima)
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		if camara:
			camara.current = true

func _unhandled_input(event: InputEvent) -> void:
	# 1. Tecla ESCAPE: Siempre disponible para recuperar o soltar el mouse
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			else:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			return

	# 2. Si no soy la autoridad de este personaje, no proceso rotación ni clics
	if not is_multiplayer_authority():
		return

	# 3. Clic izquierdo en la pantalla: si el mouse estaba libre, lo vuelve a capturar
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			return

	# 4. Rotación de cámara
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
	
	# --- SINCRONIZACIÓN POR CÓDIGO ---
	# Enviamos nuestra posición, rotación del cuerpo, rotación del modelo y animación
	var anim_actual: String = ""
	if anim_player:
		anim_actual = String(anim_player.current_animation)
		
	var rot_visual: float = 0.0
	if visual:
		rot_visual = visual.rotation.y
		
	actualizar_transform_remoto.rpc(global_position, rotation.y, rot_visual, anim_actual)
@rpc("unreliable")
func actualizar_transform_remoto(pos: Vector3, rot_y: float, rot_vis_y: float, anim: String) -> void:
	# Si este personaje es el que yo controlo localmente, ignoramos el mensaje
	if is_multiplayer_authority():
		return

	# Aplicamos los datos que nos manda la otra jugadora
	global_position = pos
	rotation.y = rot_y
	
	if visual:
		visual.rotation.y = rot_vis_y
		
	if anim != "":
		reproducir(anim)
	
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
@rpc("any_peer", "call_local", "reliable")
func morir() -> void:
	esta_muerta = true
	velocity = Vector3.ZERO
	reproducir("death")
	
	# Liberamos el cursor para que se pueda interactuar con la pantalla final
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Si este personaje es el que yo controlo: perdí
	if is_multiplayer_authority():
		EventosJuego.publicar_estado(EventosJuego.EstadoJuego.GAME_OVER)
	else:
		# Si el personaje que murió era el rival: gané
		EventosJuego.publicar_estado(EventosJuego.EstadoJuego.VICTORIA)

func aplicar_dano_autoritario(cantidad: int) -> void:
	if not multiplayer.is_server() or esta_muerta:
		return

	vida_actual = clampi(vida_actual - cantidad, 0, vida_maxima)
	print("> Servidor: Daño aplicado a ", name, " | Vida restante: ", vida_actual)
	
	sincronizar_vida.rpc(vida_actual)
	
	if vida_actual <= 0:
		morir.rpc()

@rpc("any_peer", "call_local", "reliable")
func sincronizar_vida(nueva_vida: int) -> void:
	vida_actual = nueva_vida
	if is_multiplayer_authority():
		EventosJuego.publicar_vida(vida_actual, vida_maxima)
@rpc("any_peer", "call_local", "reliable")
func ejecutar_ataque_red() -> void:
	if atacando or esta_muerta:
		return
		
	atacando = true
	velocity.x = 0.0
	velocity.z = 0.0
	var anim_a_reproducir = get("ANIM_ATAQUE") if get("ANIM_ATAQUE") != null else "attack"
	reproducir(anim_a_reproducir)
	
	if multiplayer.is_server():
		_verificar_impacto_servidor()
		
	if anim_player and anim_player.has_animation(anim_a_reproducir):
		await anim_player.animation_finished
	else:
		await get_tree().create_timer(0.4).timeout
	atacando = false

func _verificar_impacto_servidor() -> void:
	var mapa = get_parent()
	if not mapa:
		return
		
	for nodo in mapa.get_children():
		if nodo is CharacterBody3D and nodo != self and not nodo.esta_muerta:
			var distancia = global_position.distance_to(nodo.global_position)
			if distancia <= rango_ataque:
				nodo.aplicar_dano_autoritario(dano_ataque)
