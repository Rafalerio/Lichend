extends StaticBody2D

@export var break_time: float = 0.4 # Tempo até quebrar após pisar
@export var reset_time: float = 3.0 # Tempo para reaparecer

@onready var sprite: Sprite2D = $Sprite2D
@onready var player_detector: Area2D = $PlayerDetector # Detector no topo do bloco
@onready var broken_timer: Timer = $BrokenTimer
@onready var reset_timer: Timer = $ResetTimer

var is_broken = false

func _ready() -> void:
	broken_timer.wait_time = break_time
	reset_timer.wait_time = reset_time
	# NOTA: Certifique-se de conectar os signals timeout() dos dois Timers
	# para as duas funções abaixo lá pelo painel Node (Signals) do editor!

func _process(_delta: float) -> void:
	if is_broken:
		return
		
	# Evita de "ficar iniciando" o timer de quebra várias vezes por frame
	if not broken_timer.is_stopped(): 
		return 
	
	# Checa se há colisão na área que fica sobre a plataforma (PlayerDetector)
	if player_detector.has_overlapping_bodies():
		var bodies = player_detector.get_overlapping_bodies()
		for body in bodies:
			if body.is_in_group("Player"):
				# Dá um visual feedback usando TWEEN (Fica vermelho avisando perigo)
				var tween = create_tween()
				tween.tween_property(sprite, "modulate", Color(1, 0.5, 0.5, 1), break_time)
				
				# Inicia o timer seguindo as regras da arquitetura proposta
				broken_timer.start()
				break

func _on_broken_timer_timeout() -> void:
	is_broken = true
	
	# Muda o layer de collision da plataforma para ela não ser mais um chão sólido (Derruba o player)
	# Supondo que "1" é a layer/mask base do mapa em seu projeto:
	set_collision_layer_value(1, false) 
	set_collision_mask_value(1, false)
	
	# Fade out dinâmico com Tween para desaparecer
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(1, 0.5, 0.5, 0), 0.2)
	
	# Inicia o timer que traz a plataforma de volta à vida
	reset_timer.start()

func _on_reset_timer_timeout() -> void:
	is_broken = false
	
	# Retorna colisão para ser um chão sólido novamente
	set_collision_layer_value(1, true)
	set_collision_mask_value(1, true)
	
	# Retorna a cor original de forma transparente e dá um fade in
	sprite.modulate = Color(1, 1, 1, 0)
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.3)
