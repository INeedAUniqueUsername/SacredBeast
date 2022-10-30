extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
	var tallyHall = get_tree().get_nodes_in_group("Tally")
	for tally in tallyHall:
		tally.selected.connect(func():
			for other in tallyHall:
				if other == tally:
					continue
				other.deselect()
			$UI/Tally.select(tally)
		)
		tally.deselected.connect($UI/Tally.deselect)
		
