extends CharacterBody2D

enum PlayerState { IDLE, WALK, JUMP, FALL, DASH, WALL, HURT, DEAD }

@onready var anima: AnimatedSprite2D = $AnimatedSprite2D
@onready var left_wall_detector: RayCast2D = $LeftWallDetector
@onready var right_wall_detector: RayCast2D = $RightWallDetector

@export var max_speed = 100.0
@export var acceleration = 800.0
@export var deceleration = 1000.0
@export var dash_speed = 300.0
@export var dash_duration = 0.25

@export var wall_slide_speed = 80.0
@export var wall_slide_acceleration = 500.0
@export var wall_jump_pushback = 400.0

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
var last_facing_direction = 1 # 1 for right, -1 for left
var status: PlayerState

var can_dash = true
var dash_timer = 0.0

func _ready() -> void:
	current_health = max_health
	go_to_idle_state()

func _physics_process(delta: float) -> void:
	if invuln_timer > 0:
		invuln_timer -= delta
		# Piscar o sprite para dar feedback visual de i-frames
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
			
	handle_shooting(delta)

	if not is_on_floor() and status != PlayerState.DASH:
		velocity += get_gravity() * delta
	elif is_on_floor():
		can_dash = true # Reset dash when hitting the floor
	
	match status:
		PlayerState.IDLE: idle_state(delta)
		PlayerState.WALK: walk_state(delta)
		PlayerState.JUMP: jump_state(delta)
		PlayerState.FALL: fall_state(delta)
		PlayerState.DASH: dash_state(delta)
		PlayerState.WALL: wall_state(delta)
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
	if shoot_anim_timer <= 0: anima.play("dash") # Make sure there is a "dash" animation
	can_dash = false
	dash_timer = dash_duration
	
	# If not moving, dash in the direction we are facing
	var dash_dir = direction
	if dash_dir == 0: dash_dir = last_facing_direction
	
	velocity.y = 0 # Cancel vertical momentum for air dash
	velocity.x = dash_dir * dash_speed

func go_to_hurt_state():
	status = PlayerState.HURT
	# Toca a animação de "hurt" se houver, ou mantém uma de pulo/queda
	if anima.sprite_frames.has_animation("hurt"):
		anima.play("hurt")
	else:
		anima.play("fall")
	hurt_timer = 0.4 # Tempo em que perdemos controle durante o empurrão

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
	elif Input.is_action_just_pressed("dash") and can_dash:
		go_to_dash_state()

func walk_state(delta):
	move(delta)
	if velocity.x == 0:
		go_to_idle_state()
	elif Input.is_action_just_pressed("jump") and is_on_floor():
		go_to_jump_state()
	elif Input.is_action_just_pressed("dash") and can_dash:
		go_to_dash_state()
	elif not is_on_floor(): 
		go_to_fall_state()

func jump_state(delta):
	move(delta)
	if Input.is_action_just_pressed("dash") and can_dash:
		go_to_dash_state()
		return
		
	if velocity.y > 0:
		go_to_fall_state()

func fall_state(delta):
	move(delta)
	if Input.is_action_just_pressed("dash") and can_dash:
		go_to_dash_state()
		return
		
	# Transição para o estado da Parede (Wall Slide)
	# Apenas permitimos agarrar na parede se estivermos caindo e empurrando contra ela
	if (left_wall_detector.is_colliding() or right_wall_detector.is_colliding()) && is_on_wall():
		var pushing_against_wall = (left_wall_detector.is_colliding() and direction < 0) or (right_wall_detector.is_colliding() and direction > 0)
		if pushing_against_wall:
			go_to_wall_state()
			return
			
	if is_on_floor():
		if velocity.x == 0:
			go_to_idle_state()
		else:
			go_to_walk_state()

func go_to_wall_state():
	status = PlayerState.WALL
	if shoot_anim_timer <= 0: anima.play("wall_slide") 
	can_dash = true # Resetar dash também na parede (Opcional, comum em platformers)

