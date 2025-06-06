extends Control

# Import the Card class - adjust paths based on your file structure
const Card = preload("res://scripts/card.gd")
const CardDisplay = preload("res://scenes/carddisplay.tscn")

# Game state
var deck = []
var player_hand = []
var cpu_hand = []
var player_books = []
var cpu_books = []
var current_turn = "player"  # "player" or "cpu"
var game_over = false

# UI nodes
@onready var player_hand_container = $VBoxContainer/PlayerArea/PlayerHandContainer
@onready var cpu_hand_container = $VBoxContainer/CPUArea/CPUHandContainer
@onready var deck_container = $VBoxContainer/DeckArea/DeckContainer
@onready var game_log = $VBoxContainer/GameLog/GameLogText
@onready var player_books_label = $VBoxContainer/PlayerArea/PlayerBooksLabel
@onready var cpu_books_label = $VBoxContainer/CPUArea/CPUBooksLabel

func _ready():
	start_new_game()

func setup_ui():
	pass

func start_new_game():
	# Initialize deck using Card class
	deck.clear()
	for suit in Card.Suit.values():
		for rank in Card.Rank.values():
			deck.append(Card.new(rank, suit))
	
	# Shuffle deck
	deck.shuffle()
	
	# Deal initial hands (7 cards each)
	player_hand.clear()
	cpu_hand.clear()
	player_books.clear()
	cpu_books.clear()
	
	for i in range(7):
		player_hand.append(deck.pop_back())
		cpu_hand.append(deck.pop_back())
	
	# Sort hands
	sort_hand(player_hand)
	sort_hand(cpu_hand)
	
	# Debug initial hands
	print("GAME START: Initial deal - Player hand counts:")
	debug_hand_counts(player_hand)
	print("GAME START: Initial deal - CPU hand counts:")
	debug_hand_counts(cpu_hand)
	
	# Check for initial books
	check_and_remove_books(player_hand, player_books, true)
	check_and_remove_books(cpu_hand, cpu_books, true)
	
	# Reset game state
	current_turn = "player"
	game_over = false
	
	update_ui()
	log_message("Game started! You have " + str(player_hand.size()) + " cards.")

func debug_hand_counts(hand):
	var rank_counts = {}
	for card in hand:
		if card.rank in rank_counts:
			rank_counts[card.rank] += 1
		else:
			rank_counts[card.rank] = 1
	print("  Rank counts: ", rank_counts)

func sort_hand(hand):
	hand.sort_custom(func(a, b): return a.rank < b.rank or (a.rank == b.rank and a.suit < b.suit))

func check_and_remove_books(hand, books, is_initial_deal = false):
	var rank_counts = {}
	
	# Count cards of each rank
	for card in hand:
		if card.rank in rank_counts:
			rank_counts[card.rank] += 1
		else:
			rank_counts[card.rank] = 1
	
	# Remove books (pairs from sets of 2 or more) and update the actual hand array
	for rank in rank_counts:
		if rank_counts[rank] >= 2:
			books.append(rank)
			var label = ""
			if is_initial_deal:
				if hand == player_hand:
					label = "INITIAL DEAL: Player made match"
				else:
					label = "INITIAL DEAL: CPU made match"
			else:
				label = "PLAYER TURN" if current_turn == "player" else "CPU TURN"
			print(label, " - ", rank_name(rank), "s!")
			log_message("Book completed: " + rank_name(rank) + "s!")
			# Remove all cards of this rank from hand
			for i in range(hand.size() - 1, -1, -1):
				if hand[i].rank == rank:
					hand.remove_at(i)

