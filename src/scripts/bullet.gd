extends Area2D

@export var speed: float = 300.0
var direction: int = 10
var damage: int = 1

var has_exploded: bool = false

# Variáveis para guardar os nomes corretos das animações
var anim_travel: String = "default"
var anim_hit: String = "hit"

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:

	pass

func setup(spawn_position: Vector2, shoot_direction: int, damage_value: int):
	global_position = spawn_position
	direction = shoot_direction
	damage = damage_value
	
	if direction < 0:
		anim.flip_h = true
		
	# --- DEFININDO OS SPRITES POR NÍVEL DE CARGA ---
	if damage >= 7:
		# Tiro nível máximo
		anim_travel = "default3"
		anim_hit = "hit3"
	elif damage >= 3:
		# Tiro nível médio
		anim_travel = "default2"
		anim_hit = "hit2"
	else:
		# Tiro normal
		anim_travel = "default"
		anim_hit = "hit"
		
	# Toca a animação de voo escolhida!
	anim.play(anim_travel)

func _physics_process(delta: float) -> void:
	if not has_exploded:
		position.x += speed * direction * delta

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("PlayerBullets"):
		return
		
	var parent = area.get_parent()
	if parent and parent.has_method("take_damage"):
		parent.take_damage(damage, global_position.x)
	
	explode()

func _on_body_entered(body: Node2D) -> void:
	# Verifica se em quem o tiro bateu tem a função de tomar dano
	if body.has_method("take_damage"):
		# Dá o dano e passa a posição X de quem atirou (opcional, para knockback)
		body.take_damage(damage, global_position.x)

	# Destrói o tiro após bater em algo (inimigo ou parede
	queue_free()

func explode():
	if has_exploded: return
	has_exploded = true
	
	speed = 0 
	set_deferred("monitoring", false) 
	set_deferred("monitorable", false) 
	
	# Toca a animação de impacto correspondente ao tamanho do tiro!
	anim.play(anim_hit) 
	await anim.animation_finished 
	queue_free() 

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
