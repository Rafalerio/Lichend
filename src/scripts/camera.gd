extends Camera2D

@export var smoothing: float = 0.1 # Valor entre 0 e 1 (quanto menor, mais suave)
var target: Node2D = null

func _ready() -> void:
	get_target()

func _process(_delta: float) -> void:
	if is_instance_valid(target):
		# Interpolação linear para movimento suave
		position = position.lerp(target.position, smoothing)
	else:
		# Tenta recuperar o target se ele for perdido
		get_target()

func get_target():
	var nodes = get_tree().get_nodes_in_group("Player")
	if nodes.size() > 0:
		target = nodes[0]
