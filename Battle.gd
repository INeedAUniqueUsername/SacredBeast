extends Node


const ActionText = preload("res://ActionText.tscn")
var selectedTally = null

signal message_changed
var messageVisible = false
func showMessage(t:String):
	message_changed.emit()
	$UI/Message.visible_ratio = 0
	$UI/Message.text = t
	if !messageVisible:
		$UI/Message/Anim.play("Appear")
		await $UI/Message/Anim.animation_finished
		messageVisible = true
	var tw = get_tree().create_tween()
	tw.tween_property($UI/Message, "visible_ratio", 1, len(t)/32.0)
	tw.play()
	await tw.finished
	hideMessage()

func hideMessage():
	var timer = Timer.new()
	timer.wait_time = 2
	add_child(timer)
	timer.start()
	timer.timeout.connect($UI/Message/Anim.play.bind("Disappear"))
	timer.timeout.connect(func(): messageVisible = false)
	timer.timeout.connect(timer.queue_free)
	message_changed.connect(timer.queue_free)

# Called when the node enters the scene tree for the first time.
func _ready():
	for i in range($UI/Tally/MoveList.get_child_count()):
		var c = $UI/Tally/MoveList.get_child(i)
		c.clicked.connect(func():
			var m = selectedTally.move_list[i]
			
			$UI/Tally/MoveList.visible = false
			await showMessage(selectedTally.tallyName + " used *" + m.title + "*")
			
			await selectedTally.use_move(m)
			)
	for enemy in get_tree().get_nodes_in_group("Enemy"):
		enemy.died.connect(func():
			showMessage(str(enemy.name) + " fell!")
		)
		
		enemy.took_damage.connect(func(h):
			showMessage(str(enemy.name) + " took the hit!")	
			var at = ActionText.instantiate()
			at.global_position = h.pos + Vector3(0, 0.5, 1)
			$World.add_child(at)
			
			var au = AudioStreamPlayer3D.new()
			au.stream = preload("res://Sounds/punch_hit.wav")
			au.global_position = h.pos
			$World.add_child(au)
			au.play()
			au.finished.connect(au.queue_free)
			
			#$World/Camera.shake()
			)
	
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
	
	await $Intro/Anim.animation_finished
	while active:
		
		$Turn/Anim.play("PlayerTurn")
		
		await $UI/EndTurn.clicked
		
		$Turn/Anim.play("EnemyTurn")
		await $Turn/Anim.animation_finished
		
		for e in get_tree().get_nodes_in_group("Enemy"):
			
			var p = preload("res://Pointer.tscn").instantiate()
			p.global_position = e.global_position
			add_child(p)
			
			var t = get_tree().create_tween()
			t.set_trans(Tween.TRANS_QUAD)
			t.set_ease(Tween.EASE_OUT)
			t.tween_property($World/Camera, "global_position", e.global_position + Vector3(-1, 4, 6), 0.5)

			t.play()
			await t.finished
			await e.begin_turn()
			
			p.dismiss()
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
signal player_turn_ended
var active = true
