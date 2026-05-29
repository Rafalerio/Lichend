extends AnimatableBody2D

@export var move_offset: Vector2 = Vector2(150, 0) # Distância alvo relativa ao início
@export var duration: float = 2.0 # Velocidade (Tempo para ir de um lado a outro)

var start_position: Vector2

func _ready() -> void:
	# Salva a posição inicial quando a fase começa
	start_position = global_position
	start_tween()

func start_tween():
	# Cria o tween e define loop infinito
	# AnimatableBody2D é a melhor escolha física para plataformas móveis no Godot 4
	var tween = create_tween().set_loops()
	
	# Usando Easing SINE para um movimento fluído, acelerando no meio e suavizando nas bordas
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	# Vai para a posição alvo (Position inical + Offset)
	tween.tween_property(self, "global_position", start_position + move_offset, duration)
	
	# Volta para a posição inicial
	tween.tween_property(self, "global_position", start_position, duration)
