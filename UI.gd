extends Control
func _ready():
	modulate = Color.TRANSPARENT
	$Actions/Act.clicked.connect(func():
		$MoveList.visible = !$MoveList.visible
		)
	$MoveList.hide()
	
	
func showEnemy(enemy:Node3D):
	$Actions.visible = false
	$Title.set("theme_override_colors/font_color", Color.WHITE)
	$Title.text = enemy.title
	$Title/NinePatchRect.texture = preload("res://BlackRect.png")
	$Desc.text = enemy.desc
	set_opacity(0.7)
func select(char: TallyChar):
	$Actions.visible = true
	set_style(char)
	appear()
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
	$MoveList.visible = false
	set_opacity(0.7)
	
func set_style(char: TallyChar):
	$Title.set("theme_override_colors/font_color", Color.BLACK)
	const Tally = preload("res://Common.gd").Tally
	$Title.text = char.tallyName
	$Desc.text = char.desc
	var texture = {
		Tally.Joe: preload("res://RedRect.png"),
		Tally.Rob: preload("res://YellowRect.png"),
		Tally.Andrew: preload("res://GreenRect.png"),
		Tally.Zubin: preload("res://BlueRect.png"),
		Tally.Ross: preload("res://LightGrayRect.png")
	}[char.tally]
	$Title/NinePatchRect.texture = texture
func appear():
	set_opacity(1)
func disappear():
	set_opacity(0)
func set_opacity(op:float):
	var tw = get_tree().create_tween()
	tw.tween_property(self, "modulate", Color(Color.WHITE, op), 0.1)
	tw.play()
	
func hover(char: TallyChar):
	set_style(char)
	set_opacity(0.7)
