extends CharacterBody2D

enum PlayerState { IDLE, WALK, JUMP, FALL, DASH, HURT, DEAD }

@onready var anima: AnimatedSprite2D = $AnimatedSprite2D
const SHOT = preload("uid://ul47g5ryd1ge")

@export var max_speed = 100.0
@export var acceleration = 800.0
@export var deceleration = 1000.0
@export var dash_speed = 150.0
@export var dash_duration = 0.25
@export var dash_cooldown_time = 0.6 # Tempo de recarga do dash (Ajuste conforme necessário)

@export var max_health: int = 10
var current_health: int

# --- ARMAS E TIROS ---
@export var bullet_scene: PackedScene
var charge_timer: float = 0.0
var is_charging: bool = false
var shoot_cooldown: float = 0.0
var shoot_anim_timer: float = 0.0

var is_invulnerable: bool = false
var invuln_timer: float = 0.0
var hurt_timer: float = 0.0

const JUMP_VELOCITY = -300.0

var direction = 0
var last_facing_direction = 1 # 1 para direita, -1 para esquerda
var status: PlayerState

var can_dash = true
var dash_timer = 0.0
var current_dash_cooldown = 0.0 # Controle interno do cooldown

func _ready() -> void:
	current_health = max_health
	go_to_idle_state()

func _physics_process(delta: float) -> void:
	if invuln_timer > 0:
		invuln_timer -= delta
		anima.visible = false if fmod(invuln_timer, 0.2) < 0.1 else true
		if invuln_timer <= 0:
			anima.visible = true
			is_invulnerable = false

	if shoot_cooldown > 0:
		shoot_cooldown -= delta
	if shoot_anim_timer > 0:
		shoot_anim_timer -= delta
		if shoot_anim_timer <= 0:
			update_base_animation()
			
	if current_dash_cooldown > 0:
		current_dash_cooldown -= delta

	handle_shooting(delta)

	if not is_on_floor() and status != PlayerState.DASH:
		velocity += get_gravity() * delta
	elif is_on_floor():
		can_dash = true # Reseta o dash ao tocar no chão
	
	match status:
		PlayerState.IDLE: idle_state(delta)
		PlayerState.WALK: walk_state(delta)
		PlayerState.JUMP: jump_state(delta)
		PlayerState.FALL: fall_state(delta)
		PlayerState.DASH: dash_state(delta)
		PlayerState.HURT: hurt_state(delta)
		PlayerState.DEAD: dead_state(delta)
		
	move_and_slide()

# --- FUNÇÕES DE TRANSIÇÃO DE ESTADO ---

func go_to_idle_state():
	status = PlayerState.IDLE
	if shoot_anim_timer <= 0: anima.play("idle")

func go_to_walk_state():
	status = PlayerState.WALK
	if shoot_anim_timer <= 0: anima.play("walk")

func go_to_jump_state():
	status = PlayerState.JUMP
	if shoot_anim_timer <= 0: anima.play("jump")
	velocity.y = JUMP_VELOCITY
	
func go_to_fall_state():
	status = PlayerState.FALL
	if shoot_anim_timer <= 0: anima.play("fall")

func go_to_dash_state():
	status = PlayerState.DASH
	if shoot_anim_timer <= 0: anima.play("dash")
	can_dash = false
	dash_timer = dash_duration
	current_dash_cooldown = dash_cooldown_time # Aplica o cooldown
	
	var dash_dir = direction
	if dash_dir == 0: dash_dir = last_facing_direction
	
	velocity.y = 0
	velocity.x = dash_dir * dash_speed

func go_to_hurt_state():
	status = PlayerState.HURT
	if anima.sprite_frames.has_animation("hurt"):
		anima.play("hurt")
	else:
		anima.play("fall")
	hurt_timer = 0.4 

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
	elif Input.is_action_just_pressed("dash") and can_dash and current_dash_cooldown <= 0:
		go_to_dash_state()

func walk_state(delta):
	move(delta)
	if velocity.x == 0:
		go_to_idle_state()
	elif Input.is_action_just_pressed("jump") and is_on_floor():
		go_to_jump_state()
	elif Input.is_action_just_pressed("dash") and can_dash and current_dash_cooldown <= 0:
		go_to_dash_state()
	elif not is_on_floor(): 
		go_to_fall_state()

func jump_state(delta):
	move(delta)
	if Input.is_action_just_pressed("dash") and can_dash and current_dash_cooldown <= 0:
		go_to_dash_state()
		return
		
	if velocity.y > 0:
		go_to_fall_state()

