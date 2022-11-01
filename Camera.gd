extends Camera3D

func shake():
	var magnitude = 0.4
	var start = global_position
	while magnitude > 0:
		var v = Vector3(0, magnitude, 0)
		global_position = start + v
		await get_tree().process_frame
		await get_tree().process_frame
		global_position = start - v
		await get_tree().process_frame
		await get_tree().process_frame
		
		magnitude /= 1.5
		
	
	
