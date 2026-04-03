extends Camera2D

var target: Node2D

func _ready() -> void:
	get_target()
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position = target.position

# pega a referencia do player no grupo global
func get_target():
	var nodes = get_tree().get_nodes_in_group("Player")
	if nodes.size() == 0:
		push_error("Player não encontrado")
		return
	
	target = nodes[0]
