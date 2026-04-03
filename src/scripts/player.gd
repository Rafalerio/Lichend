extends CharacterBody2D

enum PlayerState { IDLE, WALK, JUMP, FALL, DEAD }

@onready var anima: AnimatedSprite2D = $AnimatedSprite2D

@export var max_speed = 100.0
@export var acceleration = 800.0 # Aumentei para o controle ficar mais responsivo
@export var deceleration = 1000.0 # Aumentei para ele parar mais rápido
const JUMP_VELOCITY = -300.0

var direction = 0
var status: PlayerState

func _ready() -> void:
	go_to_idle_state()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	match status:
		PlayerState.IDLE: idle_state(delta)
		PlayerState.WALK: walk_state(delta)
		PlayerState.JUMP: jump_state(delta)
		PlayerState.FALL: fall_state(delta)
		PlayerState.DEAD: dead_state(delta)
		
	move_and_slide()

# --- FUNÇÕES DE TRANSIÇÃO DE ESTADO ---

func go_to_idle_state():
	status = PlayerState.IDLE
	anima.play("idle")

func go_to_walk_state():
	status = PlayerState.WALK
	anima.play("walk")

func go_to_jump_state():
	status = PlayerState.JUMP
	anima.play("jump")
	velocity.y = JUMP_VELOCITY
	
func go_to_fall_state():
	status = PlayerState.FALL
	anima.play("fall")

func go_to_dead_state():
	status = PlayerState.DEAD
	anima.play("dead")
	velocity = Vector2.ZERO

# --- LÓGICA DOS ESTADOS ---

func idle_state(delta):
	move(delta)
	if velocity.x != 0:
		go_to_walk_state()
	elif Input.is_action_just_pressed("jump") and is_on_floor():
		go_to_jump_state()

func walk_state(delta):
	move(delta)
	if velocity.x == 0:
		go_to_idle_state()
	elif Input.is_action_just_pressed("jump") and is_on_floor():
		go_to_jump_state()
	elif not is_on_floor(): 
		go_to_fall_state()

func jump_state(delta):
	move(delta)
	if velocity.y > 0:
		go_to_fall_state()

func fall_state(delta):
	move(delta)
	if is_on_floor():
		if velocity.x == 0:
			go_to_idle_state()
		else:
			go_to_walk_state()

func dead_state(_delta):
	pass # Fica parado esperando o game over/restart

# --- MOVIMENTO E UTILIDADES ---

func move(delta):
	update_direction()
	if direction != 0:
		velocity.x = move_toward(velocity.x, direction * max_speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, deceleration * delta)

func update_direction():
	direction = Input.get_axis("left", "right")
	if direction < 0:
		anima.flip_h = true
	elif direction > 0:
		anima.flip_h = false

# --- COLISÕES ---

func _on_hitbox_area_entered(area: Area2D) -> void:
	if status == PlayerState.DEAD: return
	
	# Verifica se está caindo
	var is_falling = velocity.y > 0
	
	# Verifica se o Player está fisicamente acima do Inimigo.
	# global_position.y pega a posição exata no mundo. Quanto menor o Y, mais alto está.
	var is_above_enemy = global_position.y < area.global_position.y
	
	if is_falling and is_above_enemy: 
		var enemy = area.get_parent()
		if enemy.has_method("take_damage"):
			enemy.take_damage()
			# Quica no inimigo
			velocity.y = JUMP_VELOCITY * 0.8 
			go_to_jump_state()
	else:
		# Se bateu de lado, por baixo, ou não estava caindo, o player morre
		go_to_dead_state()
