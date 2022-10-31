extends Node


var selectedTally = null
# Called when the node enters the scene tree for the first time.
func _ready():
	var tallyHall = get_tree().get_nodes_in_group("Tally")
	for tally in tallyHall:
		
		var area = tally.get_node("Area")
		area.mouse_entered.connect(func():
			if !selectedTally:
				$UI/Tally.hover(tally)
			)
		area.mouse_exited.connect(func():
			if !selectedTally:
				$UI/Tally.disappear()
			)
		
		tally.selected.connect(func():
			self.selectedTally = tally
			for other in tallyHall:
				if other == tally:
					continue
				other.deselect()
			$UI/Tally.select(tally)
		)
		tally.deselected.connect(func():
			selectedTally = null
			$UI/Tally.deselect()
			)
		
	var prev_position = Vector2(0, 0)
	var prev_pressed = false
	if false:
		$Back.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouse:
				var mb = ev as InputEventMouse
				
				if mb.is_pressed():
					prev_pressed = true
				var pos = mb.position
				if prev_pressed:
					var delta = pos - prev_position
					$World/Camera3D.global_position += Vector3(delta.x, 0, delta.y) / 1080.0
				prev_position = pos
			)
