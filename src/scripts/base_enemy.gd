extends CharacterBody2D
class_name BaseEnemy # Permite que o Godot reconheça essa classe globalmente

enum State { IDLE, PATROL, DEAD }

# --- Edite no Inspector para cada inimigo ---
@export var idle_time: float = 1.0

@export var speed: float = 30.0
@export var max_health: int = 2
@export var facing_right: bool = false # Marque 'true' se o sprite original olhar para a direita
@export var gravity: float = 980.0

@onready var anima: AnimatedSprite2D = $AnimatedSprite2D
@onready var wall_detector: RayCast2D = $WallDetector
@onready var ground_detector: RayCast2D = $GroundDetector
@onready var damage_source: Area2D = $DamageSource

var current_health: int
var status: State = State.PATROL
var direction: int = 1

func _ready() -> void:
	current_health = max_health
	# Define a direção inicial baseada na configuração do Inspector
	direction = 1 if facing_right else -1
	anima.play("walk")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	match status:
		State.IDLE:
			# Se estiver IDLE, desacelera suavemente até parar totalmente
			velocity.x = move_toward(velocity.x, 0, speed * delta)
		State.PATROL:
			patrol_state(delta)
		State.DEAD:
			velocity.x = move_toward(velocity.x, 0, speed * delta)

	move_and_slide()

func go_to_idle_state() -> void:
	status = State.IDLE
	anima.play("idle") # Toca a animação de respirar/ficar parado
	
	# Cria um timer invisível que espera o tempo que configuramos no Inspector
	await get_tree().create_timer(idle_time).timeout
	
	# Trava de segurança: só volta a patrulhar se não tiver morrido enquanto esperava!
	if status != State.DEAD:
		status = State.PATROL
		anima.play("walk")

func patrol_state(_delta: float) -> void:
	velocity.x = speed * direction
	
	# Só vira se bater numa parede (do cenário) ou o chão acabar
	if wall_detector.is_colliding() or not ground_detector.is_colliding():
		flip()

func flip() -> void:
	direction *= -1
	
	# Inverte a animação visualmente
	if facing_right:
		anima.flip_h = (direction == -1)
	else:
		anima.flip_h = (direction == 1)
	
	# Inverte a física dos detectores e do ataque
	wall_detector.target_position.x *= -1 
	wall_detector.position.x *= -1       
	ground_detector.position.x *= -1
	
	if damage_source:
		damage_source.position.x *= -1

# O Player (ou magias) chamam essa função para dar dano no inimigo
func take_damage(amount: int, attacker_x_pos: float = 0.0) -> void:
	if status == State.DEAD: return
	
	current_health -= amount
	flash_damage()
	
	if current_health <= 0:
		die()

func flash_damage() -> void:
	var tween = create_tween()
	anima.modulate = Color(10, 10, 10, 1) # Hit flash Branco
	tween.tween_property(anima, "modulate", Color.WHITE, 0.2)

func die() -> void:
	status = State.DEAD
	
	# Desativa a área de dano instantaneamente para o jogador poder encostar no corpo
	if damage_source:
		damage_source.set_deferred("monitoring", false)
		damage_source.set_deferred("monitorable", false)
		
	# Desativa a colisão sólida do corpo
	$CollisionShape2D.set_deferred("disabled", true)
	
	anima.play("dead")
	await anima.animation_finished
	queue_free()
