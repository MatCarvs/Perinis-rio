extends Node2D

signal hovered
signal hovered_off

var is_clicked: bool = false
var current_slot = null

var _color: Color
var _Answer
var _Key: String

# Node References
@onready var http_request: HTTPRequest = $Sprite/HTTPRequest
@onready var sprite: Sprite2D = $Sprite

func _ready() -> void:
	# All cards must be a child of Card_manager
	if get_parent().has_method("connect_card_signals"):
		get_parent().connect_card_signals(self)
	
	# Connect HTTP Request signal
	$Sprite/HTTPRequest.request_completed.connect(_on_image_request_completed)
	
	# Dynamically fetch the sprite based on this card's name
	var base_pokemon_name = get_clean_pokemon_name(self.name)
	fetch_pokemon_sprite(base_pokemon_name)
	
	# Category matching logic
	var button_node = get_parent().get_parent()
	if button_node and "answer_sheet" in button_node:
		# Percorre todas as categorias do dicionário (tanto do X quanto do Y se necessário)
		for key in button_node.answer_sheet:
			# O operador 'in' busca o nome diretamente no array de cartas da categoria
			if self.name in button_node.answer_sheet[key]:
				_Answer = button_node.answer_sheet[key]
				_Key = key
				break # Encontrou a categoria, pode sair do loop
		if _Key in button_node.category_colors:
			_color = button_node.category_colors[_Key]

# Helper to strip suffixes like "_Shiny", "_Mega", "_GMax", "_Alola" for API lookups
func get_clean_pokemon_name(raw_name: String) -> String:
	var parts = raw_name.split("_")
	return parts[0].to_lower()

# Step 1: Query PokeAPI to get the sprite URL for the Pokémon name
func fetch_pokemon_sprite(pokemon_name: String) -> void:
	var api_url = "https://pokeapi.co/api/v2/pokemon/" + pokemon_name
	var error = http_request.request(api_url)
	if error != OK:
		push_error("Failed to initiate HTTP request for %s: Error code %d" % [pokemon_name, error])

# Handle HTTP Response (2-step: JSON metadata -> Image Binary)
func _on_image_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		push_error("HTTP Request failed with status code: %d" % response_code)
		return

	# If the response is JSON, parse it to extract the sprite URL
	var json = JSON.new()
	if json.parse(body.get_string_from_utf8()) == OK:
		var data = json.data
		if data is Dictionary and data.has("sprites"):
			var sprite_url = data["sprites"]["front_default"]
			if self.name.contains("Shiny") and data["sprites"]["front_shiny"]:
				sprite_url = data["sprites"]["front_shiny"]
				
			# Disconnect JSON callback and reconnect for raw image download
			http_request.request_completed.disconnect(_on_image_request_completed)
			http_request.request_completed.connect(_on_texture_downloaded)
			http_request.request(sprite_url)
			return

# Step 2: Receive the binary image and apply to Sprite2D
func _on_texture_downloaded(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		push_error("Image download failed with status code: %d" % response_code)
		return

	var image = Image.new()
	var err = image.load_png_from_buffer(body)
	if err != OK:
		push_error("Could not parse image data into PNG texture.")
		return

	var texture = ImageTexture.create_from_image(image)
	
	# Apply texture and enforce Nearest pixel-art filtering
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _on_area_2d_mouse_entered() -> void:
	emit_signal("hovered", self)

func _on_area_2d_mouse_exited() -> void:
	emit_signal("hovered_off", self)
