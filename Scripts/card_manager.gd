extends Node2D

var game_won

var COLLISION_MASK_CARD
var COLLISION_MASK_CARD_SLOT

var screen_size
var card_being_dragged
var target_card_slot
var card_pos 
var mouse_initial_pos

var reg_texture = preload("res://Sprites/Card_back.png")
var hovered_texture = preload("res://Sprites/Card_back_hovered.png")
var selected_texture = preload("res://Sprites/Card_back_selected.png")

func _ready() -> void:
	game_won = false
	screen_size = get_viewport_rect().size
	COLLISION_MASK_CARD = get_parent().COLLISION_MASK_CARD
	COLLISION_MASK_CARD_SLOT = get_parent().COLLISION_MASK_CARD_SLOT
	
func list_clicked() -> Array:
	var list: Array = []
	for i in get_children():
		if "is_clicked" in i and i.is_clicked:
			list.append(i)
	return list

func scatter_pieces_on_grid() -> void:
	var pieces: Array[Node] = []
	for child in self.get_children():
		if child is Node2D:
			pieces.append(child)
	
	var grid_slots: Array[Node] = []
	for x in $'../Slots'.get_child_count():
		var slot = $'../Slots'.get_child(x)
		grid_slots.append(slot)
	
	if grid_slots.size() < pieces.size():
		push_warning("Not enough grid slots for all puzzle pieces!")
		return

	var button_node = self.get_parent()
	var max_attempts = 200
	var attempts = 0
	
	while attempts < max_attempts:
		attempts += 1
		grid_slots.shuffle()
		
		# Assign slots to pieces
		for i in range(pieces.size()):
			pieces[i].position = grid_slots[i].position
			pieces[i].current_slot = grid_slots[i]
			
		# Validate board state via Button script
		if button_node and button_node.has_method("is_initial_board_valid"):
			if button_node.is_initial_board_valid():
				# Board is valid (0 solved lines and max two 3-match lines)
				break
		else:
			break

func select_cards(clicked_card, clear_all: bool) -> void:
	if clear_all:
		for i in get_children():
			if "is_clicked" in i and i != clicked_card:
				i.is_clicked = false
				highlight_card(i, false)
	else:
		for i in get_children():
			# Only unclick cards that are NOT the clicked card, but keep currently clicked ones
			if "is_clicked" in i and i != clicked_card and not i.is_clicked:
				i.is_clicked = false
				highlight_card(i, false)

