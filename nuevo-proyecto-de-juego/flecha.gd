extends Node3D

@export var velocidad := 40.0
@export var dano := 10
@export var tiempo_de_vida := 4.0

var tirador: Node = null   # quién disparó, para no herirse a sí misma

@onready var area: Area3D = $Area3D

func _ready() -> void:
	area.body_entered.connect(_on_body_entered)
	get_tree().create_timer(tiempo_de_vida).timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	global_position -= global_transform.basis.z * velocidad * delta

func _on_body_entered(body: Node3D) -> void:
	if body == tirador:
		return
	if body.has_method("recibir_dano"):
		body.recibir_dano(dano)
	queue_free()
