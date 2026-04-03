extends CharacterBody2D

enum OrcState { WALK, DEAD }

@onready var anima: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox
@onready var wall_detector: RayCast2D = $WallDetector
@onready var ground_detector: RayCast2D = $GroundDetector

const SPEED = 30.0
var status: OrcState = OrcState.WALK
var direction = -1

func _ready() -> void:
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
	# anima.flip_h = (direction == 1)
	
	wall_detector.target_position.x *= -1 
	# Inverte para onde ele aponta
	wall_detector.position.x *= -1       
	 # Inverte de onde ele nasce
	
	ground_detector.position.x *= -1    

func take_damage():
	if status == OrcState.DEAD: return
	go_to_dead_state()

func go_to_dead_state():
	status = OrcState.DEAD
	anima.play("dead")
	hitbox.set_deferred("monitoring", false)
	hitbox.set_deferred("monitorable", false)
