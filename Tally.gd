extends Node3D
class_name TallyChar
const Tally = preload("res://Common.gd").Tally
const TileGlow = preload("res://TileGlow.tscn")
@export_enum(Joe, Rob, Andrew, Zubin, Ross) var tally
const MoveInfo = preload("res://Moves.gd").MoveInfo
var move_list : Array = []
var tallyName: String:
	get:
		return {
			Tally.Joe: "Joe Hawley",
			Tally.Rob: "Rob Cantor",
			Tally.Andrew: "Andrew Horowitz",
			Tally.Zubin: "Zubin Sedghi",
			Tally.Ross: "Ross Federman"	
		}[tally]
var desc:String:
	get:
		return {
			Tally.Joe:		"Class: Songfighter\nKnown for his fabled attack, this singer can act twice per turn.",
			Tally.Rob:		"Class: Guitarcher\nThis suave fellow happens to be a skilled archer. His sharp arrows are known to break hearts.",
			Tally.Andrew:	"Class: Keybard\nThis keyboardist supports the party with the power of whimsical magic.",
			Tally.Zubin:	"Class: Basskeeper\nHe wields a hammer and specializes in slaying the toughest of enemies.",
			Tally.Ross:		"Class: Rhythmagician\nThis drummer can use musical magic to switch up the rhythm of battle."
		}[tally]
signal moved
var is_selected = false
signal clicked
func _ready():
	move_list = {
		Tally.Joe: [Moves.JoeHawley, Moves.AristotlesDenial, Moves.AllOfMyFriends, Moves.SpringAndAStorm],
		Tally.Rob: [Moves.JustApathy, Moves.Greener, Moves.AnotherMinute, Moves.GardenOfEden],
		Tally.Andrew: [Moves.TheWholeWorldAndYou, Moves.TakenForARide, Moves.Misfortune, Moves.GoodDay],
		Tally.Zubin: [Moves.ColorBeGone, Moves.RotaryPark],
		Tally.Ross: [Moves.TheTrap, Moves.TurnTheLightsOff, Moves.RulerOfEverything, Moves.HotRodDuncan]
	}[tally]
	
	create_floor_glow()
	$Area.input_event.connect(func(camera, event: InputEvent, a, b, c):
		if event.is_pressed():
			self.clicked.emit()
	)
	var b = preload("res://HpBar.tscn").instantiate()
	add_child(b)
	b.global_position += Vector3.UP * 1.5
	b.barColor = tally
	hp_changed.connect(func():
		b.portion = clamp(1.0 * self.hp / self.hp_max, 0, 1)
		)
	
signal deselected
signal selected
@onready var world = get_tree().get_first_node_in_group("World")
func create_floor_glow():
	var t = TileGlow.instantiate()
	t.color = tally
	world.add_child.call_deferred(t)
	t.tree_entered.connect(func():
		t.global_position = global_position
		t.set_emitting_selected(self)
	)
	moved.connect(t.dismiss)
	selected.connect(t.set_emitting_selected.bind(self))
	deselected.connect(t.set_emitting_selected.bind(self))
	tree_exiting.connect(t.dismiss)
func deselect():
	is_selected = false
	deselected.emit()
func select():
	is_selected = true
	selected.emit()
var is_busy = false

var moves_remaining = 0
var walk_remaining = 0

var willingVictim = 0

var allOfMyFriends = 0
var joeHawley = 0


var misfortune = 0
var misfortuneTarget:Enemy = null
var aristotlesDenial = false
var springAndAStorm = false
func begin_turn(rulerOfEverything:bool, turnTheLightsOff:bool):
	self.turnTheLightsOff = turnTheLightsOff
	if not rulerOfEverything:
		aristotlesDenial = false
		if misfortune > 0 and is_instance_valid(misfortuneTarget) and misfortuneTarget.is_inside_tree():
			show_message.emit(misfortuneTarget.title + " was struck by Misfortune!")
			await get_tree().create_timer(1.5).timeout
			var d = HitDesc.new(self, misfortuneTarget.global_position + Vector3.UP/2, misfortune * hp / 2, Moves.Misfortune)
			await misfortuneTarget.take_damage(d)
			await on_damage_dealt(d.dmgTaken)
		springAndAStorm = false
		
		misfortune = 0
		
		joeHawley = 0
		if allOfMyFriends > 0:
			allOfMyFriends = 0
			show_message.emit("*All of my Friends* has ended")
			await get_tree().create_timer(2)
	
	if tally == Tally.Joe:
		moves_remaining = 2
	else:
		moves_remaining = 1
	
	willingVictim -= 1
	if willingVictim > 0:
		walk_remaining = 0
		show_message.emit(tallyName + " is unable to walk for this turn!")
		await get_tree().create_timer(2)
	else:
		walk_remaining = 8
