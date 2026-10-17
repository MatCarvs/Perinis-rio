extends Node

# Reference to your answer sheets and colors from your Button script
@onready var main_game = $'.' # Adjust node path as needed

var COLLISION_MASK_CARD = 1
var COLLISION_MASK_CARD_SLOT = 2

var answer_sheet = {
	#x
	"18.10.1.9.99" : ["pidgeot", "caterpie", "bulbasaur", "blastoise-mega", "kingler-gmax"],
	"BI-cha 💅" :["scream-tail", "togepi", "meganium-mega", "tinkaton", "weezing-galar"],
	"Fantasias de carnaval" :["malamar-mega", "cubone", "serperior", "darkrai", "perrserker"],
	"Não-monogamia" : ["dugtrio-alola", "combee", "exeggutor", "chimecho-mega", "probopass"],
	"Muito gostado <3" :["clefairy", "swoobat", "leavanny", "blissey", "persian-alola"],
	#y
	"Topete" : ["pidgeot", "scream-tail", "malamar-mega", "dugtrio-alola", "clefairy"],
	"pitico 🤏🤏🤏" :["caterpie", "togepi", "cubone", "combee", "swoobat"],
	"Criado por jabuti" :["bulbasaur", "meganium-mega", "serperior", "exeggutor", "leavanny"],
	"RPG" :["blastoise-mega", "tinkaton", "darkrai", "chimecho-mega", "blissey"],
	"Bigode" :["kingler-gmax", "weezing-galar", "perrserker", "probopass", "persian-alola"]
}

var category_colors = {
	"Muito gostado <3": Color("#D1424C"),
	"pitico 🤏🤏🤏": Color("#D57438"),
	"Topete": Color("#4BA5AB"),
	"Criado por jabuti": Color("#7EB24E"),
	"RPG": Color("#D8A523"),
	"18.10.1.9.99": Color("#4E7DB7"),
	"Não-monogamia": Color("#ABACC4"),
	"Bigode": Color("#AA815A"),
	"Fantasias de carnaval": Color("#A077BE"),
	"BI-cha 💅": Color("#D370AA")
}

var rows = {
	"1": [],
	"2": [],
	"3": [],
	"4": [],
	"5": []
}

var columns = {
	"A": [],
	"B": [],
	"C": [],
	"D": [],
	"E":[]
}

var line_tweens: Dictionary = {}

@onready var answer_card = $'Answer_card_manager'

func _ready() -> void:
	$Card_manager.scatter_pieces_on_grid()

func get_best_hint_candidate() -> Dictionary:
	get_rows()
	get_columns()
	
	var all_lines: Array = []
	for k in rows.keys():
		all_lines.append({"type": "Row", "key": k, "cards": rows[k]})
	for k in columns.keys():
		all_lines.append({"type": "Column", "key": k, "cards": columns[k]})
	
	var best_count := 0
	var best_candidates: Array = []
	
	for line in all_lines:
		for category in answer_sheet.keys():
			var correct_cards: Array = answer_sheet[category]
			var match_count := 0
			
			# Conta a linha INTEIRA antes de decidir qualquer coisa
			for card_name in line["cards"]:
				if card_name in correct_cards:
					match_count += 1
			
			# 5 já está resolvido
			if match_count < 2 or match_count > 4:
				continue
			
			var candidate := {
				"category": category,
				"match_count": match_count,
				"line_type": line["type"],
				"line_key": line["key"]
			}
			
			if match_count > best_count:
				best_count = match_count
				best_candidates = [candidate]
			elif match_count == best_count:
				best_candidates.append(candidate)
	
	if best_candidates.is_empty():
		return {}
	
	return best_candidates.pick_random()

func _on_hint_button_pressed() -> void:
	$HintLayer.open_hint()
	
func _on_button_pressed() -> void:
	$Answer_card_manager.hide_cards()
	get_right()
	
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
		var line_has_4_matches = false
		
		for  category in answer_sheet.keys():
				var correct_cards = answer_sheet[category]
				var match_count = 0
				
				for card_name in submitted_line:
					if card_name in correct_cards:
						match_count += 1
				
				# "One Away" Hint: Line has 4 matching cards
				if match_count == 4:
					print(category)
					print(correct_cards)
					line_has_4_matches = true
						
				# Completed category
				if match_count == 5:
					total_matches += 1
					answer_card.show_answer_card(category, line["name"], category_colors[category])
					set_line_one_away_hint(line["name"], true, category_colors[category], true)
					print(line["name"] + " está correta com a categoria: " + category)			
		
		if line_has_4_matches:
			print(line)
			answer_card.show_answer_card("Falta um!", line["name"], Color('#141617'))
			set_line_one_away_hint(line["name"], true, Color('#0000005c'), false)

	# Fixed: Moved win check back into get_right scope
	if total_matches == 10:
		$'Card_manager'.game_won = true
		$'Cake'.visible = true
		$'Gligar'.celebrate()
		$Label2.visible = true
		$Button.visible = false
		
		print("Você venceu! Todos os 16 Pokémon estão corretos.")

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

func is_initial_board_valid() -> bool:
	get_rows()
	get_columns()
	
	var three_match_lines = 0
	var all_lines = []
	for key in rows.keys(): all_lines.append(rows[key])
	for key in columns.keys(): all_lines.append(columns[key])
	
	for line_cards in all_lines:
		var line_has_three = false
		
		for category in answer_sheet.keys():
			var correct_cards = answer_sheet[category]
			var match_count = 0
			
			for card_name in line_cards:
				if card_name in correct_cards:
					match_count += 1
			
			# RULE 1: Disqualify board if ANY line is already fully solved
			if match_count == 5:
				return false
			
			if match_count >= 3:
				line_has_three = true
		
		if line_has_three:
			three_match_lines += 1
			
	# RULE 2: Max 2 lines with 3 matches allowed
	return three_match_lines == 2
	
# --- LINE HINT VISUALS ---
func set_line_one_away_hint(line_name: String, active: bool, xcolor: Color, is_five: bool):
	if not has_node("Slots_connect"):
		return
		
	# Find connector(s) corresponding to line_name ("1", "2", "A", etc.) and set visibility
	for connector in $'Slots_connect'.get_children():
		if connector.name.ends_with(line_name):
			if (!is_five and !connector.name.begins_with("X")) or is_five:
				connector.visible = active
				connector.color = xcolor

func clear_all_line_hints(is_five: bool):
	if not has_node("Slots_connect"):
		return
		
	# Instantly hide all connectors
	for connector in $'Slots_connect'.get_children():
		if (is_five and connector.color == Color("000000")) or !is_five:
			connector.visible = false
