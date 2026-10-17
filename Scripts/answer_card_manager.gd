extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func hide_cards():
	for i in self.get_children():
		i.get_node("Label").text = ""
		i.get_node("Sprite2D").visible = false

#When an answer is right
func show_answer_card(category: String, line: String, color: Color):
	var sprite = self.get_node(line).get_node("Sprite2D")
	var replacement_color: Color = color
	
	if sprite.material:
		sprite.material = sprite.material.duplicate()
		var card_material: ShaderMaterial = sprite.material
		
		# Parameter names match the exact names you gave your Parameter nodes in VisualShader
		card_material.set_shader_parameter("Enable", true)
		card_material.set_shader_parameter("ReplacementColor", replacement_color)
	
	self.get_node(line).get_node("Label").text = category
	sprite.visible = true
