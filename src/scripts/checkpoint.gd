extends Area2D

@onready var anima = $AnimatedSprite2D
var is_active: bool = false

func _ready():
	anima.play("idle_off")

func _on_body_entered(body: Node2D) -> void:
	# Se já estiver ativo, ignora
	if is_active: return
	
	if body.name == "Player":
		is_active = true
		anima.play("idle_on")
		# Salva a posição DESTE checkpoint no nosso script Global!
		Global.checkpoint_pos = global_position
		print("Checkpoint salvo em: ", Global.checkpoint_pos)
