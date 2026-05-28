extends Area2D

# Quantidade que aumentamos a vida máxima do Lich
@export var health_boost: int = 5

func _ready() -> void:
	# Certifique-se de conectar o sinal body_entered via Interface também!
	# E usar a colision mask certa pro Player.
	pass

func _on_body_entered(body: Node2D) -> void:
	# O Node colidido pertence a classe CharacterBody, mas verificamos de
	# forma dinamica se ele possui o método correto da nossa lógica 
	if body.has_method("add_health_capacity"):
		# Entregamos o bônus
		body.add_health_capacity(health_boost)
		
		# Opcional: Aqui poderíamos tocar um Som antes de sumir
		
		# Apagamos o power-up do mapa log após coletado
		queue_free()
