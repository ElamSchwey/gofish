extends Control

# Card suits and ranks
enum Suit { HEARTS, DIAMONDS, CLUBS, SPADES }
enum Rank { TWO = 2, THREE, FOUR, FIVE, SIX, SEVEN, EIGHT, NINE, TEN, JACK, QUEEN, KING, ACE }

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
@onready var game_log = $VBoxContainer/GameLog/GameLogText
@onready var player_books_label = $VBoxContainer/PlayerArea/PlayerBooksLabel
@onready var cpu_books_label = $VBoxContainer/CPUArea/CPUBooksLabel
@onready var ask_button = $VBoxContainer/PlayerArea/AskButton
@onready var rank_option = $VBoxContainer/PlayerArea/RankOption

func _ready():
	setup_ui()
	start_new_game()

func setup_ui():
	# Setup rank selection dropdown
	for rank in Rank.values():
		rank_option.add_item(rank_name(rank))
	
	ask_button.pressed.connect(_on_ask_button_pressed)

func start_new_game():
	# Initialize deck
	deck.clear()
	for suit in Suit.values():
		for rank in Rank.values():
			deck.append({"suit": suit, "rank": rank})
	
	# Shuffle deck
	deck.shuffle()
	
	# Deal initial hands (7 cards each)
	player_hand.clear()
	cpu_hand.clear()
	for i in range(7):
		player_hand.append(deck.pop_back())
		cpu_hand.append(deck.pop_back())
	
	# Sort hands
	sort_hand(player_hand)
	sort_hand(cpu_hand)
	
	# Check for initial books
	check_and_remove_books(player_hand, player_books)
	check_and_remove_books(cpu_hand, cpu_books)
	
	# Reset game state
	current_turn = "player"
	game_over = false
	
	update_ui()
	log_message("Game started! You have " + str(player_hand.size()) + " cards.")

func sort_hand(hand):
	hand.sort_custom(func(a, b): return a.rank < b.rank)

func check_and_remove_books(hand, books):
	var rank_counts = {}
	
	# Count cards of each rank
	for card in hand:
		if card.rank in rank_counts:
			rank_counts[card.rank] += 1
		else:
			rank_counts[card.rank] = 1
	
	# Remove books (sets of 2) and update the actual hand array
	for rank in rank_counts:
		if rank_counts[rank] == 2:
			books.append(rank)
			log_message("Book completed: " + rank_name(rank) + "s!")
			# Remove all cards of this rank from hand
			for i in range(hand.size() - 1, -1, -1):  # Iterate backwards to avoid index issues
				if hand[i].rank == rank:
					hand.remove_at(i)

func update_ui():
	# Update player hand display
	for child in player_hand_container.get_children():
		child.queue_free()
	
	for card in player_hand:
		var button = Button.new()
		button.text = card_short_name(card)
		player_hand_container.add_child(button)
	
	# Update CPU hand display (face down)
	for child in cpu_hand_container.get_children():
		child.queue_free()
	
	for i in range(cpu_hand.size()):
		var label = Label.new()
		label.text = "🂠"  # Card back symbol
		cpu_hand_container.add_child(label)
	
	# Update books display
	player_books_label.text = "Your Books (" + str(player_books.size()) + "): " + books_text(player_books)
	cpu_books_label.text = "CPU Books (" + str(cpu_books.size()) + "): " + books_text(cpu_books)
	
	# Update available ranks for asking
	rank_option.clear()
	var available_ranks = get_available_ranks(player_hand)
	for rank in available_ranks:
		rank_option.add_item(rank_name(rank))
	
	# Enable/disable ask button
	ask_button.disabled = (current_turn != "player" or available_ranks.is_empty() or game_over)

func get_available_ranks(hand):
	var ranks = []
	for card in hand:
		if card.rank not in ranks:
			ranks.append(card.rank)
	return ranks

func card_short_name(card):
	return rank_short_name(card.rank) + "-" + suit_short_name(card.suit)

func rank_short_name(rank):
	match rank:
		Rank.JACK: return "J"
		Rank.QUEEN: return "Q"
		Rank.KING: return "K"
		Rank.ACE: return "A"
		_: return str(rank)

