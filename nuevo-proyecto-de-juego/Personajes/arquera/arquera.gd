extends PersonajeBase

@export var flecha_escena: PackedScene
@export var cadencia := 0.6
@export var retraso_flecha := 0.4
@export var invertir_frente := true   # true = dispara en sentido contrario a basis.z

var anim_disparo: String = "anim_disparo"
var puede_disparar := true
var disparando := false

@onready var punto_disparo: Marker3D = $PuntoDisparo

func _ready() -> void:
	super()
	visual = $archerpr

	anim_quieta = "anim_iddle"
	anim_caminar = "anim_walk"
	anim_salto = "anim_jump"

	if anim_player:
		for nombre in [anim_quieta, anim_caminar]:
			if anim_player.has_animation(nombre):
				anim_player.get_animation(nombre).loop_mode = Animation.LOOP_LINEAR

func reproducir(anim: String) -> void:
	if disparando:
		return
	super(anim)

func _unhandled_input(event: InputEvent) -> void:
	super(event)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and puede_disparar and not esta_muerta:
			disparar()

func disparar() -> void:
	if flecha_escena == null:
		print("Falta asignar flecha_escena en el Inspector")
		return
	puede_disparar = false

	# Animación de disparo (si existe)
	var duracion := 0.0
	if anim_player and anim_player.has_animation(anim_disparo):
		disparando = true
		anim_player.play(anim_disparo)
		duracion = anim_player.get_animation(anim_disparo).length
		await get_tree().create_timer(retraso_flecha).timeout

	# Dirección: hacia donde mira el modelo del personaje
	var frente: Vector3 = global_transform.basis.z
	if visual:
		frente = visual.global_transform.basis.z
	if invertir_frente:
		frente = -frente
	frente.y = 0.0
	frente = frente.normalized()

	# Crear la flecha
	var flecha = flecha_escena.instantiate()
	get_tree().current_scene.add_child(flecha)
	flecha.tirador = self
	flecha.global_position = punto_disparo.global_position
	flecha.look_at(punto_disparo.global_position + frente)

	# Volver a la normalidad
	if duracion > 0.0:
		await get_tree().create_timer(max(duracion - retraso_flecha, 0.0)).timeout
		disparando = false

	await get_tree().create_timer(cadencia).timeout
	puede_disparar = true
