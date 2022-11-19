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
			
			Tally.Joe: 		"Class: Songfighter",
			Tally.Rob: 		"Class: Guitarcher",
			Tally.Andrew: 	"Class: Keybard",		# Musicleric
			Tally.Zubin: 	"Class: Basskeeper",	#Beast Slayer
			Tally.Ross: 	"Class: Rhythmagician"	# Drumlock, Drumgineer
		}[tally]
signal moved
var is_selected = false
func _ready():
	move_list = {
		Tally.Joe: [Moves.JoeHawley],
		Tally.Rob: [Moves.JustApathy, Moves.Greener, Moves.AnotherMinute],
		Tally.Andrew: [],
		Tally.Zubin: [],
		Tally.Ross: []
	}[tally]
	
	create_floor_glow()
	$Area.input_event.connect(func(camera, event: InputEvent, a, b, c):
		if event.is_pressed():
			if self.is_selected:
				if self.is_moving:
					return
				self.deselect()
			else:
				self.select()
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
	if !allow_select:
		return
	is_selected = false
	deselected.emit()
func select():
	if !allow_select:
		return
	is_selected = true
	selected.emit()

var allow_select = false
var is_moving = false

var walk_remaining = 0
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
		is_moving = true
		for x in path:
			var tw = get_tree().create_tween()
			tw.tween_property(self, "global_position", x.global_position, 1/3.0)
			tw.play()
			tw.finished.connect(x.dismiss)
			await tw.finished
		is_moving = false
		
		create_floor_glow()
		if self.is_selected:
			if not is_instance_valid(flag):
				flag = null
			self.show_walk(flag)
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
		var hit = get_world_3d().direct_space_state.intersect_point(param, 32)
		hit = hit.map(func(h):
			return h.collider
		).filter(func(h):
			return h.is_in_group("Hitbox")
		).map(func(h):
			h.get_parent().take_damage(HitDesc.new(self, param.position, 10, Moves.JoeHawley))
		)
		await get_tree().create_timer(0.2).timeout
	await get_tree().create_timer(0.3).timeout
	$Anim.play("Idle")
func use_move_just_apathy(enemy: Node3D):
	
	$Anim.play("Shoot")
	await $Anim.animation_finished
	enemy.take_damage(HitDesc.new(self, enemy.global_position + Vector3(0, 0.5, 0), randi_range(1, 100), Moves.JustApathy))
	await get_tree().create_timer(0.5).timeout
	$Anim.play("Idle")

func use_move_greener(enemy: Node3D):
	
	$Anim.play("Shoot")
	await $Anim.animation_finished
	enemy.take_damage(HitDesc.new(self, enemy.global_position + Vector3(0, 0.5, 0), 10 + (enemy.global_position - global_position).length() * 5, Moves.Greener))
	await get_tree().create_timer(0.5).timeout
	$Anim.play("Idle")

func use_move_another_minute(other:TallyChar):
	
	other.walk_remaining += 8
	await get_tree().create_timer(0.5).timeout
func take_damage(hitDesc:HitDesc):
	pass
func _process(delta):
	pass

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
