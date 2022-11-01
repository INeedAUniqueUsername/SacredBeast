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

signal moved
var is_selected = false
func _ready():
	move_list = {
		Tally.Joe: [Moves.JoeHawley],
		Tally.Rob: [],
		Tally.Andrew: [],
		Tally.Zubin: [],
		Tally.Ross: []
	}[tally]
	
	create_floor_glow()
	$Area.input_event.connect(func(camera, event: InputEvent, a, b, c):
		if event.is_pressed():
			if is_selected:
				self.deselect()
			else:
				self.select()
	)
signal deselected
signal selected
@onready var world = get_tree().get_first_node_in_group("World")

func create_floor_glow():
	var t = TileGlow.instantiate()
	t.global_position = global_position
	t.set_emitting_selected(self)
	world.add_child.call_deferred(t)
	
	moved.connect(t.dismiss)
	selected.connect(t.set_emitting_selected.bind(self))
	deselected.connect(t.set_emitting_selected.bind(self))
func deselect():
	is_selected = false
	deselected.emit()
func select():
	is_selected = true
	selected.emit()
	show_walk()
func show_walk():
	const dirs = [Vector3(0, 0, 1), Vector3(0, 0, -1), Vector3(1, 0, 0), Vector3(-1, 0, 0)]
	
	var seen = {global_position:null}
	var next : Array[Vector3] = [global_position]
	
	var move_to := func move_to(t: Node3D):
		if !seen.has(t.global_position):
			return
		self.moved.emit()
		var path = t.get_tile_path()
		for k in seen.values():
			k.clickable = false
			if path.has(k):
				continue
			k.dismiss()
		seen.clear()
		next.clear()
		for x in path:
			var tw = get_tree().create_tween()
			tw.tween_property(self, "global_position", x.global_position, 1/3.0)
			tw.play()
			tw.finished.connect(x.dismiss)
			await tw.finished
		
		create_floor_glow()
		self.show_walk()
	var create_tile := func(v: Vector3, delay:float, parent:Node3D):
		var timer = Timer.new()
		add_child(timer)
		timer.wait_time = delay
		timer.start()
		
		selected.connect(timer.queue_free)
		deselected.connect(timer.queue_free)
		
		var t = preload("res://TileStep.tscn").instantiate()
		t.tree_exited.connect(timer.queue_free)
		timer.timeout.connect(func():
			timer.queue_free()
			if !is_instance_valid(t):
				return
			t.global_position = v
			t.parent = parent
			world.add_child.call_deferred(t)
			selected.connect(t.dismiss)
			deselected.connect(t.dismiss)
			t.clicked.connect(move_to.bind(t))
		)
		return t
	
	var radius = 4
	while !next.is_empty():
		
		var p = next.pop_front()
		var disp := (p - global_position) as Vector3
		if disp.length() > radius:
			break
		
		
		var tile = create_tile.call(p, (abs(disp.x) + abs(disp.z))/4.0, seen[p])
		
		seen[p] = tile
		for offset in dirs:
			var q = p + offset
			if q in seen:
				continue
			if !has_ground(q):
				continue
			seen[q] = tile
			next.push_back(q)
	var start = seen[global_position]
	start.tree_entered.connect(start.queue_free)
	seen.erase(global_position)
const HitDesc = preload("res://HitDesc.gd")
func use_move(m):
	if m == Moves.JoeHawley:
		
		#var TileTarget = preload("res://TileTarget.tscn")
		#var forward = global_position + global_transform.basis.x
		#var tt = TileTarget.instantiate()
		#tt.global_position = forward
		#world.add_child(tt)
		
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
			h.get_parent().take_damage(HitDesc.new(self, param.position, 10))
		)
		
		await get_tree().create_timer(0.5).timeout
		
		
		$Anim.play("Idle")
		return
	pass
func _process(delta):
	pass


func has_ground(pos: Vector3):
	var param = PhysicsPointQueryParameters3D.new()
	param.position = pos + Vector3(0, -0.1, 0)
	param.collide_with_areas = false
	param.collide_with_bodies = true
	param.exclude = []
	param.collision_mask = -1
	for hit in get_world_3d().direct_space_state.intersect_point(param):
		return true
	return false
