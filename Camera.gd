extends Camera3D

var can_move = true

var offset: Vector3

var follow: Node3D:
	set(n):
		if n:
			offset = (global_position - n.global_position)
		follow = n
var follow_pos: Vector3:
	get:
		return follow.global_position + offset 
func move(delta: Vector3):
	var tw = get_tree().create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_QUAD)
	tw.tween_property(self, "global_position", global_position + delta, 0.2)
	
	tw.play()
	await tw.finished
func _process(delta):
	if follow and is_instance_valid(follow):
		global_position = follow_pos
		return
	if can_move:
		var p = Input.is_key_pressed
		var dirs = {
			KEY_UP: Vector3(0, 0, -1),
			KEY_DOWN: Vector3(0, 0, 1),
			KEY_RIGHT: Vector3(1, 0, 0),
			KEY_LEFT: Vector3(-1, 0, 0),
		}
		for key in dirs:
			if p.call(key):
				can_move = false
				await move(dirs[key])
				can_move = true
			
func shake():
	var magnitude = 0.4
	var start = global_position
	while magnitude > 1/100.0:
		var v = Vector3(0, magnitude, 0)
		global_position = start + v
		await get_tree().process_frame
		await get_tree().process_frame
		global_position = start - v
		await get_tree().process_frame
		await get_tree().process_frame
		
		magnitude /= 1.5
		
	global_position = start
	
