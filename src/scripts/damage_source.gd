extends Area2D
class_name DamageSource # Permite que você ache essa classe no Godot facilmente

# Ao usar @export, o valor vai aparecer no Inspector!
@export var damage: int = 1

func _ready():
	# Conecta o sinal automaticamente via código
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D):
	# Pega o nó "Pai" da área atingida (Se a área for a Hitbox do player, o pai é o CharacterBody2D do Player)
	var victim = area.get_parent()
	
	# Se a vítima for o próprio dono desse DamageSource, ignora!
	if victim == get_parent():
		return
	
	# Verifica se a vítima atingida tem a instância de tomar dano
	if victim and victim.has_method("take_damage"):
		# Aplica a quantidade específica de dano e envia a posição para calcular o empurrão!
		victim.take_damage(damage, global_position.x)
