class_name Card
extends Resource

enum Suit { CLUBS, DIAMONDS, HEARTS, SPADES }
enum Rank { ACE = 1, TWO = 2, THREE = 3, FOUR = 4, FIVE = 5, SIX = 6, SEVEN = 7, EIGHT = 8, NINE = 9, TEN = 10, JACK = 11, QUEEN = 12, KING = 13 }

@export var rank: Rank
@export var suit: Suit

func _init(r: Rank = Rank.ACE, s: Suit = Suit.CLUBS):
	rank = r
	suit = s

func get_filename() -> String:
	var rank_str = "%02d" % rank
	var suit_str = ""
	match suit:
		Suit.CLUBS: suit_str = "C"
		Suit.DIAMONDS: suit_str = "D" 
		Suit.HEARTS: suit_str = "H"
		Suit.SPADES: suit_str = "S"
	
	return rank_str + suit_str + ".png"
