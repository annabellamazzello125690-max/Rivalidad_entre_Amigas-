extends Control

# Apuntamos a la UI principal
const ESCENA_UI_PRINCIPAL: String = "res://ui/ui_principal.tscn"

@onready var line_edit_ip: LineEdit = $LineEditIp
@onready var line_edit_puerto: LineEdit = $LineEditPuerto
@onready var button_host: Button = $ButtonHost
@onready var button_client: Button = $ButtonClient

func _ready() -> void:
	line_edit_ip.placeholder_text = "127.0.0.1"
	line_edit_puerto.placeholder_text = "7777"
	
	button_host.pressed.connect(_on_host_pressed)
	button_client.pressed.connect(_on_client_pressed)
	
	RedManager.conexion_establecida.connect(_on_conectado)
	RedManager.error_de_conexion.connect(_on_error)

func _on_host_pressed() -> void:
	var puerto = int(line_edit_puerto.text) if line_edit_puerto.text.strip_edges() != "" else 7777
	Engine.get_main_loop().change_scene_to_file(ESCENA_UI_PRINCIPAL)
	RedManager.iniciar_host_sin_spawn(puerto)

func _on_client_pressed() -> void:
	var ip = line_edit_ip.text.strip_edges() if line_edit_ip.text.strip_edges() != "" else "127.0.0.1"
	var puerto = int(line_edit_puerto.text) if line_edit_puerto.text.strip_edges() != "" else 7777
	
	button_host.disabled = true
	button_client.disabled = true
	RedManager.conectar_cliente(ip, puerto)

func _on_conectado() -> void:
	# Cuando el cliente confirma conexión
	Engine.get_main_loop().change_scene_to_file(ESCENA_UI_PRINCIPAL)

func _on_error(mensaje: String) -> void:
	print("Error de conexión: ", mensaje)
	button_host.disabled = false
	button_client.disabled = false