func end_turn(turnTheLightsOff:bool):
	self.turnTheLightsOff = turnTheLightsOff
	pass
func show_walk(flag:Node = null):
	if !flag:
		flag = Node.new()
		add_child(flag)
	deselected.connect(flag.queue_free)
	selected.connect(flag.queue_free)
	var distanceTo = {
		global_position:0
	}
	const dirs = [Vector3(0, 0, 1), Vector3(0, 0, -1), Vector3(1, 0, 0), Vector3(-1, 0, 0)]
	var seen = {global_position:null}
	var next : Array[Vector3] = [global_position]
	var move_to := func move_to(t: Node3D):
		if !seen.has(t.global_position):
			return
		is_busy = true
		self.walk_remaining -= distanceTo[t.global_position]
		self.moved.emit()
		var path = t.get_tile_path()
		path.map(func(p):
			flag.tree_exiting.disconnect(p.dismiss)
		)
		seen.values().map(func(k):
			k.clickable = false
			if !path.has(k):
				if k.is_inside_tree():
					k.dismiss()
				else:
					k.queue_free()
		)
		seen.clear()
		next.clear()
		for x in path:
			var tw = get_tree().create_tween()
			tw.tween_property(self, "global_position", x.global_position, 1/3.0)
			tw.play()
			tw.finished.connect(x.dismiss)
			await tw.finished
		
		create_floor_glow()
		if self.is_selected:
			if not is_instance_valid(flag):
				flag = null
			self.show_walk(flag)
		is_busy = false
	var create_tile := func create_tile(v: Vector3, delay:float, parent:Node3D):
		
		var t = preload("res://TileStep.tscn").instantiate()
		t.parent = parent
		
		var timer = Timer.new()
		add_child(timer)
		if delay > 0:
			timer.wait_time = delay
			timer.start()
		deselected.connect(timer.queue_free)
		timer.timeout.connect(func place_in_world():
			if !is_instance_valid(t):
				return
			world.add_child(t)
			t.global_position = v
			flag.tree_exiting.connect(t.dismiss)
			t.clicked.connect(move_to.bind(t))	
		)
		
		timer.timeout.connect(timer.queue_free)
		return t
	
	while !next.is_empty():
		
		var p = next.pop_front()
		var d = distanceTo[p]
		if d > walk_remaining:
			break
		var tile = create_tile.call(p, d/8.0, seen[p])
		seen[p] = tile
		for offset in dirs:
			var q = p + offset
			if seen.has(q):
				continue
			if !can_walk(q):
				continue
			distanceTo[q] = d + 1
			seen[q] = tile
			next.push_back(q)
	
	seen[global_position].queue_free()
	seen.erase(global_position)
const HitDesc = preload("res://HitDesc.gd")

func on_damage_dealt(dmgDealt:int):
	if dmgDealt <= 0:
		return
	if springAndAStorm:
		var delta = heal(dmgDealt / 2)
		if delta > 0:
			add_child(preload("res://HealParticle.tscn").instantiate())
			var a = AudioStreamPlayer3D.new()
			add_child(a)
			a.stream = preload("res://Sounds/staff_heal.wav")
			a.play()
			a.finished.connect(a.queue_free)
			
			show_message.emit(tallyName + " restored " + str(delta) + " HP!")
			await get_tree().create_timer(0.5).timeout
# Joe
func use_move_joe_hawley():
	$Anim.play("Punch")
	await $Anim.animation_finished
	
	var param = PhysicsPointQueryParameters3D.new()
	param.position = $Punch.global_position
	param.collide_with_areas = true
	param.collide_with_bodies = false
	param.exclude = []
	param.collision_mask = -1
	
	var dmg = 20 * (1 + joeHawley)
	if allOfMyFriends > 0:
		dmg *= 6 - allOfMyFriends
	
	var result = {
		dmgDealt = 0
	}
	
	var hit = get_world_3d().direct_space_state.intersect_point(param, 32)
	hit = hit.map(func(h):
		return h.collider
	).filter(func(h):
		return h.is_in_group("Hitbox")
	).map(func(h):
		return h.get_parent()
	)
	if len(hit) > 0:
		var h = hit.front()
		
		var d = HitDesc.new(self, param.position, dmg, Moves.JoeHawley)
		await h.take_damage(d)
		result.dmgDealt += d.dmgTaken
	
	await get_tree().create_timer(0.5).timeout
	$Anim.play("Idle")
	joeHawley += 1
	
	await on_damage_dealt(result.dmgDealt)
