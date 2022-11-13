extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready():
	await $Anim.animation_finished
	$Anim.play("Hover")
func dismiss():
	$Anim.play("Exit")
	await $Anim.animation_finished
	queue_free()
