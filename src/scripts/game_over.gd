extends Control

func _ready():
	# Garante que o mouse fique visível para clicar nos botões
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_btn_continuar_pressed() -> void:
	# Recarrega a fase principal. 
	get_tree().change_scene_to_file("res://src/levels/scene.tscn")

func _on_btn_menu_pressed() -> void:
	# Altere o caminho abaixo para o caminho da sua cena de Menu Principal
	get_tree().change_scene_to_file("res://caminho/para/seu/menu.tscn")
