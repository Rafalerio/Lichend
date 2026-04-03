extends CharacterBody2D

enum OrcState {
	walk,
	dead
}

@onready var anima: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $hitbox


const SPEED = 300.0
const JUMP_VELOCITY = -400.0

var status: OrcState

func _ready() -> void:	
	go_to_walk_state()

func _physics_process(delta: float) -> void:

	if not is_on_floor():
		velocity += get_gravity() * delta

	match status:
		OrcState.walk:
			walk_state(delta)
		OrcState.dead:
			dead_state(delta)

	move_and_slide()

func go_to_walk_state():
	status = OrcState.walk
	anima.play("walk")

func go_to_dead_state():
	status = OrcState.dead
	anima.play("dead")
	hitbox.process_mode = Node.PROCESS_MODE_DISABLED

func walk_state(delta):
	pass

func dead_state(delta):
	pass

func take_damage():
	go_to_dead_state()
