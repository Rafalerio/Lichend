extends CharacterBody2D

enum OrcState { WALK, DEAD }

@onready var anima: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox
@onready var wall_detector: RayCast2D = $WallDetector
@onready var ground_detector: RayCast2D = $GroundDetector

const SPEED = 30.0

@export var max_health: int = 2
var current_health: int

var status: OrcState = OrcState.WALK
var direction = -1

func _ready() -> void:
	current_health = max_health
	go_to_walk_state()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	match status:
		OrcState.WALK:
			walk_state(delta)
		OrcState.DEAD:
			velocity.x = move_toward(velocity.x, 0, SPEED * delta)

	move_and_slide()

func go_to_walk_state():
	status = OrcState.WALK
	anima.play("walk")

func walk_state(_delta):
	velocity.x = SPEED * direction
	
	# Verifica se bateu na parede OU se o chão acabou
	if wall_detector.is_colliding() or not ground_detector.is_colliding():
		flip()

func flip():
	direction *= -1
	
	anima.flip_h = (direction == 1)
	# OBS: Se ele foi desenhado olhando para a ESQUERDA, mude a linha acima para:
	# anima.flip_h = (direction == -1)
	
	wall_detector.target_position.x *= -1 
	# Inverte para onde ele aponta
	wall_detector.position.x *= -1       
	 # Inverte de onde ele nasce
	
	ground_detector.position.x *= -1    

func take_damage(amount: int = 1):
	if status == OrcState.DEAD: return
	
	current_health -= amount
	flash_damage()
	
	if current_health <= 0:
		go_to_dead_state()

func flash_damage():
	var tween = create_tween()
	anima.modulate = Color(10, 10, 10, 1) # Hit flash Branco
	tween.tween_property(anima, "modulate", Color.WHITE, 0.2)

func go_to_dead_state():
	status = OrcState.DEAD
	
	# Desativa a hitbox para ele não machucar o player enquanto a animação toca
	hitbox.set_deferred("monitoring", false)
	hitbox.set_deferred("monitorable", false)
	
	anima.play("dead")
	await anima.animation_finished # Espera a animação de morte terminar
	queue_free() # Deleta o inimigo da memória e tira ele da cena
