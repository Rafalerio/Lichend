extends Area2D

# Isso cria um campo no Inspector para você arrastar a cena da PRÓXIMA FASE
@export var next_scene_path: String

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		if next_scene_path != "":
			print("Passando de fase!")
			
			# Limpa o checkpoint para o jogador nascer no início da nova fase
			Global.reset_checkpoint() 
			
			# Carrega a próxima fase
			get_tree().change_scene_to_file(next_scene_path)
		else:
			print("Caminho da próxima fase não foi configurado no Inspector!")
