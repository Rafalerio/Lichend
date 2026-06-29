extends Area2D

func _on_body_entered(body: Node2D) -> void:
	# Verifica se o corpo que encostou tem a função de morte instantânea (o Player)
	if body.has_method("insta_kill"):
		body.insta_kill()
