extends Area2D

@export var speed: float = 400.0
var direction: int = 1
var damage: int = 1

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	# Assim que o tiro nasce, ele já começa a tocar a animação de voo
	anim.play("default") 

func setup(spawn_position: Vector2, shoot_direction: int, damage_value: int):
	global_position = spawn_position
	direction = shoot_direction
	damage = damage_value
	
	# Vira o tiro para o lado correto
	if direction < 0:
		anim.flip_h = true
		
	# LÓGICA DO TIRO CARREGÁVEL
	if damage >= 7:
		# Tiro nível máximo: Maior e mais forte
		anim.scale = Vector2(2.0, 2.0) 
		# anim.play("tiro_carregado") # Use se tiver uma animação específica
	elif damage >= 3:
		# Tiro nível médio
		anim.scale = Vector2(1.5, 1.5)
	else:
		# Tiro normal
		anim.scale = Vector2(1.0, 1.0)

func _physics_process(delta: float) -> void:
	# Move o tiro constantemente
	position.x += speed * direction * delta

# Conecte o sinal "area_entered" do nó Area2D para esta função
func _on_area_entered(area: Area2D) -> void:
	var parent = area.get_parent()
	if parent and parent.has_method("take_damage"):
		parent.take_damage(damage)
	
	explode()

# Conecte o sinal "body_entered" do nó Area2D para bater em paredes
func _on_body_entered(body: Node2D) -> void:
	explode()

func explode():
	speed = 0 # Para o tiro no lugar
	
	# Desativa a colisão para não dar dano duas vezes enquanto explode
	set_deferred("monitoring", false) 
	
	anim.play("hit") # Toca a animação de impacto
	await anim.animation_finished # Espera a animação terminar
	queue_free() # Destrói o tiro da memória


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