func fall_state(delta):
	move(delta)
	if Input.is_action_just_pressed("dash") and can_dash and current_dash_cooldown <= 0:
		go_to_dash_state()
		return
			
	if is_on_floor():
		if velocity.x == 0:
			go_to_idle_state()
		else:
			go_to_walk_state()

func dash_state(delta):
	dash_timer -= delta
	
	if dash_timer <= 0:
		if is_on_floor():
			go_to_idle_state() if direction == 0 else go_to_walk_state()
		else:
			go_to_fall_state()

func hurt_state(delta):
	hurt_timer -= delta
	velocity.x = move_toward(velocity.x, 0, deceleration * 0.5 * delta)
	
	if hurt_timer <= 0:
		if is_on_floor():
			go_to_idle_state() if velocity.x == 0 else go_to_walk_state()
		else:
			go_to_fall_state()

func take_damage(amount: int):
	if status == PlayerState.DEAD or is_invulnerable: return
	
	current_health -= amount
	print("Player sofreu dano! Vida atual: ", current_health)
	
	flash_damage()
	
	if current_health <= 0:
		go_to_dead_state()
	else:
		is_invulnerable = true
		invuln_timer = 1.0

func add_health_capacity(amount: int):
	max_health += amount
	current_health += amount 
	print("Max HP aumentado! Vida Máxima: ", max_health)

func flash_damage():
	var tween = create_tween()
	anima.modulate = Color(10, 10, 10, 1) 
	tween.tween_property(anima, "modulate", Color.WHITE, 0.2)
	
func dead_state(_delta):
	pass 

# --- MOVIMENTO E UTILIDADES ---

func move(delta):
	update_direction()
	if direction != 0:
		velocity.x = move_toward(velocity.x, direction * max_speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, deceleration * delta)

func handle_shooting(delta):
	if status == PlayerState.DEAD:
		is_charging = false
		charge_timer = 0.0
		return
		
	var active_bullets = get_tree().get_nodes_in_group("PlayerBullets").size()
	
	if Input.is_action_just_pressed("shoot"):
		if active_bullets < 3 and shoot_cooldown <= 0:
			fire_bullet(1) # Tiro normal
			shoot_cooldown = 0.15 
		is_charging = true
		charge_timer = 0.0
		
	if Input.is_action_pressed("shoot") and is_charging:
		charge_timer += delta
		
	if Input.is_action_just_released("shoot"):
		if is_charging:
			if charge_timer >= 1.0: 
				if active_bullets < 3:
					fire_bullet(7) # Tiro carregado nível 2
			elif charge_timer >= 0.4: 
				if active_bullets < 3:
					fire_bullet(3) # Tiro carregado nível 1
			is_charging = false
			charge_timer = 0.0

func fire_bullet(damage_val: int):
	shoot_anim_timer = 0.3 
	
	if bullet_scene:
		var bullet = bullet_scene.instantiate()
		get_tree().current_scene.add_child(bullet)
		
		bullet.add_to_group("PlayerBullets")
		
		# Define onde o tiro nasce (na frente do player)
		var spawn_pos = global_position + Vector2(25 * last_facing_direction, 0)
		
		# Envia as informações essenciais para a bala se configurar
		bullet.setup(spawn_pos, last_facing_direction, damage_val)

func update_base_animation():
	match status:
		PlayerState.IDLE: anima.play("idle")
		PlayerState.WALK: anima.play("walk")
		PlayerState.JUMP: anima.play("jump")
		PlayerState.FALL: anima.play("fall")
		PlayerState.DASH: anima.play("dash")
		PlayerState.HURT:
			if anima.sprite_frames.has_animation("hurt"): anima.play("hurt")
			else: anima.play("fall")
		PlayerState.DEAD: anima.play("dead")

func update_direction():
	direction = Input.get_axis("left", "right")
	if direction < 0:
		anima.flip_h = true
		last_facing_direction = -1
	elif direction > 0:
		anima.flip_h = false
		last_facing_direction = 1

# --- COLISÕES ---

func _on_hitbox_area_entered(area: Area2D) -> void:
	if status == PlayerState.DEAD: return
	
	if not is_invulnerable:
		take_damage(1)
		
		# Efeito de repulsão (Knockback)
		velocity.y = JUMP_VELOCITY * 0.6 
		velocity.x = max_speed * -last_facing_direction * 1.5
		go_to_hurt_state()