func use_move_aristotles_denial():
	aristotlesDenial = true
func use_move_all_of_my_friends():
	allOfMyFriends = len(get_tree().get_nodes_in_group("Tally"))
	var p = (allOfMyFriends - 1) * 25
	show_message.emit("Joe gained " + str(p) + "% defense.")
	await get_tree().create_timer(1).timeout
func use_move_spring_and_a_storm():
	for t in get_tree().get_nodes_in_group("Tally"):
		t.springAndAStorm = true
	await get_tree().create_timer(0.5).timeout
# Rob
func use_move_just_apathy(enemy: Node3D):
	$Anim.play("Shoot")
	await $Anim.animation_finished
	var d = HitDesc.new(self, enemy.global_position + Vector3(0, 0.5, 0), randi_range(1, 100), Moves.JustApathy)
	get_tree().create_timer(0.5).timeout.connect($Anim.play.bind("Idle"))
	await enemy.take_damage(d)
	await on_damage_dealt(d.dmgTaken)
func use_move_greener(enemy: Node3D):
	$Anim.play("Shoot")
	await $Anim.animation_finished
	var dmg = 10 + walk_remaining * 5
	walk_remaining = 0
	var d = HitDesc.new(self, enemy.global_position + Vector3(0, 0.5, 0), dmg, Moves.Greener)
	get_tree().create_timer(0.5).timeout.connect($Anim.play.bind("Idle"))
	await enemy.take_damage(d)
	await on_damage_dealt(d.dmgTaken)
func use_move_another_minute(other:TallyChar):
	$BowCharge.play()
	$Anim.play("Raise")
	await $Anim.animation_finished
	$Anim.play("Idle")
	other.walk_remaining += 8
func use_move_garden_of_eden(other:TallyChar):
	$BowCharge.play()
	$Anim.play("Raise")
	await $Anim.animation_finished
	$Anim.play("Idle")
	other.hp = other.hp_max
# Andrew
func use_move_the_whole_world_and_you(enemy:Node3D):
	$Anim.play("Raise")
	await $Anim.animation_finished
	$Anim.play("Idle")
	enemy.timestop = 1
	
	var tp = preload("res://TimestopParticle.tscn").instantiate()
	enemy.add_child(tp)
	tp.global_position = enemy.global_position
	
	var a = AudioStreamPlayer3D.new()
	a.stream = preload("res://Sounds/timestop.wav")
	enemy.add_child(a)
	a.play()
	a.finished.connect(a.queue_free)
	pass
func use_move_taken_for_a_ride(e:Node3D, pos:Vector3):
	
	$Anim.play("Raise")
	await $Anim.animation_finished
	$Anim.play("Idle")
	
	$Teleport.play()
	
	show_message.emit(e.title + " was taken for a ride!")
	
	e.takenForARide = true
	var tw = get_tree().create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_QUAD)
	tw.tween_property(e, "global_position", pos, 0.5)
	
	tw.play()
	
	e.spin()
	
	await get_tree().create_timer(1).timeout
func use_move_misfortune_1(e:Node3D):
	
	$Anim.play("Raise")
	await $Anim.animation_finished
	$Anim.play("Idle")
	misfortune = 1
	misfortuneTarget = e
func use_move_misfortune_2():
	
	$Anim.play("Raise")
	await $Anim.animation_finished
	$Anim.play("Idle")
	misfortune = 2
func use_move_good_day():
	$Anim.play("Raise")
	await $Anim.animation_finished
	$Anim.play("Idle")
	$Heal.play()
	for t in get_tree().get_nodes_in_group("Tally"):
		t.heal(20)
		var h = preload("res://HealParticle.tscn").instantiate()
		t.add_child(h)
		h.global_position = t.global_position
# Zubin
func use_move_color_be_gone():
	$Anim.play("Smash")
	await $Anim.animation_finished
	$HammerHit.play()
	
	var param = PhysicsPointQueryParameters3D.new()
	param.position = $Smash.global_position
	param.collide_with_areas = true
	param.collide_with_bodies = false
	param.exclude = []
	param.collision_mask = -1
	
	var dmgDealt = 0
	
	var hit = get_world_3d().direct_space_state.intersect_point(param, 32)
	hit = hit.map(func(h):
		return h.collider
	).filter(func(h):
		return h.is_in_group("Hitbox")
	).map(func(h):
		return h.get_parent()
	)
	get_tree().create_timer(1).timeout.connect($Anim.play.bind("Idle"))
	if len(hit) > 0:
		var h = hit.front()
		var d = HitDesc.new(self, param.position, 60, Moves.ColorBeGone)
		await h.take_damage(d)
		dmgDealt += d.dmgTaken
	
		
	await on_damage_dealt(dmgDealt)
