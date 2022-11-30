extends Node2D
# Called when the node enters the scene tree for the first time.
func _ready():
	var levels = [
		{
			title = "Banana Man",
			desc = "The Tallies encounter a group of songbird statues. But who's that over there, hopping on the white hot sand?",
		}, {
			title = "Two Wuv",
			desc = "The Tallies encounter two girls with great eyes (emphasis on eyes).",
		}, {
			title = "Murders",
			desc = "",
		},  {
			title = "Murders",
			desc = "A certain creature lurks around the black woods.",
		}, {
			title = "Sacred Beast",
			desc = "",
		},
	]
	
	var transition = func(level:String):
		if $Anim.is_playing():
			return
		$Anim.play("Exit")
		await $Anim.animation_finished
		get_tree().change_scene_to_file(level)
	
	var i = 0
	for m in get_tree().get_nodes_in_group("MapMarker"):
		var l = levels[i]
		
		var anim = m.get_node("Anim")
		var a = m.get_node("Area") as Area2D
		a.mouse_entered.connect(func():
			$Control.visible = true
			$Control/Title.text = l.title
			$Control/Desc.text = l.desc
			anim.play("Grow")
			)
		a.mouse_exited.connect(func():
			$Control.visible = false
			anim.play("Shrink")
			)
		a.input_event.connect(func(viewport,event:InputEvent,idx:int):
			if event.is_pressed() and event.button_index == MOUSE_BUTTON_MASK_LEFT:
				transition.call("res://Levels/L" + str(i) + ".tscn")
				pass
			)
		
		
		i += 1
		
	pass # Replace with function body.
