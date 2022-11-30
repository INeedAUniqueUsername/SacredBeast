extends Node
class_name Battle
const TallyChar = preload("res://Tally.gd")
const ActionText = preload("res://ActionText.tscn")
var selectedTally: TallyChar = null:
	set(t):
		if selectedTally and is_instance_valid(selectedTally):
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
	tw.tween_property($UI/Message, "visible_ratio", 1, len(t)/80.0)
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

var springAndAStorm:bool = false:
	set(b):
		$Rain.emitting = b
		springAndAStorm = b
var rulerOfEverything:bool = false:
	set(b):
		if !rulerOfEverything and b:
			var tw = get_tree().create_tween()
			tw.tween_property($Camera/Anim, "playback_speed", 0.5, 1)
			tw.play()
		elif rulerOfEverything and !b:
			var tw = get_tree().create_tween()
			tw.tween_property($Camera/Anim, "playback_speed", 1, 1)
			tw.play()
			
		rulerOfEverything = b
func set_background_brightness(f:float):
	
	var env = $WorldEnvironment.environment
	var tw = get_tree().create_tween()
	tw.tween_property(env, "background_energy_multiplier", f, 1)
	tw.play()

signal turn_the_lights_off_ended()
var turnTheLightsOff = 0:
	set(n):
		if n == 2 and turnTheLightsOff == 0:
			await set_background_brightness(0.35)
		elif n == 1:
			await set_background_brightness(0)
		elif n == 0:
			await set_background_brightness(1)
		turnTheLightsOff = n

var flameBorder:bool:
	set(b):
		for n in get_tree().get_nodes_in_group("FlameBorder"):
			n.emitting = b
		flameBorder = b

var busy : bool:
	set(b):
		$UI/EndTurn.clickable = not b
		busy = b
func get_active_tallies() -> Array[TallyChar]:
	return get_tree().get_nodes_in_group("Tally").map(func(t):
		return t as TallyChar
	).filter(func(t):
		return t.hp > 0
	)
func get_active_enemies() -> Array[Enemy]:
	return get_tree().get_nodes_in_group("Enemy").filter(func(e):
		return e.alive
	).map(func(e):
		return e as Enemy
	)
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
func focus(e:Enemy):
	if e:
		var flag = Node.new()
		add_child(flag)
		var offset = Vector3(0, 4, 6)
		$Camera.follow = e
		flag.tree_exited.connect(func():
			if $Camera.follow == e:
				$Camera.follow = null
		)
		
		$UI/Tally.showEnemy(e)
		var p = preload("res://Pointer.tscn").instantiate()
		flag.tree_exited.connect(p.dismiss)
		#p.global_position = e.global_position
		e.add_child(p)
		var t = get_tree().create_tween()
		t.set_trans(Tween.TRANS_QUAD)
		t.set_ease(Tween.EASE_OUT)
		
		t.tween_property($Camera, "offset", offset, 0.5)
		t.play()
		return flag
func register(enemy:Enemy):
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
	
	enemy.fell.connect(func():
		
		if get_tree() and get_active_enemies().is_empty():
			await get_tree().process_frame
			end_game()
		)
var extra_turns : Array[Enemy] = []

func wait(time:float):
	await get_tree().create_timer(time).timeout