func use_move_rotary_park():
	$Anim.play("SpinCharge")
	await $Anim.animation_finished	
	(func():
		$Anim.play("Spin")
		await $Anim.animation_finished
		$Anim.play("Idle")
	).call()
	
	var par = PhysicsShapeQueryParameters3D.new()
	var sh = SphereShape3D.new()
	sh.radius = 1.5
	par.shape = sh
	par.transform.origin = global_position
	par.collide_with_areas = true
	par.collide_with_bodies = false
	par.exclude = []
	par.collision_mask = -1
	var hit = get_world_3d().direct_space_state.intersect_shape(par).map(func(h):
		return h.collider
	).filter(func(h):
		return h.is_in_group("Hitbox")
	).map(func(h):
		return h.get_parent() as Enemy
	) as Array[Enemy]
	
	var result = {
		dmgDealt = 0,
		msg = "Damage: "
	}
	
	var flags = []
	
	var dmg = 30
	for h in hit:
		var f = Node.new()
		add_child(f)
		flags.push_back(f)
		
		
		(func():
			var d = HitDesc.new(self, h.global_position + Vector3(0, 0.5, 0), dmg, Moves.RotaryPark, false)
			await h.take_damage(d)
			result.dmgDealt += d.dmgTaken
			result.msg += h.title + ": " + str(d.dmgTaken) + ", "
			f.queue_free()
		).call()
		await get_tree().create_timer(0.1).timeout
		
	for f in flags:
		await f.tree_exited
	
	show_message.emit(result.msg)
	await get_tree().create_timer(2).timeout
	
	await on_damage_dealt(result.dmgDealt)
# Ross
func use_move_the_trap(first: Node3D):
	$Anim.play("Wave")
	await $Anim.animation_finished
	get_tree().create_timer(0.5).timeout.connect($Anim.play.bind("Idle"))
	$Lightning.play()
	var seen = [first]
	var next = [first]
	
	var dmgDealt = 0
	
	var msg = "Damage: "
	while len(next) > 0:
		var e = next.pop_front()
		
		var dmg = 30 / (1 + (e.global_position - first.global_position).length()/4.0)
		var d = HitDesc.new(self, e.global_position + Vector3(0, 0.5, 0), dmg, Moves.TheTrap, false)
		e.take_damage(d)
		dmgDealt += d.dmgTaken
		
		msg += e.title + ": " + str(int(dmg)) + ", "
		
		var param = PhysicsShapeQueryParameters3D.new()
		var sp = SphereShape3D.new()
		sp.radius = 3
		param.shape = sp
		param.transform.origin = e.global_position
		param.collide_with_areas = true
		param.collide_with_bodies = false
		param.exclude = []
		param.collision_mask = -1
		var nearby = get_world_3d().direct_space_state.intersect_shape(param).map(func(h):
			return h.collider
		).filter(func(h):
			return h.is_in_group("Hitbox")
		).map(func(h):
			return h.get_parent()
		)
		for other in nearby:
			if seen.has(other):
				continue
			seen.push_back(other)
			next.push_back(other)
		
		await get_tree().create_timer(0.1).timeout
	show_message.emit(msg)
	await get_tree().create_timer(2).timeout
		
	await on_damage_dealt(dmgDealt)
		
	return
	var e = null
	await get_tree().create_timer(1).timeout
	#e.take_damage(HitDesc.new(self, e.global_position + Vector3(0, 0.5, 0), 30, Moves.TheTrap))
	
	var param = PhysicsShapeQueryParameters3D.new()
	var sp = SphereShape3D.new()
	sp.radius = 3
	param.shape = sp
	param.transform.origin = e.global_position
	param.collide_with_areas = true
	param.collide_with_bodies = false
	param.exclude = []
	param.collision_mask = -1
	var nearby = get_world_3d().direct_space_state.intersect_shape(param).map(func(h):
		return h.collider
	).filter(func(h):
		return h.is_in_group("Hitbox")
	).map(func(h):
		return h.get_parent()
	)
	nearby.erase(e)
	for hit in nearby:
		await get_tree().create_timer(0.5).timeout
		hit.take_damage(HitDesc.new(self, hit.global_position + Vector3(0, 1, 0), 20, Moves.TheTrap))
	pass
