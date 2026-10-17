extends Node2D

var COLLISION_MASK_CARD = 3
var COLLISION_MASK_CARD_SLOT = 3

var page

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_card_positions()
	page = 0
	tutorial()

@onready var answer_card = $'Answer_card_manager'

var answer_sheet = {
	#x
	"Iniciais de água" : ["squirtle", "swampert", "empoleon"],
	"Habilidade Water Absorb" : ["poliwrath", "quagsire", "volcanion"],
	"Fossil" : ["aerodactyl","tirtouga","arctovish"],
	#y
	"Kanto": ["squirtle", "poliwrath", "aerodactyl"],
	"4x Grama" : ["swampert", "quagsire", "tirtouga"],
	"0.25x Gelo" : ["empoleon", "volcanion", "arctovish"]
}

var category_colors = {
	"Kanto": Color("#D1424C"),
	"Fossil": Color("#D57438"),
	"0.25x Gelo": Color("#4BA5AB"),
	"4x Grama": Color("#7EB24E"),
	"Iniciais de água": Color("#4E7DB7"),
	"Habilidade Water Absorb": Color("#A077BE")
}

var rows = {
	"1": [],
	"2": [],
	"3": []
}

var columns = {
	"A": [],
	"B": [],
	"C": []
}

func tutorial():
	var tut_text = $TutorialText/MarginContainer/VBoxContainer/TutorialTextLabel
	var tut_page = $TutorialText/Page
	
	if page == 0:
		
		get_card_positions()
		
		tut_text.text = \
		"O objetivo do jogo é organizar os Pokémon \
		em suas respectivas categorias."
		tut_page.text = "1/5"
		$Button1.visible = false
		$Button2/button_tutorial_2/Label.text = ">"
	
	if page == 1:
		var pieces: Array[Node] = []
		for child in $Card_manager.get_children():
			if child is Node2D:
				pieces.append(child)
		
		$Card_manager/squirtle.current_slot = $Slots/A1
		$Card_manager/arctovish.current_slot = $Slots/C1
		$Card_manager/aerodactyl.current_slot = $Slots/B2
		
		for i in range(pieces.size()):
			pieces[i].position = pieces[i].current_slot.position
		
		tut_text.text = \
		"Quando todos os Pokémon da mesma categoria estiverem alinhados, \
		a categoria será revelada. Também será mostrado quando faltar apenas \
		um Pokémon para completar uma categoria."
		
		tut_page.text = "2/5"
		
		$Button1.visible = true
		
		get_right()
		
	if page == 2:
		var pieces: Array[Node] = []
		for child in $Card_manager.get_children():
			if child is Node2D:
				pieces.append(child)
		
		$Card_manager/volcanion.current_slot = $Slots/C3
		$Card_manager/aerodactyl.current_slot = $Slots/C1
		$Card_manager/arctovish.current_slot = $Slots/B2
		$Card_manager/quagsire.current_slot = $Slots/B3
		
		for i in range(pieces.size()):
			pieces[i].position = pieces[i].current_slot.position
		
		tut_text.text = \
		"Cada Pokémon possui duas categorias. Cada linha e cada coluna representará \
		uma categoria."
		
		tut_page.text = "3/5"
		
		$Button2/button_tutorial_2/Label.text = ">"		
		
		get_right()

	if page == 3:
		
		var pieces: Array[Node] = []
		for child in $Card_manager.get_children():
			if child is Node2D:
				pieces.append(child)
		
		$Card_manager/volcanion.current_slot = $Slots/B3
		$Card_manager/arctovish.current_slot = $Slots/C3
		$Card_manager/quagsire.current_slot = $Slots/B2
		
		for i in range(pieces.size()):
			pieces[i].position = pieces[i].current_slot.position
		
		$Perini.visible = false
		$Gligar.get_node("AnimatedSprite2D").play("default")
		
		tut_text.text = \
		"Para resolver os quebra-cabeça, todos os Pokémon devem estar \
		alinhados com suas duas categorias."
		
		tut_page.text = "4/5"
		
		$Button2/button_tutorial_2/Label.text = ">"
	
		get_right()
	
	if page == 4:
		
		$Perini.visible = true
		$Gligar.get_node("AnimatedSprite2D").play("happy")
		
		tut_text.text = \
		"Obviamente, todas as categorias estão relacionadas ao \
		aniversariante desse dias mais que especial. Boa sorte!"
		
		tut_page.text = "5/5"
		
		$Button2/button_tutorial_2/Label.text = "Ok"
	
