extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	$Act.clicked.connect(func():
		$MoveList.visible = !$MoveList.visible
		)
func select(char: Node3D):
	const Tally = preload("res://Common.gd").Tally
	var texture = {
		Tally.Joe: preload("res://RedRect.png"),
		Tally.Rob: preload("res://YellowRect.png"),
		Tally.Andrew: preload("res://GreenRect.png"),
		Tally.Zubin: preload("res://BlueRect.png"),
		Tally.Ross: preload("res://LightGrayRect.png")
	}[char.tally]
	$Name/NinePatchRect.texture = texture
	$Anim.play("Appear")
func deselect():
	$Anim.play("Disappear")
