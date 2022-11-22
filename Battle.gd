extends Node

const TallyChar = preload("res://Tally.gd")
const ActionText = preload("res://ActionText.tscn")
var selectedTally: TallyChar = null:
	set(t):
		if selectedTally:
			selectedTally.deselect()
			$UI/Tally.deselect()
		selectedTally = t
		if t:
			t.select()
			$UI/Tally.select(t)
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
var rulerOfEverything = false
var turnTheLightsOff = 0:
	set(n):
		var env = $WorldEnvironment.environment
		if n == 2 and turnTheLightsOff == 0:
			var tw = get_tree().create_tween()
			tw.tween_property(env, "background_energy_multiplier", 0.35, 1)
			tw.play()
		elif n == 1:
			var tw = get_tree().create_tween()
			tw.tween_property(env, "background_energy_multiplier", 0, 1)
			tw.play()
		elif n == 0:
			var tw = get_tree().create_tween()
			tw.tween_property(env, "background_energy_multiplier", 1, 1)
			tw.play()
		turnTheLightsOff = n

var busy = false

func get_active_enemies():
	return get_tree().get_nodes_in_group("Enemy").filter(func(e): return e.alive)
func request_target(targets: Array, f: Callable, subtask:bool = false):
	var action = Node.new()
	if subtask:
		current_action.add_child(action)
	else:
		current_action = action
	var selection = Node.new()
	add_child(selection)
	action.tree_exiting.connect(selection.queue_free)
	var attack = Node.new()
	add_child(attack)
	for e in targets:
		var marker = preload("res://TileStep.tscn").instantiate()
		add_child(marker)
		if e is Vector3:
			marker.global_position = e
		else:
			marker.global_position = e.global_position
			marker.scale *= 2
		marker.clicked.connect(func():
			selection.queue_free()
			await f.call(e)
			if is_instance_valid(action):
				action.queue_free()
			)
		selection.tree_exiting.connect(marker.queue_free)
	await action.tree_exiting
