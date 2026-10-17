extends Node2D

var celebrating: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func celebrate():
	celebrating = true
	sprite.play("celebration")

func _on_area_2d_mouse_entered() -> void:
	if $'../Card_manager'.card_being_dragged:
		print("zzz")
		sprite.play("hovered")

func _on_area_2d_mouse_exited() -> void:
	if celebrating:
		sprite.play("celebration")
	else:
		sprite.play("default")