func wall_state(delta):
	# Aplica a gravidade customizada: Deslizamento com aceleração limitada (fricção)
	velocity.y = move_toward(velocity.y, wall_slide_speed, wall_slide_acceleration * delta)
	
	update_direction()
	
	var is_touching_wall = false
	var wall_normal_x = 0
	
	if left_wall_detector.is_colliding():
		is_touching_wall = true
		wall_normal_x = 1 # O empurrão do salto será para a direita (+1)
		anima.flip_h = true
		last_facing_direction = -1
	elif right_wall_detector.is_colliding():
		is_touching_wall = true
		wall_normal_x = -1 # O empurrão do salto será para a esquerda (-1)
		anima.flip_h = false
		last_facing_direction = 1
		
	# Transição de volta ao chão
	if is_on_floor():
		go_to_idle_state() if velocity.x == 0 else go_to_walk_state()
		return
		
	# Transição se soltar a tecla direcional para a direção contrária da parede, ou a parede acabar
	if not is_touching_wall or (wall_normal_x == 1 and direction > 0) or (wall_normal_x == -1 and direction < 0):
		go_to_fall_state()
		return
		
	# Wall Jump! (Aplica o impulso de pulo e queda saindo do estado)
	if Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_VELOCITY
		# Aplicamos o knockback na direção que a normal da parede aponta
		velocity.x = wall_normal_x * wall_jump_pushback
		
		# Transferimos para o Jump State para lidar com o arco do salto 
		go_to_jump_state()
		return

func dash_state(delta):
	dash_timer -= delta
	# Dash velocity is already set in go_to_dash_state. Just maintain it.
	
	if dash_timer <= 0:
		if is_on_floor():
			go_to_idle_state() if direction == 0 else go_to_walk_state()
		else:
			go_to_fall_state()

func hurt_state(delta):
	hurt_timer -= delta
	# Adiciona um leve drag no ar para o knockback não ser infinito
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
		# Acionamos o I-frame para evitar double hits em colisão de Area2D
		is_invulnerable = true
		invuln_timer = 1.0

func add_health_capacity(amount: int):
	max_health += amount
	current_health += amount # Curamos o player ao pegar o item
	print("Max HP aumentado! Vida Máxima: ", max_health)

func flash_damage():
	var tween = create_tween()
	anima.modulate = Color(10, 10, 10, 1) # Hit flash branco
	tween.tween_property(anima, "modulate", Color.WHITE, 0.2)
	
func dead_state(_delta):
	pass # Fica parado esperando o game over/restart

# --- MOVIMENTO E UTILIDADES ---

func move(delta):
	update_direction()
	if direction != 0:
		velocity.x = move_toward(velocity.x, direction * max_speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, deceleration * delta)

func handle_shooting(delta):
	# Evitamos atirar preso na parede ou já morto
	if status == PlayerState.WALL or status == PlayerState.DEAD:
		is_charging = false
		charge_timer = 0.0
		return
		
	var active_bullets = get_tree().get_nodes_in_group("PlayerBullets").size()
	
	if Input.is_action_just_pressed("shoot"):
		if active_bullets < 3 and shoot_cooldown <= 0:
			fire_bullet(1)
			shoot_cooldown = 0.15 # Cooldown minímo
		is_charging = true
		charge_timer = 0.0
		
	if Input.is_action_pressed("shoot") and is_charging:
		charge_timer += delta
		
	if Input.is_action_just_released("shoot"):
		if is_charging:
			if charge_timer >= 1.0: # Tiro nível 3 (Dano 7)
				if active_bullets < 3:
					fire_bullet(7)
			elif charge_timer >= 0.4: # Tiro nível 2 (Dano 3)
				if active_bullets < 3:
					fire_bullet(3)
			is_charging = false
			charge_timer = 0.0

func fire_bullet(damage_val: int):
	# Substitui estado do sprite temporariamente (0.3 seg)
	shoot_anim_timer = 0.3 
	anima.play("shoot")
	
	if bullet_scene:
		var bullet = bullet_scene.instantiate()
		get_tree().current_scene.add_child(bullet)
		
		# Spawna a bala um pouco na frente do player
		var spawn_pos = global_position + Vector2(25 * last_facing_direction, 0)
		bullet.setup(spawn_pos, last_facing_direction, damage_val)

func update_base_animation():
	match status:
		PlayerState.IDLE: anima.play("idle")
		PlayerState.WALK: anima.play("walk")
		PlayerState.JUMP: anima.play("jump")
		PlayerState.FALL: anima.play("fall")
		PlayerState.DASH: anima.play("dash")
		PlayerState.WALL: anima.play("wall_slide")
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
		# Se bateu de lado, por baixo, ou não estava caindo, no lugar de morrer de uma vez
		# Nós tomamos dano do Inimigo. Supondo que ele dê 1 de dano por colisão:
		if not is_invulnerable:
			take_damage(1)
			
			# Empurrão para trás (Knockback base) para não colar no inimigo sofrendo 100 hit kills seguidos
			velocity.y = JUMP_VELOCITY * 0.6 
			velocity.x = max_speed * -last_facing_direction * 1.5
			go_to_hurt_state()