func _process(delta: float) -> void:
	if card_being_dragged:
		var mouse_pos = get_global_mouse_position()
		card_being_dragged.position = Vector2(
			clamp(mouse_pos.x + card_pos.x - mouse_initial_pos.x, 0-self.position.x, screen_size.x-self.position.x),
			clamp(mouse_pos.y + card_pos.y - mouse_initial_pos.y, 0-self.position.y, screen_size.y-self.position.y)
			)

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var card = raycast_check_for_card()
		var card_slot = raycast_check_for_card_slot()
		
		if event.pressed:
			if card and card.get_node("Area2D").get_collision_layer() == COLLISION_MASK_CARD:
				card_being_dragged = card
				card_pos = card_being_dragged.position
				mouse_initial_pos = get_global_mouse_position()
				
				# Bring dragged card to front visually
				card.get_node("Card_back").texture = selected_texture
				card.get_node("Sprite").z_index = 17
				card.get_node("Card_back").z_index = 16
				
				# Check if there are already clicked cards using the list
				if list_clicked().size() > 0:
					select_cards(card, false)
				else:
					select_cards(card, true)
			else:
				select_cards(null, true)
				
		else: # MOUSE RELEASED
			if card_being_dragged:
				var distance = mouse_initial_pos.distance_to(get_global_mouse_position())
				var is_drag = distance > 5.0 # If mouse moved more than 5 pixels, it's a drag!
				
				var target_slot_to_use = card_slot
				# If we dropped on a card but missed the slot area, use the card's slot
				if not target_slot_to_use and card:
					target_slot_to_use = card.current_slot
					
				var clicked_list = list_clicked()
				var swapped = false
				
				# 1. DRAG-TO-SWAP MECHANIC (Prioritized if dragged)
				if is_drag:
					if target_slot_to_use and 	!game_won:
						var target_card = get_target_card(target_slot_to_use)
						var return_slot = card_being_dragged.current_slot

						move_card(card_being_dragged, target_slot_to_use)
						move_card(target_card, return_slot)
						swapped = true
					else:
						# Return to original position if dropped in empty space
						move_card(card_being_dragged, card_being_dragged.current_slot)
						
				# 2. CLICK-TO-SWAP MECHANIC (Only runs if we didn't drag)
				elif !game_won:
					if clicked_list.size() == 1 and clicked_list[0] != card_being_dragged and target_slot_to_use:
						var first_clicked_card = clicked_list[0]
						var target_card = get_target_card(target_slot_to_use)
						var return_slot = first_clicked_card.current_slot

						move_card(first_clicked_card, target_slot_to_use)
						move_card(target_card, return_slot)
						swapped = true
						
				# 3. CLEANUP VISUAL STATES
				var dragged_card_ref = card_being_dragged
				card_being_dragged = null
				
				var is_mouse_over = (raycast_check_for_card() == dragged_card_ref)
				
				# If we completed any kind of swap, or dragged it, or it was already clicked -> Clear everything
				if swapped or is_drag or dragged_card_ref.is_clicked:
					dragged_card_ref.is_clicked = false
					select_cards(null, true) # Clear all clicked states
					highlight_card(dragged_card_ref, is_mouse_over)
				else:
					# Otherwise, this was a fresh, simple click to select a card. Select it!
					dragged_card_ref.is_clicked = true
					select_cards(dragged_card_ref, true)
					highlight_card(dragged_card_ref, is_mouse_over)

# --- HOVER LOGIC ---

func connect_card_signals(card):
	card.connect("hovered", on_hovered_over_card)
	card.connect("hovered_off", on_hovered_off_card)

func on_hovered_over_card(card):
	if card_being_dragged != null: return
	highlight_card(card, true)

func on_hovered_off_card(card):
	if card_being_dragged == card: return
	highlight_card(card, false)

func highlight_card(card, is_hovered: bool):
	if card.get_node("Area2D").get_collision_layer() == COLLISION_MASK_CARD:
		var extra_z = 0
		
		if card.is_clicked:
			extra_z = 10
			
		if is_hovered or card.is_clicked:
			card.get_node("Sprite").position.y = -5
			card.get_node("Sprite").z_index = 7 + extra_z
			card.get_node("Card_back").z_index = 6 + extra_z
			card.get_node("Card_back").texture = selected_texture if card.is_clicked else hovered_texture

		else:
			card.get_node("Sprite").position.y = 0
			card.get_node("Sprite").z_index = 4 + extra_z
			card.get_node("Card_back").z_index = 2 + extra_z
			card.get_node("Card_back").texture = reg_texture

# --- RAYCASTS & MOVEMENT ---

func raycast_check_for_card():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_CARD
	var result = space_state.intersect_point(parameters)
	if result.size() > 0:
		return result[0].collider.get_parent()
	return null
	
func raycast_check_for_card_slot():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_CARD_SLOT
	var result = space_state.intersect_point(parameters)
	if result.size() > 0:
		return result[0].collider.get_parent()
	return null

func get_target_card(card_slot):
	for i in self.get_child_count():
		if self.get_child(i).current_slot == card_slot:
			return self.get_child(i)
	return null

func move_card(card_being_moved, target_card_slot):
	if card_being_moved and target_card_slot:
		card_being_moved.position = target_card_slot.position
		card_being_moved.current_slot = target_card_slot
		
		# Hide connectors whenever a card moves
		var button_node = $'../Button'
		if button_node and button_node.has_method("clear_all_line_hints"):
			button_node.clear_all_line_hints(false)
