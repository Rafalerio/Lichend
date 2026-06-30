extends Sprite2D

var time_passed: float = 0.0
var float_speed: float = 3.0 # Velocidade do sobe e desce
var float_amplitude: float = 1.0 # Altura do sobe e desce
var start_y: float

func _ready():
	# Salva a posição Y inicial relativa ao Lich
	start_y = position.y

func _process(delta):
	time_passed += delta
	# Usa uma onda senoidal (sin) para criar o movimento suave
	position.y = start_y + sin(time_passed * float_speed) * float_amplitude
