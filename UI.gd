extends Control
func _ready():
	modulate = Color.TRANSPARENT
	$Act.clicked.connect(func():
		$MoveList.visible = !$MoveList.visible
		)
	$MoveList.hide()
func set_style(char: TallyChar):
	
	const Tally = preload("res://Common.gd").Tally
	
	$Name.text = char.tallyName
	var texture = {
		Tally.Joe: preload("res://RedRect.png"),
		Tally.Rob: preload("res://YellowRect.png"),
		Tally.Andrew: preload("res://GreenRect.png"),
		Tally.Zubin: preload("res://BlueRect.png"),
		Tally.Ross: preload("res://LightGrayRect.png")
	}[char.tally]
	$Name/NinePatchRect.texture = texture
func appear():
	var tw = get_tree().create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_QUAD)
	tw.tween_property(self, "modulate", Color.WHITE, 0.1)
	tw.play()
func disappear():
	var tw = get_tree().create_tween()
	tw.tween_property(self, "modulate", Color.TRANSPARENT, 0.1)
	tw.play()
	
	self.modulate = Color.TRANSPARENT
func hover(char: TallyChar):
	set_style(char)
	
	
	var tw = get_tree().create_tween()
	tw.tween_property(self, "modulate", Color(Color.WHITE, 0.5), 0.1)
	tw.play()
	
	$Act.visible = false
func select(char: TallyChar):
	set_style(char)
	appear()
	$Act.visible = true
	for index in range(4):
		var m = $MoveList.get_child(index) as LabelButton
		if index < len(char.move_list):
			var move = char.move_list[index]
			m.text = move.title
			m.clickable = true
		else:
			m.text = ""
			m.clickable = false
			
func deselect():
	$Act.visible = false
	$MoveList.visible = false

	
	var tw = get_tree().create_tween()
	tw.tween_property(self, "modulate", Color(Color.WHITE, 0.5), 0.1)
	tw.play()
