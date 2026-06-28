extends Control

@onready var buttons: Array[Button] = [
	$MainCenter/VerticalStack/MenuOptions/RetryButton,
	$MainCenter/VerticalStack/MenuOptions/MenuButton
]
@onready var selector: Sprite2D = $SelectorIcon
@onready var move_sound: AudioStreamPlayer = $MoveSound
@onready var select_sound: AudioStreamPlayer = $SelectSound

var is_option_selected: bool = false
var offset_x: float = 24.0 
var move_tween: Tween 

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Espera o layout se organizar
	await get_tree().process_frame
	await get_tree().process_frame
	
	buttons[0].grab_focus()
	_move_selector_to(buttons[0], true)
	
	for button in buttons:
		button.focus_entered.connect(_on_button_focus_entered.bind(button))
		button.pressed.connect(_on_button_selected.bind(button))

func _on_button_focus_entered(button: Button) -> void:
	if is_option_selected: return
	_move_selector_to(button, false)
	# Toca o bip sonoro
	if move_sound: move_sound.play()

func _move_selector_to(target_button: Button, instant: bool) -> void:
	if move_tween and move_tween.is_running():
		move_tween.kill()
		
	var target_pos = Vector2(
		target_button.global_position.x - offset_x,
		target_button.global_position.y + (target_button.size.y / 2)
	)
	
	if instant:
		selector.global_position = target_pos
	else:
		move_tween = create_tween()
		move_tween.tween_property(selector, "global_position", target_pos, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _on_button_selected(button: Button) -> void:
	if is_option_selected: return
	is_option_selected = true 
	select_sound.play()
	
	# Efeito de piscar ao selecionar
	var flash_tween = create_tween().set_loops(8)
	flash_tween.tween_property(button, "modulate:a", 0.0, 0.06)
	flash_tween.tween_property(button, "modulate:a", 1.0, 0.06)
	
	await flash_tween.finished
	
	# Executa as ações baseadas no botão clicado
	if button.name == "RetryButton":
		get_tree().change_scene_to_file("res://src/levels/scene.tscn")
	elif button.name == "MenuButton":
		get_tree().change_scene_to_file("res://src/levels/menu.tscn")
