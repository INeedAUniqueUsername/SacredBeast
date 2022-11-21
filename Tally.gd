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
			Tally.Joe:		"Class: Songfighter\n",
			Tally.Rob:		"Class: Guitarcher\nThis suave fellow happens to be a skilled archer. His sharp arrows are known to break hearts.",
			Tally.Andrew:	"Class: Keybard\nThis keyboardist has the blessing of the Rainbow Connection.",		# Musicleric
			Tally.Zubin:	"Class: Basskeeper\nHe wields a hammer and specializes in slaying the toughest enemies.",	#Beast Slayer
			Tally.Ross:		"Class: Rhythmagician\nThis drummer wields the power of musical magic."	# Drumlock, Drumgineer
		}[tally]
signal moved
var is_selected = false
signal clicked
func _ready():
	move_list = {
		Tally.Joe: [Moves.JoeHawley, Moves.AllOfMyFriends],
		Tally.Rob: [Moves.JustApathy, Moves.Greener, Moves.AnotherMinute],
		Tally.Andrew: [Moves.TheWholeWorldAndYou, Moves.TakenForARide, Moves.GoodDay],
		Tally.Zubin: [Moves.ColorBeGone],
		Tally.Ross: [Moves.TheTrap, Moves.TurnTheLightsOff, Moves.RulerOfEverything]
	}[tally]
	
	create_floor_glow()
	$Area.input_event.connect(func(camera, event: InputEvent, a, b, c):
		if event.is_pressed():
			self.clicked.emit()
	)
signal deselected
signal selected
@onready var world = get_tree().get_first_node_in_group("World")
func create_floor_glow():
	var t = TileGlow.instantiate()
	var tc = t.TileColor
	t.color = [tc.Red, tc.Yellow, tc.Green, tc.Blue, tc.Gray][tally]
	world.add_child.call_deferred(t)
	t.tree_entered.connect(func():
		t.global_position = global_position
		t.set_emitting_selected(self)
	)
	moved.connect(t.dismiss)
	selected.connect(t.set_emitting_selected.bind(self))
	deselected.connect(t.set_emitting_selected.bind(self))
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
var joeHawley = false
func begin_turn(rulerOfEverything:bool):
	joeHawley = false
	if !rulerOfEverything and allOfMyFriends > 0:
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
func end_turn():
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
func use_move_joe_hawley():
	
	for i in range(1):
		var a = AudioStreamPlayer3D.new()
		add_child(a)
		a.stream = preload("res://Sounds/JoeHawleyJoeHawley.wav")
		a.global_position = global_position + Vector3(0, 1, 0)
		a.play()
		a.finished.connect(a.queue_free)
		
		$Anim.play("Punch")
		await $Anim.animation_finished
		
		var param = PhysicsPointQueryParameters3D.new()
		param.position = $Punch.global_position
		param.collide_with_areas = true
		param.collide_with_bodies = false
		param.exclude = []
		param.collision_mask = -1
		
		var dmg = {
			true:40,
			false:20
		}[joeHawley]
		
		var hit = get_world_3d().direct_space_state.intersect_point(param, 32)
		hit = hit.map(func(h):
			return h.collider
		).filter(func(h):
			return h.is_in_group("Hitbox")
		).map(func(h):
			h.get_parent().take_damage(HitDesc.new(self, param.position, dmg, Moves.JoeHawley))
		)
		await get_tree().create_timer(0.2).timeout
	await get_tree().create_timer(0.3).timeout
	$Anim.play("Idle")
	joeHawley = true
func use_move_all_of_my_friends():
	allOfMyFriends = len(get_tree().get_nodes_in_group("Tally"))
	show_message.emit("Joe's defense is at " + str(allOfMyFriends * 20) + "%.")
	await get_tree().create_timer(1).timeout
func use_move_just_apathy(enemy: Node3D):
	$Anim.play("Shoot")
	await $Anim.animation_finished
	enemy.take_damage(HitDesc.new(self, enemy.global_position + Vector3(0, 0.5, 0), randi_range(1, 100), Moves.JustApathy))
	await get_tree().create_timer(0.5).timeout
	$Anim.play("Idle")
func use_move_greener(enemy: Node3D):
	$Anim.play("Shoot")
	await $Anim.animation_finished
	var dmg = 10 + walk_remaining * 5
	walk_remaining = 0
	enemy.take_damage(HitDesc.new(self, enemy.global_position + Vector3(0, 0.5, 0), dmg, Moves.Greener))
	await get_tree().create_timer(0.5).timeout
	$Anim.play("Idle")
func use_move_another_minute(other:TallyChar):
	await get_tree().create_timer(0.5).timeout
	other.walk_remaining += 8
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
	
	show_message.emit(e.title + " was taken for a ride!")
	
	var tw = get_tree().create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_QUAD)
	tw.tween_property(e, "global_position", pos, 0.5)
	tw.play()
	
	await get_tree().create_timer(1).timeout
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
	var hit = get_world_3d().direct_space_state.intersect_point(param, 32)
	hit = hit.map(func(h):
		return h.collider
	).filter(func(h):
		return h.is_in_group("Hitbox")
	).map(func(h):
		h.get_parent().take_damage(HitDesc.new(self, param.position, 60, Moves.ColorBeGone))
	)
	await get_tree().create_timer(1).timeout
	$Anim.play("Idle")

func use_move_the_trap(first: Node3D):
	$Anim.play("Wave")
	await $Anim.animation_finished
	$Anim.play("Idle")
	
	$Lightning.play()
	
	
	var seen = [first]
	var next = [first]
	while len(next) > 0:
		await get_tree().create_timer(0.3).timeout
		var e = next.pop_front()
		e.take_damage(HitDesc.new(self, e.global_position + Vector3(0, 0.5, 0), 30, Moves.TheTrap))
		
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
	$Anim.play("Idle")
		
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
func use_move_turn_the_lights_off():
	$Anim.play("Wave")
	await $Anim.animation_finished
	$Anim.play("Idle")
func heal(amount:int):
	pass
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
func take_damage(h:HitDesc):
	h.dmg *= (1 - allOfMyFriends/5.0)
	
	show_message.emit(tallyName + " was hit for " + str(h.dmg) + " damage!")
	var at = preload("res://ActionText.tscn").instantiate()
	add_child(at)
	at.global_position = h.pos + Vector3(0, 0.5, 1)
	at.get_node("Label3D").text = str(h.dmg)
	
	var au = AudioStreamPlayer3D.new()
	au.stream = preload("res://Sounds/punch_hit.wav")
	
	add_child(au)
	au.global_position = h.pos
	au.play()
	au.finished.connect(au.queue_free)
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
