class_name CardDisplay
extends Control

var texture_rect: TextureRect
var button: Button
var card_data: Card
var is_face_up: bool = true

signal card_clicked(card_display: CardDisplay)

func _ready():
	texture_rect = get_node("TextureRect")
	button = get_node("Button")
	if button:
		button.pressed.connect(_on_button_pressed)

func setup_card(card: Card, face_up: bool = true):
	card_data = card
	is_face_up = face_up
	update_display()

func update_display():
	if not texture_rect:
		return
		
	var path: String
	if is_face_up and card_data:
		path = "res://art/deck/" + card_data.get_filename()
	else:
		path = "res://art/deck/B.png"
	
	texture_rect.texture = load(path)

func _on_button_pressed():
	card_clicked.emit(self)
	print("Clicked card: %s" % card_data.get_filename())
