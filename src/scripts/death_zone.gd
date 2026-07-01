extends Area2D

func _on_body_entered(body: Node2D) -> void:
	#Se for o Player, chama a função de morte instantânea
	if body.has_method("insta_kill"):
		body.insta_kill()
		
	#Se for um Inimigo (BaseEnemy), chama a função de morrer dele
	elif body.has_method("die"):
		body.die()
		
	#Se for qualquer outra coisa inútil que caiu no buraco, apenas deleta para não pesar o jogo
	else:
		body.queue_free()