func _on_button_tutorial_2_pressed() -> void:
	$Answer_card_manager.hide_cards()
	
	print(2)
	
	if page < 4:
		page +=1
		tutorial()
	
	elif page == 4:
		get_tree().change_scene_to_file('res://Scenes/main.tscn')

func _on_button_tutorial_1_pressed() -> void:
	print(1)	
	if page > 0:
		page -=1
		tutorial()


func get_card_positions():
	var pieces: Array[Node] = []
	for child in $Card_manager.get_children():
		if child is Node2D:
			pieces.append(child)
	
	var grid_slots: Array[Node] = []
	for x in $'Slots'.get_child_count():
		var slot = $'Slots'.get_child(x)
		grid_slots.append(slot)
	
	if grid_slots.size() < pieces.size():
		push_warning("Not enough grid slots for all puzzle pieces!")
		return
	
	for i in range(pieces.size()):
		pieces[i].position = grid_slots[i].position
		pieces[i].current_slot = grid_slots[i]

func get_columns():
	for key in columns.keys():
		columns[key].clear()
	
	var cards = $"Card_manager".get_children()
	var slots = $'Slots'.get_children()
	
	for slot in slots:
		for card in cards:
			if card.current_slot != null and card.current_slot == slot:
				var slot_name = card.current_slot.name
				for column_key in columns.keys():
					if slot_name.begins_with(column_key):
						columns[column_key].append(card.name)
						break

func get_right():

	var total_matches = 0
	get_rows()
	get_columns()
	
	clear_all_line_hints(true)
	
	var all_lines = []
	for key in rows.keys(): all_lines.append({"name": key, "cards": rows[key]})
	for key in columns.keys(): all_lines.append({"name": key, "cards": columns[key]})
	
	for line in all_lines:
		var submitted_line = line["cards"]
		var line_has_2_matches = false
		
		print(line)
		
		for  category in answer_sheet.keys():
				var correct_cards = answer_sheet[category]
				var match_count = 0
				
				for card_name in submitted_line:
					if card_name in correct_cards:
						match_count += 1
				
				# "One Away" Hint: Line has 4 matching cards
				if match_count == 2:
					print(category)
					print(correct_cards)
					line_has_2_matches = true
						
				# Completed category
				if match_count == 3:
					total_matches += 1
					answer_card.show_answer_card(category, line["name"], category_colors[category])
					set_line_one_away_hint(line["name"], true, category_colors[category], true)
					print(line["name"] + " está correta com a categoria: " + category)			
		
		if line_has_2_matches:
			print(line)
			answer_card.show_answer_card("Falta um!", line["name"], Color('#141617'))
			set_line_one_away_hint(line["name"], true, Color('#0000005c'), false)

	# Fixed: Moved win check back into get_right scope
	if total_matches == 6:
		$'Card_manager'.game_won = true
		#$'Cake'.visible = true
		#$'Gligar'.celebrate()

func get_rows():
	for key in rows.keys():
		rows[key].clear()
	
	var cards = $"Card_manager".get_children()
	var slots = $'Slots'.get_children()
	
	for slot in slots:
		for card in cards:
			if card.current_slot != null and card.current_slot == slot:
				var slot_name = card.current_slot.name
				for row_key in rows.keys():
					if slot_name.ends_with(row_key):
						rows[row_key].append(card.name)
						break
			
# --- LINE HINT VISUALS ---
func set_line_one_away_hint(line_name: String, active: bool, xcolor: Color, is_right: bool):
	if not has_node("Slots_connect"):
		return
		
	# Find connector(s) corresponding to line_name ("1", "2", "A", etc.) and set visibility
	for connector in $'Slots_connect'.get_children():
		if connector.name.ends_with(line_name):
			if (!is_right and !connector.name.begins_with("X")) or is_right:
				connector.visible = active
				connector.color = xcolor

func clear_all_line_hints(is_five: bool):
	if not has_node("Slots_connect"):
		return
		
	# Instantly hide all connectors
	for connector in $'Slots_connect'.get_children():
		if (is_five):
			connector.visible = false