func suit_short_name(suit):
	match suit:
		Suit.HEARTS: return "H"
		Suit.DIAMONDS: return "D"
		Suit.CLUBS: return "C"
		Suit.SPADES: return "S"

func rank_name(rank):
	match rank:
		Rank.JACK: return "Jack"
		Rank.QUEEN: return "Queen"
		Rank.KING: return "King"
		Rank.ACE: return "Ace"
		_: return str(rank)

func suit_name(suit):
	match suit:
		Suit.HEARTS: return "Hearts"
		Suit.DIAMONDS: return "Diamonds"
		Suit.CLUBS: return "Clubs"
		Suit.SPADES: return "Spades"

func books_text(books):
	if books.is_empty():
		return "None"
	var text = ""
	for i in range(books.size()):
		if i > 0:
			text += ", "
		text += rank_name(books[i])
	return text

func _on_ask_button_pressed():
	if current_turn != "player" or game_over:
		return
	
	var selected_rank_index = rank_option.selected
	if selected_rank_index < 0:
		return
	
	var available_ranks = get_available_ranks(player_hand)
	if selected_rank_index >= available_ranks.size():
		return
		
	var asked_rank = available_ranks[selected_rank_index]
	
	player_ask_for_rank(asked_rank)

func player_ask_for_rank(rank):
	log_message("You ask: 'Do you have any " + rank_name(rank) + "s?'")
	
	# Check if CPU has cards of this rank
	var matching_cards = []
	for card in cpu_hand:
		if card.rank == rank:
			matching_cards.append(card)
	
	if matching_cards.size() > 0:
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
		check_game_over()
	else:
		# Go fish!
		log_message("CPU says: 'Go Fish!'")
		go_fish_player()

func go_fish_player():
	if deck.is_empty():
		log_message("Deck is empty! Turn passes to CPU.")
		current_turn = "cpu"
		cpu_turn()
		return
	
	var drawn_card = deck.pop_back()
	player_hand.append(drawn_card)
	sort_hand(player_hand)
	
	log_message("You draw a card: " + card_short_name(drawn_card))
	
	# Check for new books
	check_and_remove_books(player_hand, player_books)
	
	# Turn passes to CPU
	current_turn = "cpu"
	update_ui()
	check_game_over()
	
	if not game_over:
		# Delay CPU turn for better UX
		await get_tree().create_timer(1.0).timeout
		cpu_turn()

func cpu_turn():
	if game_over or cpu_hand.is_empty():
		return
	
	# CPU picks a random rank from its hand
	var available_ranks = get_available_ranks(cpu_hand)
	if available_ranks.is_empty():
		current_turn = "player"
		update_ui()
		return
	
	var asked_rank = available_ranks[randi() % available_ranks.size()]
	
	log_message("CPU asks: 'Do you have any " + rank_name(asked_rank) + "s?'")
	
	# Check if player has cards of this rank
	var matching_cards = []
	for card in player_hand:
		if card.rank == asked_rank:
			matching_cards.append(card)
	
	if matching_cards.size() > 0:
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
		check_game_over()
		
		if not game_over:
			await get_tree().create_timer(1.0).timeout
			cpu_turn()
	else:
		# CPU goes fish - draws random card
		log_message("You say: 'Go Fish!'")
		go_fish_cpu()

func go_fish_cpu():
	if deck.is_empty():
		log_message("Deck is empty! Turn passes to you.")
		current_turn = "player"
		update_ui()
		return
	
	var drawn_card = deck.pop_back()
	cpu_hand.append(drawn_card)
	sort_hand(cpu_hand)
	
	log_message("CPU draws a card from the deck.")
	
	# Check for new books
	check_and_remove_books(cpu_hand, cpu_books)
	
	# Turn passes to player
	current_turn = "player"
	update_ui()
	check_game_over()

func check_game_over():
	if player_hand.is_empty() or cpu_hand.is_empty() or deck.is_empty():
		game_over = true
		
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

func log_message(message):
	game_log.text += message + "\n"