func update_ui():
	# Clear existing displays
	for child in player_hand_container.get_children():
		child.queue_free()
	for child in cpu_hand_container.get_children():
		child.queue_free()
	for child in deck_container.get_children():
		child.queue_free()
	
	# Update player hand display with CardDisplay scenes
	for card in player_hand:
		var card_display = CardDisplay.instantiate()
		player_hand_container.add_child(card_display)
		card_display.setup_card(card, true)
		card_display.card_clicked.connect(_on_player_card_clicked)
	
	# Update CPU hand display (face down)
	for card in cpu_hand:
		var card_display = CardDisplay.instantiate()
		cpu_hand_container.add_child(card_display)
		card_display.setup_card(card, false)  # Face down
	
	# Update deck display - show some random face-down cards for visual
	var cards_to_show = min(deck.size(), 10)  # Show up to 10 cards
	for i in range(cards_to_show):
		var card_display = CardDisplay.instantiate()
		deck_container.add_child(card_display)
		var random_card = deck[randi() % deck.size()]  # Pick random card for display
		card_display.setup_card(random_card, false)  # Face down
		card_display.card_clicked.connect(_on_deck_card_clicked)
	
	# Update books display
	player_books_label.text = "Your Books (" + str(player_books.size()) + "): " + books_text(player_books)
	cpu_books_label.text = "CPU Books (" + str(cpu_books.size()) + "): " + books_text(cpu_books)

func get_available_ranks(hand):
	var ranks = []
	for card in hand:
		if card.rank not in ranks:
			ranks.append(card.rank)
	return ranks

func _on_player_card_clicked(card_display: CardDisplay):
	print("PLAYER TURN: Clicked card - ", rank_name(card_display.card_data.rank), " of ", suit_name(card_display.card_data.suit))
	if current_turn != "player" or game_over:
		return
	
	# Ask for the rank of the clicked card
	var card_rank = card_display.card_data.rank
	player_ask_for_rank(card_rank)

func rank_name(rank):
	match rank:
		Card.Rank.ACE: return "Ace"
		Card.Rank.JACK: return "Jack"
		Card.Rank.QUEEN: return "Queen"
		Card.Rank.KING: return "King"
		_: return str(rank)

func books_text(books):
	if books.is_empty():
		return "None"
	var text = ""
	for i in range(books.size()):
		if i > 0:
			text += ", "
		text += rank_name(books[i])
	return text

func suit_name(suit):
	match suit:
		Card.Suit.HEARTS: return "Hearts"
		Card.Suit.DIAMONDS: return "Diamonds"
		Card.Suit.CLUBS: return "Clubs"
		Card.Suit.SPADES: return "Spades"

func _on_deck_card_clicked(card_display: CardDisplay):
	if current_turn == "player":
		print("PLAYER TURN: Clicked deck card to draw")
		# Only allow drawing when player needs to "go fish"
		draw_from_deck()

func draw_from_deck():
	if deck.is_empty():
		log_message("Deck is empty! Turn passes to CPU.")
		current_turn = "cpu"
		if check_game_over():
			return
		cpu_turn()
		return
	
	var drawn_card = deck.pop_back()
	player_hand.append(drawn_card)
	sort_hand(player_hand)
	
	print("PLAYER TURN: Drew ", rank_name(drawn_card.rank), " of ", suit_name(drawn_card.suit))
	log_message("You draw a card.")
	
	# Check for new books
	check_and_remove_books(player_hand, player_books)
	
	# Turn passes to CPU
	current_turn = "cpu"
	update_ui()
	if check_game_over():
		return
	
	if not game_over:
		# Delay CPU turn for better UX
		await get_tree().create_timer(1.0).timeout
		cpu_turn()

func player_ask_for_rank(rank):
	print("PLAYER TURN: Asking 'Do you have any ", rank_name(rank), "s?'")
	log_message("You ask: 'Do you have any " + rank_name(rank) + "s?'")
	
	# Check if CPU has cards of this rank
	var matching_cards = []
	for card in cpu_hand:
		if card.rank == rank:
			matching_cards.append(card)
	
	if matching_cards.size() > 0:
		print("PLAYER TURN: CPU answering 'Yes, I have ", matching_cards.size(), " ", rank_name(rank), "(s)'")
		# CPU gives cards to player
		for card in matching_cards:
			cpu_hand.erase(card)
			player_hand.append(card)
		
		sort_hand(player_hand)
		log_message("CPU gives you " + str(matching_cards.size()) + " " + rank_name(rank) + "(s)!")
		
		# Check for new books
		check_and_remove_books(player_hand, player_books)
		
		# Player continues turn
		update_ui()
		if check_game_over():
			return
	else:
		print("PLAYER TURN: CPU answering 'No, go fish'")
		# Go fish!
		log_message("CPU says: 'Go Fish!'")
		go_fish_player()

