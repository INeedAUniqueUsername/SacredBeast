extends Node

const TallyChar = preload("res://Tally.gd")
const ActionText = preload("res://ActionText.tscn")
var selectedTally: TallyChar = null

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


const HitDesc = preload("res://HitDesc.gd")

var current_action:Node = null:
	set(n):
		if self.current_action:
			self.current_action.queue_free()
			current_action = null
		current_action = n
		if n:
			add_child(n)
			n.tree_exiting.connect(func():
				if n == self.current_action:
					current_action = null
				)
var tally_turn = true
func _ready():
	var tallyHall = get_tree().get_nodes_in_group("Tally")
	var allowSelect = func(b): tallyHall.map(func(t): t.allow_select = b)
	for i in range($UI/Tally/MoveList.get_child_count()):
		var c = $UI/Tally/MoveList.get_child(i)
		c.clicked.connect(func():
			var t := self.selectedTally as TallyChar
			if i >= len(t.move_list):
				return
			current_action = null
			
			allowSelect.call(false)
			
			var m = t.move_list[i]
			$UI/Tally/MoveList.visible = false
			if m == Moves.JoeHawley:
				await showMessage(t.tallyName + " used *" + m.title + "*")
				await t.use_move_joe_hawley()
			elif m == Moves.JustApathy:
				var action = Node.new()
				self.current_action = action
				var selection = Node.new()
				add_child(selection)
				action.tree_exiting.connect(selection.queue_free)
				var attack = Node.new()
				add_child(attack)
				for e in get_tree().get_nodes_in_group("Enemy"):
					var marker = preload("res://TileStep.tscn").instantiate()
					add_child(marker)
					marker.global_position = e.global_position
					marker.scale *= 2
					marker.clicked.connect(func():
						selection.queue_free()
						await showMessage(t.tallyName + " used *" + m.title + "*")
						await t.use_move_just_apathy(e)
						action.queue_free()
						)
					selection.tree_exiting.connect(marker.queue_free)
				await action.tree_exiting
			elif m == Moves.Greener:
				var action = Node.new()
				self.current_action = action
				var selection = Node.new()
				add_child(selection)
				action.tree_exiting.connect(selection.queue_free)
				var attack = Node.new()
				add_child(attack)
				for e in get_tree().get_nodes_in_group("Enemy"):
					var marker = preload("res://TileStep.tscn").instantiate()
					add_child(marker)
					marker.global_position = e.global_position
					marker.scale *= 2
					marker.clicked.connect(func():
						selection.queue_free()
						await showMessage(t.tallyName + " used *" + m.title + "*")
						await t.use_move_greener(e)
						action.queue_free()
						)
					selection.tree_exiting.connect(marker.queue_free)
				await action.tree_exiting
			
			elif m == Moves.AnotherMinute:
				var action = Node.new()
				self.current_action = action
				var selection = Node.new()
				add_child(selection)
				action.tree_exiting.connect(selection.queue_free)
				var attack = Node.new()
				add_child(attack)
				for e in get_tree().get_nodes_in_group("Tally"):
					var marker = preload("res://TileStep.tscn").instantiate()
					add_child(marker)
					marker.global_position = e.global_position
					marker.scale *= 2
					marker.clicked.connect(func():
						selection.queue_free()
						await showMessage(t.tallyName + " used *" + m.title + "*")
						
						await t.use_move_another_minute(e)
						await showMessage(e.tallyName + " gained walk range!")
						action.queue_free()
						)
					selection.tree_exiting.connect(marker.queue_free)
				await action.tree_exiting
				
			allowSelect.call(true)
			
			self.current_action = Node.new()
			t.show_walk(self.current_action)
			)
	for enemy in get_tree().get_nodes_in_group("Enemy"):
		var h = enemy.get_node("Hitbox")
		h.mouse_entered.connect(func():
			if !self.selectedTally:
				$UI/Tally.showEnemy(enemy)
			)
		h.mouse_exited.connect(func():
			if !self.selectedTally:
				$UI/Tally.disappear()
			)
		enemy.show_message.connect(func(s):
			showMessage(s)
		)
		
		enemy.took_damage.connect(func(h:HitDesc):
			
			showMessage(str(enemy.title) + " was hit!")
			var at = ActionText.instantiate()
			$World.add_child(at)
			at.global_position = h.pos + Vector3(0, 0.5, 1)
			
			var st = str(h.dmg)
			if h.move == Moves.JoeHawley:
				st = "JOE HAWLEY!"
			elif h.move == Moves.JustApathy:
				st = "Apathy!"
			at.get_node("Label3D").text = st
			var au = AudioStreamPlayer3D.new()
			au.stream = preload("res://Sounds/punch_hit.wav")
			
			$World.add_child(au)
			au.global_position = h.pos
			au.play()
			au.finished.connect(au.queue_free)
			
			#$World/Camera.shake()
			)
	
	for tally in tallyHall:
		
		var area = tally.get_node("Area")
		area.mouse_entered.connect(func():
			if !self.selectedTally:
				$UI/Tally.hover(tally)
			)
		area.mouse_exited.connect(func():
			if !self.selectedTally:
				$UI/Tally.disappear()
			)
		
		tally.selected.connect(func():
			if self.selectedTally:
				self.selectedTally.deselect()
			$UI/Tally.select(tally)
			self.selectedTally = tally
			
			self.current_action = Node.new()
			tally.show_walk(self.current_action)
		)
		tally.deselected.connect(func():
			if tally == self.selectedTally:
				$UI/Tally.deselect()
				self.selectedTally = null
			)
	
	await $Intro/Anim.animation_finished
	
	get_tree().create_timer(4.5).timeout.connect(func():
		$World/Smoke.emitting = true
		)
	
	
	tallyHall.map(func(t): t.walk_remaining = 8)
	while active:
		
		$Turn/Anim.play("PlayerTurn")
		allowSelect.call(true)
		
		await $UI/EndTurn.clicked
		if self.selectedTally:
			self.selectedTally.deselect()
			
		tallyHall.map(func(t): t.walk_remaining = 8)
		allowSelect.call(false)
		
		$Turn/Anim.play("EnemyTurn")
		await $Turn/Anim.animation_finished
		
		for e in get_tree().get_nodes_in_group("Enemy"):
			
			var p = preload("res://Pointer.tscn").instantiate()
			#p.global_position = e.global_position
			e.add_child(p)
			
			var t = get_tree().create_tween()
			t.set_trans(Tween.TRANS_QUAD)
			t.set_ease(Tween.EASE_OUT)
			t.tween_property($World/Camera, "global_position", e.global_position + Vector3(-1, 4, 6), 0.5)

			t.play()
			await t.finished
			
			$World/Camera.follow = e
			await e.begin_turn()
			$World/Camera.follow = null
			
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
