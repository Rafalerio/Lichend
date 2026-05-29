extends Area2D

@export var speed: float = 600.0
var direction: int = 1
var damage: int = 1

func _ready():
	# Adiciona ao grupo para limitarmos 3 balas na tela
	add_to_group("PlayerBullets")

func setup(pos: Vector2, _direction: int, _damage: int):
	global_position = pos
	direction = _direction
	damage = _damage
	
	# Muda a escala visual e velocidade da bala baseado na carga
	if damage == 3:
		scale = Vector2(1.5, 1.5)
		speed = 700.0
	elif damage == 7:
		scale = Vector2(2.5, 2.5)
		speed = 850.0

func _physics_process(delta: float) -> void:
	position.x += speed * direction * delta

func _on_body_entered(body: Node2D) -> void:
	# Destroi o tiro se bater em uma parede/chão
	if body is TileMap or body is StaticBody2D:
		# Adicione lógica de partículas ou animação de impacto aqui
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	# Acertar a Hitbox do Inimigo
	var enemy = area.get_parent()
	if enemy.has_method("take_damage"):
		enemy.take_damage(damage)
		# Adicione impacto visual / hit stop aqui
		queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	# Limpa da memória quando sai da tela
	queue_free()
