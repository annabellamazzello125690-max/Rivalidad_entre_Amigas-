extends PersonajeBase

const DANO_BOLA_DE_FUEGO: int = 10
const ALCANCE_BOLA_DE_FUEGO: float = 30.0
const TIEMPO_BOLA_DE_FUEGO: float = 0.8

var lanzando: bool = false


func _ready() -> void:
	# Ajustamos los nombres de las animaciones de la Maga
	anim_quieta = "anim_iddle"
	anim_caminar = "anim_walk"
	anim_salto = "anim_jump"
	anim_muerte = "anim_dying"

	# Llamamos al inicio base
	super._ready()


func _unhandled_input(event: InputEvent) -> void:
	# Mantiene la cámara y el mouse de PersonajeBase
	super._unhandled_input(event)

	# Click izquierdo = bola de fuego
	if event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT \
			and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		lanzar_bola_de_fuego()


func lanzar_bola_de_fuego() -> void:
	if esta_muerta or lanzando:
		return
	lanzando = true
	reproducir("anim_flip")

	# Rayo desde la cámara hacia donde mira
	var cam := get_viewport().get_camera_3d()
	if cam:
		var origen: Vector3 = cam.global_position
		var destino: Vector3 = origen + (-cam.global_transform.basis.z) * ALCANCE_BOLA_DE_FUEGO
		var query := PhysicsRayQueryParameters3D.create(origen, destino)
		query.exclude = [get_rid()]
		var resultado := get_world_3d().direct_space_state.intersect_ray(query)

		# Si golpea algo con recibir_dano, le quita 10
		if resultado:
			var objetivo = resultado.collider
			if objetivo and objetivo.has_method("recibir_dano"):
				objetivo.recibir_dano(DANO_BOLA_DE_FUEGO)
				print("Bola de fuego impactó: -", DANO_BOLA_DE_FUEGO)

	await get_tree().create_timer(TIEMPO_BOLA_DE_FUEGO).timeout
	lanzando = false


# Evita que idle/caminar corten la animación del hechizo
func reproducir(anim: String) -> void:
	if lanzando and anim != "anim_flip":
		return
	super.reproducir(anim)
	
	
	
	
