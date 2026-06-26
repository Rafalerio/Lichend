extends Control

func _ready():
	# Garante que o mouse fique visível para o jogador poder clicar
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_btn_jogar_pressed() -> void:
	# Carrega a fase principal do jogo. 
	get_tree().change_scene_to_file("res://src/levels/scene.tscn")

func _on_btn_sair_pressed() -> void:
	get_tree().quit()
