extends StaticBody2D

@onready var anim_player = $AnimationPlayer
@onready var solid_collision = $SolidCollision
@onready var detector_collision = $PlayerDetector/DetectorCollision

# Tempos configuráveis no Inspector
@export var break_time: float = 1.85 # Tempo que o bloco treme/racha antes de sumir
@export var respawn_time: float = 3.0 # Tempo para o bloco voltar

var is_breaking: bool = false

func _ready():
	# Garante que o bloco comece normal
	reset_platform()

# ATENÇÃO: Conecte o sinal "body_entered" do seu nó PlayerDetector a esta função!
func _on_player_detector_body_entered(body):
	# Se o bloco já estiver quebrando ou sumido, ignora
	if is_breaking:
		return
		
	# Verifica se quem pisou foi o player (você pode usar grupos ou nome)
	if body.name == "Player" or body.has_method("take_damage"):
		start_breaking()

func start_breaking():
	is_breaking = true
	# Toca a animação da sprite sheet rachando
	anim_player.play("break")
	
	# Cria um timer via código para o tempo de quebra
	await get_tree().create_timer(break_time).timeout
	break_platform()

func break_platform():
	solid_collision.set_deferred("disabled", true)
	detector_collision.set_deferred("disabled", true)
	
	$Sprite2D.visible = false
	await get_tree().create_timer(respawn_time).timeout
	reset_platform()

func reset_platform():
	is_breaking = false
	$Sprite2D.visible = true
	anim_player.play("idle")
	
	solid_collision.set_deferred("disabled", false)
	detector_collision.set_deferred("disabled", false)
