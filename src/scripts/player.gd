extends CharacterBody2D

enum PlayerState{
	idle,
	walk,
	jump,
	fall,
	dead
}

# Criação da variavel para a referencia do nó de animações.
@onready var anima: AnimatedSprite2D = $AnimatedSprite2D

@export var max_speed = 100.0
@export var acceleration = 100
@export var deceleration = 100
const JUMP_VELOCITY = -300.0

var direction = 0
var status: PlayerState

func move(delta):
	update_direction()
	
	if direction:
		velocity.x = move_toward(velocity.x, direction * max_speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, deceleration * delta)

func _ready() -> void:
	go_to_idle_state()

func _physics_process(delta: float) -> void:
	
	# Adiciona a gravidade.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	match status:
		PlayerState.idle:
			idle_state(delta)
		PlayerState.walk:
			walk_state(delta)
		PlayerState.jump:
			jump_state(delta)
		PlayerState.fall:
			fall_state(delta)
		PlayerState.dead:
			dead_state(delta)
		
	move_and_slide()

func go_to_idle_state():
	status = PlayerState.idle
	anima.play("idle")

func go_to_walk_state():
	status = PlayerState.walk
	anima.play("walk")

func go_to_jump_state():
	status = PlayerState.jump
	anima.play("jump")
	velocity.y = JUMP_VELOCITY
	
func go_to_fall_state():
	status = PlayerState.fall
	anima.play("fall")

func go_to_dead_state():
	status = PlayerState.dead
	anima.play("dead")
	velocity =  Vector2.ZERO

func idle_state(delta):
	move(delta)
	if velocity.x != 0:
		go_to_walk_state()
		return
	
	if Input.is_action_just_pressed("jump"):
		go_to_jump_state()
		return

func walk_state(delta):
	move(delta)
	if velocity.x == 0:
		go_to_idle_state()
		return
	
	if Input.is_action_just_pressed("jump"):
		go_to_jump_state()
		return
		
	if !is_on_floor(): 
		go_to_fall_state()
		return

func jump_state(delta):
	move(delta)
	
	if velocity.y > 0:
		go_to_fall_state()
		return

func fall_state(delta):
	move(delta)
	
	if is_on_floor():
		if velocity.x == 0:
			go_to_idle_state()
		else:
			go_to_walk_state()
		return

func dead_state(delta):
	pass

func update_direction():
	direction = Input.get_axis("left", "right")
	
	if direction < 0:
		anima.flip_h = true
	elif direction > 0:
		anima.flip_h = false

func temp(delta: float) -> void:
	# Adiciona a gravidade.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

func _on_hitbox_area_entered(area: Area2D) -> void:
	if velocity.y > 0: 
		#inimigo morre
		area.get_parent().take_damage()
	else:
		go_to_dead_state()