func use_move_ruler_of_everything():
	$Anim.play("Wave")
	await $Anim.animation_finished
	$Anim.play("Idle")
	$DoubleTime.play()
func use_move_turn_the_lights_off():
	$Anim.play("Wave")
	await $Anim.animation_finished
	$Anim.play("Idle")
	$DoubleTime.play()
func heal(amount:int):
	var h = hp
	hp = min(hp_max, hp + amount)
	hp_changed.emit()
	return hp - h
func get_line_of_sight_enemies():
	return get_tree().get_nodes_in_group("Enemy")
	[].filter(func(e):
		var param = PhysicsRayQueryParameters3D.new()
		param.from = global_position
		param.to = e.global_position
		param.collide_with_areas = true
		param.collide_with_bodies = false
		param.exclude = [$Area, $NoWalk, e.get_node("Hitbox")]
		param.collision_mask = -1
		var hit = get_world_3d().direct_space_state.intersect_ray(param)
		return not hit.has("collider")
	)
signal show_message(msg:String)

var hp_max = 100
var hp = 100
var turnTheLightsOff = false

var total_damage_taken = 0

signal hp_changed
func take_damage(h:HitDesc):
	h.dmgTaken = h.dmg
	if turnTheLightsOff:
		h.dmgTaken *= 2
	
	#if misfortune > 0:
	#	h.dmgTaken += misfortune * hp / 2
	#	misfortune = 0
	if allOfMyFriends > 0:
		h.dmgTaken *= (1 - (allOfMyFriends - 1)/4.0)
	h.dmgTaken = min(h.dmgTaken, hp)
	
	total_damage_taken += h.dmgTaken
	
	
	show_message.emit(tallyName + " was hit for " + str(h.dmgTaken) + " damage!")
	var at = preload("res://ActionText.tscn").instantiate()
	add_child(at)
	at.global_position = h.pos + Vector3(0, 0.5, 0.5)
	at.get_node("Label3D").text = str(h.dmgTaken)
	
	var au = AudioStreamPlayer3D.new()
	au.stream = preload("res://Sounds/punch_hit.wav")
	add_child(au)
	au.global_position = h.pos
	au.play()
	au.finished.connect(au.queue_free)
	
	hp -= h.dmgTaken
	hp_changed.emit()
	if hp == 0:
		if aristotlesDenial:
			var dmg = 0
			for t in get_tree().get_nodes_in_group("Tally"):
				dmg += t.total_damage_taken
			dmg = dmg / 4
			
			show_message.emit("*Aristotle's Denial* activated! All enemies took damage!")
			await get_tree().create_timer(1).timeout
			var dmgDealt = 0
			for e in get_tree().get_nodes_in_group("Enemy"):
				var d = HitDesc.new(self, e.global_position, dmg, Moves.AristotlesDenial, false)
				await e.take_damage(d)
				dmgDealt += d.dmgTaken
		await fall()
func fall():
	await get_tree().create_timer(2).timeout
	show_message.emit(tallyName + " fell!")
	
	
	var tw = get_tree().create_tween()
	tw.tween_property($Sprite, "modulate", Color.TRANSPARENT, 1)
	tw.play()
	tw.finished.connect(self.queue_free)
	
	var p = preload("res://TallyFallParticle.tscn").instantiate()
	world.add_child(p)
	p.tallyColor = tally
	p.global_position = global_position
	
	var a = AudioStreamPlayer3D.new()
	a.stream = preload("res://Sounds/tally_fall.wav")
	world.add_child(a)
	a.global_position = global_position
	a.play()
	
	
func can_walk(pos: Vector3):
	var allow_walk = func():
		
		var param = PhysicsPointQueryParameters3D.new()
		param.position = pos + Vector3(0, 0.1, 0)
		param.collide_with_areas = true
		param.collide_with_bodies = false
		param.exclude = [$NoWalk]
		param.collision_mask = -1
		return not get_world_3d().direct_space_state.intersect_point(param).any(func(e): return e.collider.is_in_group("NoWalk"))
	
	return allow_walk.call() and has_ground(pos)
func has_ground(pos: Vector3):
	var param = PhysicsPointQueryParameters3D.new()
	param.position = pos + Vector3(0, -0.1, 0)
	param.collide_with_areas = false
	param.collide_with_bodies = true
	param.exclude = []
	param.collision_mask = -1
	
	var hit = get_world_3d().direct_space_state.intersect_point(param)
	return hit.any(func(e): return e.collider.is_in_group("Ground"))
