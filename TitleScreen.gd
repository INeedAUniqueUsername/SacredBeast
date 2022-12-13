extends Control
func _ready():
	if $Button:
		$Button.pressed.connect(self.start_story)
func start_story():
	$Anim.play("Exit")
	await $Anim.animation_finished
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://Prologue.tscn")
