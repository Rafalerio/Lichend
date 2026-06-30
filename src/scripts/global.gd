extends Node

# Guarda a posição exata onde o player deve renascer
var checkpoint_pos: Vector2 = Vector2.ZERO

# Função para limpar o checkpoint quando passarmos de fase
func reset_checkpoint():
	checkpoint_pos = Vector2.ZERO
