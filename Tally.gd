extends Node3D



const TileGlow = preload("res://TileGlow.tscn")

@export_enum(Joe, Rob, Andrew, Zubin, Ross) var tally

signal moved
func _ready():
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
	world.add_child.call_deferred(t)
	
	moved.connect(t.dismiss)
	
var is_selected = true
func deselect():
	is_selected = false
	deselected.emit()
func select():
	is_selected = true
	selected.emit()
	
	const dirs = [Vector3(0, 0, 1), Vector3(0, 0, -1), Vector3(1, 0, 0), Vector3(-1, 0, 0)]
	
	var seen = {global_position:null}
	var next : Array[Vector3] = [global_position]
	
	var move_to := func move_to(t: Node3D):
		if !seen.has(t.global_position):
			return
			
		
		self.moved.emit()
		var path = t.get_tile_path()
		for k in seen.values():
			if path.has(k):
				continue
			k.dismiss()
		seen.clear()
		
		var tw = get_tree().create_tween()
		tw.tween_property(self, "global_position", t.global_position, 1)
		tw.play()
		for x in path:
			tw.finished.connect(x.dismiss)
			
		await tw.finished
		
		create_floor_glow()
	var create_tile := func(v: Vector3, delay:float, parent:Node3D):
		var timer = Timer.new()
		add_child(timer)
		timer.wait_time = delay
		timer.start()
		selected.connect(timer.queue_free)
		
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
			seen[q] = tile
			next.push_back(q)
	var start = seen[global_position]
	start.tree_entered.connect(start.queue_free)
	seen.erase(global_position)
func _process(delta):
	pass
