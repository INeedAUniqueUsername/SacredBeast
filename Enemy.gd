extends Node3D

signal died
signal took_damage(hitDesc)
func take_damage(hitDesc):
	took_damage.emit(hitDesc)
	
	$Anim.play("Hurt")
	await $Anim.animation_finished
	die()
	pass
@onready var world = get_tree().get_first_node_in_group("World")
func die():
	died.emit()
	var a = AudioStreamPlayer3D.new()
	world.add_child(a)
	a.stream = preload("res://Sounds/enemy_die.wav")
	a.global_position = global_position + Vector3(0, 0.5, 0)
	a.finished.connect(a.queue_free)
	a.play()
	
	const DeathParticles = preload("res://DeathParticles.tscn")
	var dp = DeathParticles.instantiate()
	dp.global_position = global_position + Vector3(0, 0.5, 0)
	world.add_child(dp)
	
	await get_tree().create_timer(0.5).timeout
	$Anim.play("Die")
	await $Anim.animation_finished
	queue_free()
	
