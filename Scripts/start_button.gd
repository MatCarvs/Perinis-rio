extends Node2D

var tex_btn_normal = preload("res://Sprites/Button.png")
var tex_btn_pressed = preload("res://Sprites/Button_pressed.png")
var tex_btn_hovered = preload("res://Sprites/Button_hovered.png")
	
var is_hovered: bool = false
var is_pressed: bool = false

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file('res://Scenes/tutorial.tscn')
	
func _on_button_button_down() -> void:
	is_pressed = true
	$Button.icon = tex_btn_pressed
	$Button/Label.position.x = -1
	$Button/Label.position.y = -1
	$Button/Label.label_settings.shadow_offset = Vector2(4, 4)

func _on_button_button_up() -> void:
	is_pressed = false
	$Button.icon = tex_btn_normal
	$Button/Label.position.x = 0
	$Button/Label.position.y = 0
	$Button/Label.label_settings.shadow_offset = Vector2(2, 2)
	
func _on_button_mouse_entered() -> void:
	is_hovered = true
	if not is_pressed:
		$Button.icon = tex_btn_hovered

func _on_button_mouse_exited() -> void:
	is_hovered = false
	if not is_pressed:
		$Button.icon = tex_btn_normal
