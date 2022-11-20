extends Control

var tally : TallyChar:
	set(t):
		if t:
			$Actions.visible = true
			$Title.set("theme_override_colors/font_color", Color.BLACK)
			const Tally = preload("res://Common.gd").Tally
			$Title.text = t.tallyName
			$Desc.text = t.desc
			var texture = {
				Tally.Joe: preload("res://RedRect.png"),
				Tally.Rob: preload("res://YellowRect.png"),
				Tally.Andrew: preload("res://GreenRect.png"),
				Tally.Zubin: preload("res://BlueRect.png"),
				Tally.Ross: preload("res://LightGrayRect.png")
			}[t.tally]
			$Title/NinePatchRect.texture = texture
			
			var index = 0
			for m in $MoveList.get_children():
				m = m as LabelButton
				if index < len(t.move_list):
					var move = t.move_list[index]
					m.text = move.title
					m.clickable = true
				else:
					m.text = ""
					m.clickable = false
				index += 1	
		tally = t
func _ready():
	modulate = Color.TRANSPARENT
	$Actions/Act.clicked.connect(func():
		$MoveList.visible = !$MoveList.visible
		)
	var i = 0
	for b in $MoveList.get_children():
		var index = i
		b.mouse_entered.connect(func():
			if self.tally and index < len(self.tally.move_list):
				$Desc.text = self.tally.move_list[index].desc
			)
		b.mouse_exited.connect(func():
			if self.tally:
				$Desc.text = self.tally.desc
			)
			
		i += 1
	$MoveList.hide()
func showEnemy(enemy:Node3D):
	$Actions.visible = false
	$Title.set("theme_override_colors/font_color", Color.WHITE)
	$Title.text = enemy.title
	$Title/NinePatchRect.texture = preload("res://BlackRect.png")
	$Desc.text = enemy.desc
	set_opacity(0.7)
func select(t: TallyChar):
	tally = t
	appear()
func deselect():
	$MoveList.visible = false
	set_opacity(0.7)
func appear():
	set_opacity(1)
func disappear():
	set_opacity(0)
func set_opacity(op:float):
	var tw = get_tree().create_tween()
	tw.tween_property(self, "modulate", Color(Color.WHITE, op), 0.1)
	tw.play()
	
func hover(t: TallyChar):
	tally = t
	set_opacity(0.7)