func _ready():
	var tallyHall = get_tree().get_nodes_in_group("Tally")
	for i in range($UI/Tally/MoveList.get_child_count()):
		var c = $UI/Tally/MoveList.get_child(i)
		c.clicked.connect(func():
			var t := self.selectedTally as TallyChar
			if i >= len(t.move_list):
				return
			if t.is_busy:
				return
			var m = t.move_list[i]
			var begin_move = func():
				self.selectedTally.moves_remaining -= 1
				$UI/Tally.tally = self.selectedTally
				c.mouse_exited.emit()
				self.current_action = null
				t.is_busy = true
			var announceMove = func():
				await showMessage(t.tallyName + " used *" + m.title + "*")
			if m == Moves.JoeHawley:
				begin_move.call()
				await announceMove.call()
				await t.use_move_joe_hawley()
			elif m == Moves.RotaryPark:
				begin_move.call()
				await announceMove.call()
				await t.use_move_rotary_park()
			elif m == Moves.AllOfMyFriends:
				if t.allOfMyFriends > 0:
					return
				begin_move.call()
				await announceMove.call()
				await t.use_move_all_of_my_friends()
			elif m == Moves.JustApathy:
				begin_move.call()
				var act = func(e):
					await announceMove.call()
					await t.use_move_just_apathy(e)
				await request_target(t.get_line_of_sight_enemies(), act)
			elif m == Moves.Greener:
				begin_move.call()
				var act = func(e):
					await announceMove.call()
					await t.use_move_greener(e)
				await request_target(t.get_line_of_sight_enemies(), act)
			elif m == Moves.AnotherMinute:
				begin_move.call()
				var act = func(e):
					await announceMove.call()
					await t.use_move_another_minute(e)
					await showMessage(e.tallyName + " gained walk range!")
				await request_target(get_tree().get_nodes_in_group("Tally"), act)
			elif m == Moves.TheWholeWorldAndYou:
				begin_move.call()
				var act = func(e):
					await announceMove.call()
					await t.use_move_the_whole_world_and_you(e)
					await showMessage(e.title + " is timestopped!")
				await request_target(get_active_enemies(), act)
			elif m == Moves.TakenForARide:
				begin_move.call()
				var act = func(e):
					var act2 = func(pos):
						await announceMove.call()
						await t.use_move_taken_for_a_ride(e, pos)
						
					var positions = e.get_all_standable_positions()
					await request_target(positions, act2, true)
				await request_target(get_active_enemies(), act)
			elif m == Moves.GoodDay:
				begin_move.call()
				await announceMove.call()
				await t.use_move_good_day()
				await showMessage("The Tallies restored 20 HP!")
			elif m == Moves.ColorBeGone:
				begin_move.call()
				await announceMove.call()
				await t.use_move_color_be_gone()
			elif m == Moves.TheTrap:
				begin_move.call()
				var act = func(e):
					await announceMove.call()
					await t.use_move_the_trap(e)
				await request_target(get_active_enemies(), act)
			elif m == Moves.TurnTheLightsOff:
				if turnTheLightsOff > 1:
					return
				begin_move.call()
				await announceMove.call()
				await t.use_move_turn_the_lights_off()

				if turnTheLightsOff == 0:
					showMessage("The lights begin to dim. The lights will be off at the end of this turn.")
				else:
					showMessage("The lights will stay off for the next two turns.")
				await get_tree().create_timer(1).timeout
				
				turnTheLightsOff = 2

			elif m == Moves.RulerOfEverything:
				if rulerOfEverything:
					return
				begin_move.call()
				await announceMove.call()
				await t.use_move_ruler_of_everything()
				rulerOfEverything = true
				await showMessage("Next turn will be a Tally turn!")
			t.is_busy = false
			
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
		enemy.show_message.connect(func(s): showMessage(s))
		
		enemy.took_damage.connect(func(h:HitDesc):
			
			if h.announce:
				showMessage(str(enemy.title) + " was hit for " + str(h.dmg) + " damage!")
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
		
		tally.clicked.connect(func():
			if (self.selectedTally and self.selectedTally.is_busy) or busy:
				return
			if tally == self.selectedTally:
				self.selectedTally = null
				return
			
			self.selectedTally = tally
			self.current_action = Node.new()
			tally.show_walk(self.current_action)
		)
		tally.show_message.connect(func(s): showMessage(s))
	
	await $Intro/Anim.animation_finished
	
	get_tree().create_timer(4.5).timeout.connect(func():
		$World/Smoke.emitting = true
		)
	while active:
		var tally_turn = func(second = false):
			busy = false
			for t in tallyHall:
				await t.begin_turn(self.rulerOfEverything, self.turnTheLightsOff > 0)
			$Turn/Msg.text = {
				true:"Tally Turn Part II",
				false: "Tally Turn"
			}[second]
			$Turn/Anim.play("Show")
			await $UI/EndTurn.clicked
			self.selectedTally = null
			
			
			for t in tallyHall:
				await t.end_turn(self.turnTheLightsOff > 0)
		var enemy_turn = func(second = false):
			busy = true
			$Turn/Msg.text = {
				true:"Enemy Turn Part II",
				false: {true: "Enemy Turn Part I", false: "Enemy Turn"}[self.rulerOfEverything]
			}[second]
			$Turn/Anim.play("Show")
			await $Turn/Anim.animation_finished
			
			var activeEnemies = get_active_enemies()
			activeEnemies.sort_custom(func(a, b): return a.turn_priority < b.turn_priority)
			for e in activeEnemies:
				if !is_instance_valid(e):
					continue
				var p = preload("res://Pointer.tscn").instantiate()
				#p.global_position = e.global_position
				e.add_child(p)
				var t = get_tree().create_tween()
				t.set_trans(Tween.TRANS_QUAD)
				t.set_ease(Tween.EASE_OUT)
				t.tween_property($World/Camera, "global_position", e.global_position + Vector3(0, 4, 6), 0.5)
				t.play()
				await t.finished
				
				$World/Camera.follow = e
				await e.begin_turn(self.turnTheLightsOff > 0)
				$World/Camera.follow = null
				
				p.dismiss()
			for e in get_active_enemies():
				e.timestop -= 1
		
		# Tally turns
		await tally_turn.call()
		if rulerOfEverything:
			await tally_turn.call(true)
		
		if turnTheLightsOff == 2:
			turnTheLightsOff = 1
			await showMessage("The lights are off! All damage is doubled!")
			await get_tree().create_timer(0.5).timeout
		elif turnTheLightsOff == 1:
			turnTheLightsOff = 0
			await showMessage("*Turn the Lights Off* has ended. The lights are on. Damage is no longer doubled.")
			await get_tree().create_timer(0.5).timeout
		# Enemy turns
		busy = true
		await enemy_turn.call()
		if rulerOfEverything:
			await enemy_turn.call(true)
		
		if turnTheLightsOff == 2:
			turnTheLightsOff = 1
		
		if rulerOfEverything:
			rulerOfEverything = false
			await showMessage("*Ruler of Everything* has ended")
			await get_tree().create_timer(0.5).timeout
		
			
			await get_tree().create_timer(0.5).timeout
		busy = false
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
