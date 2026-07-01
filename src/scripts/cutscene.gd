extends Control

# Isso permite escrever o texto e definir a próxima cena direto no Inspector!
@export_multiline var dialogue_lines: Array[String]
@export_file("*.tscn") var next_scene_path: String

@onready var text_label: RichTextLabel = $MarginContainer/RichTextLabel
@onready var timer: Timer = $Timer
@onready var audio: AudioStreamPlayer = $AudioStreamPlayer

var current_line: int = 0
var is_typing: bool = false

func _ready() -> void:
	if dialogue_lines.size() > 0:
		show_line()
	else:
		finish_cutscene()

func show_line() -> void:
	text_label.text = dialogue_lines[current_line]
	text_label.visible_characters = 0 # Esconde todo o texto
	is_typing = true
	timer.start()

func _input(event: InputEvent) -> void:
	# O jogador pode avançar usando o pulo, tiro ou o enter (ui_accept)
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("jump") or event.is_action_pressed("shoot"):
		if is_typing:
			# Se ainda está digitando, pula a animação e mostra a frase toda
			text_label.visible_characters = text_label.get_total_character_count()
			is_typing = false
			timer.stop()
		else:
			# Se já terminou de digitar, passa para a próxima linha
			current_line += 1
			if current_line < dialogue_lines.size():
				show_line()
			else:
				finish_cutscene()

func _on_timer_timeout() -> void:
	# Adiciona uma letra por vez e toca o bipe
	if text_label.visible_characters < text_label.get_total_character_count():
		text_label.visible_characters += 1
		audio.play()
	else:
		is_typing = false
		timer.stop()

func finish_cutscene() -> void:
	if next_scene_path != "":
		get_tree().change_scene_to_file(next_scene_path)