func _ready():
	flameBorder = false
	busy = true
	Moves.print_all()
	for i in range($UI/Tally/MoveList.get_child_count()):
		var c = $UI/Tally/MoveList.get_child(i)
		c.clicked.connect(func():
			var t := self.selectedTally as TallyChar
			
			
			if !t or t.is_busy:
				return
			if i >= len(t.move_list):
				return
			var m = t.move_list[i]
			var begin_move = func():
				self.selectedTally.moves_remaining -= 1
				$UI/Tally.refresh()
				$UI/Tally/Actions/Act.clickable = false
				c.mouse_exited.emit()
				self.current_action = null
				t.is_busy = true
				self.busy = true
			var announceMove = func():
				await showMessage(t.tallyName + " used *" + m.title + "*")
			# Joe
			if m == Moves.JoeHawley:
				begin_move.call()
				await announceMove.call()
				await t.use_move_joe_hawley()
			elif m == Moves.AristotlesDenial:
				begin_move.call()
				await announceMove.call()
				await t.use_move_aristotles_denial()
			elif m == Moves.AllOfMyFriends:
				if t.allOfMyFriends > 0:
					return
				begin_move.call()
				await announceMove.call()
				await t.use_move_all_of_my_friends()
			elif m == Moves.SpringAndAStorm:
				begin_move.call()
				await announceMove.call()
				await t.use_move_spring_and_a_storm()
				springAndAStorm = true
				await showMessage("It is raining! Until the next Tally Turn, damage dealt to enemies will heal Tallies")
			# Rob
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
				await request_target(get_active_tallies(), act)
			elif m == Moves.GardenOfEden:
				begin_move.call()
				var act = func(e):
					await announceMove.call()
					await t.use_move_garden_of_eden(e)
					await showMessage(e.tallyName + " restored all HP!")
				await request_target(get_active_tallies(), act)
			# Andrew
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
			elif m == Moves.Misfortune:
				begin_move.call()
				if t.misfortune == 0:
					var act = func(e):
						await announceMove.call()
						await t.use_move_misfortune_1(e)
						await showMessage(e.title + " is cursed with Misfortune!")
					await request_target(get_active_enemies(), act)
				elif t.misfortune == 1:
					await announceMove.call()
					await t.use_move_misfortune_2()
					await showMessage(t.misfortuneTarget.title + " is cursed with even more Misfortune!")
			elif m == Moves.GoodDay:
				begin_move.call()
				await announceMove.call()
				await t.use_move_good_day()
				await showMessage("The Tallies restored 20 HP!")
			# Zubin
			elif m == Moves.ColorBeGone:
				begin_move.call()
				await announceMove.call()
				await t.use_move_color_be_gone()
			elif m == Moves.RotaryPark:
				begin_move.call()
				await announceMove.call()
				await t.use_move_rotary_park()
			elif m == Moves.WhiteBall:
				#begin_move.call()
				#var positions = get_all_empty_positions()
				#var act2 = func(pos: Vector3):
				#	await announceMove.call()
				#	await t.use_move_white_ball(pos)
				#await request_target(positions, act2, true)
				pass
			elif m == Moves.SeaCucumber:
				begin_move.call()
				var act = func(e):
					await announceMove.call()
					await t.use_move_sea_cucumber(e)
				await request_target(get_active_tallies(), act)
			# Ross
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
				turnTheLightsOff = 2
				await get_tree().create_timer(1).timeout
			elif m == Moves.RulerOfEverything:
				begin_move.call()
				await announceMove.call()
				await t.use_move_ruler_of_everything()
				rulerOfEverything = true
				await showMessage("This turn will have a Part II!")
			elif m == Moves.HotRodDuncan:
				begin_move.call()
				var act = func(e):
					await announceMove.call()
					await t.use_move_the_apologue_of_hot_rod_duncan(e)
					await showMessage(e.tallyName + " gained two more actions for this turn!")
				await request_target(get_active_tallies(), act)
				
			self.busy = false
			t.is_busy = false
			$UI/Tally.refresh()
			
			self.current_action = Node.new()
			t.show_walk(self.current_action)
			)
	for enemy in get_active_enemies():
		register(enemy)
	for tally in get_active_tallies():
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
			if (self.selectedTally and is_instance_valid(self.selectedTally) and self.selectedTally.is_busy) or busy:
				return
			if tally == self.selectedTally:
				self.selectedTally = null
				return
			
			self.selectedTally = tally
			self.current_action = Node.new()
			tally.show_walk(self.current_action)
		)
		tally.show_message.connect(func(s): showMessage(s))
		
		tally.fell.connect(func():
			if tally == self.selectedTally:
				self.selectedTally = null
			if get_tree() and get_active_tallies().is_empty():
				end_game()
			)
	
	
	$Turn/Msg.text = "Battle Start!"
	$Turn/Anim.play("Show")
	await $Turn/Anim.animation_finished
	
	(func():
		await $Turn/Anim.animation_finished
		showMessage("Objective: Defeat all enemies to win the battle!")
		).call()
	
	get_tree().create_timer(4.5).timeout.connect(func():
		$Smoke.emitting = true
		)
		
	var tally_turn = func(second = false):
		if !active:
			return
		for t in get_active_tallies():
			await t.begin_turn(self.rulerOfEverything, self.turnTheLightsOff > 0)
		if !self.rulerOfEverything and springAndAStorm:
			springAndAStorm = false
			await showMessage("*Spring and a Storm* has ended")
			await get_tree().create_timer(0.5).timeout
		$Turn/Msg.text = {
			true:"Tally Turn Part II",
			false: "Tally Turn"
		}[second]
		$Turn/Anim.play("Show")
		#await $Turn/Anim.animation_finished
		
		
		self.busy = false
		$UI/Tally.refresh()
		
		await $UI/EndTurn.clicked
		
		self.busy = true
		self.selectedTally = null
		for t in get_active_tallies():
			await t.end_turn(self.turnTheLightsOff > 1)
	var enemy_turn = func(second = false):
		$Turn/Msg.text = {
			true:"Enemy Turn Part II",
			false: {true: "Enemy Turn Part I", false: "Enemy Turn"}[self.rulerOfEverything]
		}[second]
		$Turn/Anim.stop()
		$Turn/Anim.play("Show")
		await $Turn/Anim.animation_finished
		
		var activeEnemies = get_active_enemies()
		activeEnemies.sort_custom(func(a, b): return a.turn_priority < b.turn_priority)
		
		var movers = activeEnemies
		while len(movers) > 0:
			for e in movers:
				if !is_instance_valid(e):
					continue
				if not active:
					return
				
				var f = focus(e)
				await e.begin_turn(self.turnTheLightsOff > 0)
				f.queue_free()
			for e in get_active_enemies():
				e.timestop -= 1
			
			movers = extra_turns
			extra_turns = []
	for e in get_active_enemies():
		await e.begin_battle()
		
	
	while active:
		# Tally turns
		self.selectedTally = null
		await tally_turn.call()
		if rulerOfEverything:
			await tally_turn.call(true)
		if not active:
			return
		if turnTheLightsOff > 1:
			turnTheLightsOff -= 1
			await showMessage("The lights are off! All damage is doubled!")
			await get_tree().create_timer(0.5).timeout
		elif turnTheLightsOff == 1:
			turnTheLightsOff = 0
			turn_the_lights_off_ended.emit()
			await showMessage("*Turn the Lights Off* has ended. The lights are on. Damage is no longer doubled.")
			await get_tree().create_timer(0.5).timeout
		# Enemy turns
		busy = true
		await enemy_turn.call()
		if rulerOfEverything:
			await enemy_turn.call(true)
		
		if turnTheLightsOff > 1:
			turnTheLightsOff -= 1
		
		if rulerOfEverything:
			rulerOfEverything = false
			await showMessage("*Ruler of Everything* has ended")
			await get_tree().create_timer(0.5).timeout
		
			
			await get_tree().create_timer(0.5).timeout
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
					$Camera3D.global_position += Vector3(delta.x, 0, delta.y) / 1080.0
				prev_position = pos
			)
func end_game():
	
	active = false
	busy = true
	selectedTally = null
	current_action = null
	await get_tree().create_timer(1).timeout
	if get_active_tallies().is_empty():
		$Turn/Msg.text = "Enemies won"
	else:
		$Turn/Msg.text = "Tallies won"
	$Turn/Anim.play("Ending")
	$UI/EndTurn.text = "End Battle"
	$UI/EndTurn.clickable = true
	await $UI/EndTurn.clicked
	get_tree().change_scene_to_file("res://Overworld.tscn")
	
signal player_turn_ended
var active = true
