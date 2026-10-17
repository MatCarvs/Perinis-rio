extends CanvasLayer

@onready var popup: PanelContainer = $HintPopup
@onready var hint_label: Label = $HintPopup/MarginContainer/VBoxContainer/HintTextLabel

# Reference to your Main / Board script that contains get_best_hint_candidate()
@onready var game_manager = $".." 

# Pistas indiretas por categoria (as chaves devem ser IGUAIS às do answer_sheet)
const CATEGORY_CLUES := {
	# --- x ---
	"18.10.1.9.99": [
		"Uma das categorias está ligada aos números da Pokédex.",
		"Há 27 anos, houve um dia muito especial! Que dia foi esse mesmo?",
	],
	"BI-cha 💅": [
		"Rosa, João? (isso não é sobre cores)",
		"Olhar o tipo dos Pokémon pode ser uma boa ideia.",
	],
	"Fantasias de carnaval": [
		"Hoje cê pode me esquecer ♬♪",
		"Sabia que Perrserker é conhecido como 'Pokémon Viking'?",
	],
	"Não-monogamia": [
		"Alguns Pokémon nunca estão sozinhos.",
		"Que engraçado, o Mega Chimecho parece estar cercado de vários Chimechinhos.",
	],
	"Muito gostado <3": [
		"Alguns desses Pokémon compartilham um método de evolução especial.",
		"Além do tipo sombrio, que o Persian de Alola tem de diferente do de Kanto?",
	],
	# --- y ---
	"Topete": [
		"Há categorias ligadas à aparência de alguns Pokémon. O que eles têm em comum?",
		"O Dugtrio de Alola tem um característica bem diferente da sua versão original.",
	],
	"pitico 🤏🤏🤏": [
		"Alguns Pokémon ainda têm muito pra crescer na vida.",
		"Alguns Pokémon seriam ótimos salva-vidas. Num aquário talvez.",
	],
	"Criado por jabuti": [
		"Se o Mogli foi criado por lobos, que outro animal poderia criar uma criança?",
		"Olhar o tipo dos Pokémon pode ser uma boa ideia.",
	],
	"RPG": [
		"Um bardo, um artífice, um necromante e um pistoleiro entram numa taverna...",
		"A Blissey é conhecida por cuidar de Pokémon doentes. Seria uma ótima companheira para uma certa classe.",
	],
	"Bigode": [
		"Algumas categorias estão ligadas à aparência de alguns Pokémon. O que eles têm em comum?",
		"Talvez não seja coincidência o Kingler estar na forma G-Max...",
	],
}

func _ready() -> void:
	# Hide the popup overlay when the game starts
	close_hint()

func open_hint() -> void:
	var hint_text = generate_local_hint()
	hint_label.text = hint_text
	
	popup.visible = true

func close_hint() -> void:
	popup.visible = false

# Signal connected from CloseButton
func _on_close_button_pressed() -> void:
	close_hint()

# Gera uma dica indireta com base no estado do tabuleiro
func generate_local_hint() -> String:
	var candidate = game_manager.get_best_hint_candidate()
	
	if candidate.is_empty():
		return "Troque as cartas de lugar e observe com calma. Algumas combinações podem estar escondidas à vista de todos."
	
	var category: String = candidate["category"]
	var count: int = candidate["match_count"]
	
	var intros: Array = []
	if count >= 3:
		intros = [
			"Você está quase lá, mas ainda falta um detalhe...",
			"Algo no tabuleiro está quase certo. Preste atenção:",
			"Falta pouco em algum ponto! Pense nisto:",
		]
	else:
		intros = [
			"Parece que você começou a formar algo em algum lugar...",
			"Há uma ligação surgindo entre algumas cartas. Reflita:",
			"Alguma coisa une alguns desses Pokémon. Pense nisto:",
		]
	
	var clues: Array = CATEGORY_CLUES.get(category, [])
	if clues.is_empty():
		return "Há uma conexão escondida em algum lugar. Olhe de novo para o que as cartas têm em comum."
	
	return "%s\n\n%s" % [intros.pick_random(), clues.pick_random()]