func go_fish_player():
	print("PLAYER TURN: Go fish! Click a card from the deck to draw")
	log_message("CPU says: 'Go Fish!' Click a card from the deck to draw.")
	# Player must now click a deck card to continue
	# The actual drawing happens in draw_from_deck() when they click

func cpu_turn():
	print("CPU TURN: Starting - CPU has ", cpu_hand.size(), " cards")
	if game_over or cpu_hand.is_empty():
		print("CPU TURN: Cannot continue - game over or no cards")
		if cpu_hand.is_empty():
			check_game_over()
		return
	
	# CPU picks a random rank from its hand
	var available_ranks = []
	for card in cpu_hand:
		if card.rank not in available_ranks:
			available_ranks.append(card.rank)
			
	if available_ranks.is_empty():
		print("CPU TURN: No available ranks, switching to player")
		current_turn = "player"
		update_ui()
		return
	
	var asked_rank = available_ranks[randi() % available_ranks.size()]
	print("CPU TURN: Asking 'Do you have any ", rank_name(asked_rank), "s?'")
	
	log_message("CPU asks: 'Do you have any " + rank_name(asked_rank) + "s?'")
	
	# Check if player has cards of this rank
	var matching_cards = []
	for card in player_hand:
		if card.rank == asked_rank:
			matching_cards.append(card)
	
	if matching_cards.size() > 0:
		print("CPU TURN: Player answering 'Yes, I have ", matching_cards.size(), " ", rank_name(asked_rank), "(s)'")
		# Player gives cards to CPU
		for card in matching_cards:
			player_hand.erase(card)
			cpu_hand.append(card)
		
		sort_hand(cpu_hand)
		log_message("You give CPU " + str(matching_cards.size()) + " " + rank_name(asked_rank) + "(s).")
		
		# Check for new books
		check_and_remove_books(cpu_hand, cpu_books)
		
		# CPU continues turn
		update_ui()
		if check_game_over():
			return
		
		if not game_over:
			await get_tree().create_timer(1.0).timeout
			cpu_turn()
	else:
		print("CPU TURN: Player answering 'No, go fish'")
		# CPU goes fish - draws random card
		log_message("You say: 'Go Fish!'")
		go_fish_cpu()

func go_fish_cpu():
	if deck.is_empty():
		log_message("Deck is empty! Turn passes to you.")
		current_turn = "player"
		update_ui()
		check_game_over()
		return
	
	var drawn_card = deck.pop_back()
	cpu_hand.append(drawn_card)
	sort_hand(cpu_hand)
	
	print("CPU TURN: Drew ", rank_name(drawn_card.rank), " of ", suit_name(drawn_card.suit))
	log_message("CPU draws a card from the deck.")
	
	# Check for new books
	check_and_remove_books(cpu_hand, cpu_books)
	
	# Turn passes to player
	current_turn = "player"
	update_ui()
	check_game_over()

func check_game_over():
	# Game ends when either player runs out of cards OR deck is empty
	if player_hand.is_empty() or cpu_hand.is_empty() or deck.is_empty():
		game_over = true
		print("GAME OVER: Player cards:", player_hand.size(), " CPU cards:", cpu_hand.size(), " Deck cards:", deck.size())
		
		# Determine winner
		var player_score = player_books.size()
		var cpu_score = cpu_books.size()
		
		if player_score > cpu_score:
			log_message("Game Over! You win with " + str(player_score) + " books!")
		elif cpu_score > player_score:
			log_message("Game Over! CPU wins with " + str(cpu_score) + " books!")
		else:
			log_message("Game Over! It's a tie with " + str(player_score) + " books each!")
		
		update_ui()
		return true
	return false

func log_message(message):
	game_log.text += message + "\n"
