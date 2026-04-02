extends CharacterBody2D

enum PlayerState{
	idle,
	walk,
	jump
}

# Criação da variavel para a referencia do nó de animações.
@onready var anima: AnimatedSprite2D = $AnimatedSprite2D

const SPEED = 100.0
const JUMP_VELOCITY = -300.0

var status: PlayerState

func _ready() -> void:
	go_to_idle_state()

func _physics_process(delta: float) -> void:
	
	# Adiciona a gravidade.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	match status:
		PlayerState.idle:
			idle_state()
		PlayerState.walk:
			walk_state()
		PlayerState.jump:
			jump_state()
			
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

func idle_state():
	move()
	if velocity.x != 0:
		go_to_walk_state()
		return
	
	if Input.is_action_just_pressed("jump"):
		go_to_jump_state()
		return

func walk_state():
	move()
	if velocity.x == 0:
		go_to_idle_state()
		return
	
	if Input.is_action_just_pressed("jump"):
		go_to_jump_state()
		return
		

func jump_state():
	move()
	if is_on_floor():
		if velocity.x == 0:
			go_to_idle_state()
		else:
			go_to_walk_state()
		return

func move():
	var direction := Input.get_axis("left", "right")
	
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
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
