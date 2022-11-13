extends Node3D

@export var title: String

enum Width {
	Single, Double
}
@export var width : Width


var is_turn_active:bool:
	set(b):
		if $Aura:
			$Aura.emitting = b
func begin_turn():
	is_turn_active = true
	
	
	
	await get_tree().create_timer(2).timeout
	
	var target = get_tree().get_first_node_in_group("Tally")
	if target:
		var walkRemaining = {
			global_position: 4
		}
		var prev = {
			global_position: null
		}
		var next = [global_position]
		while len(next) > 0:
			var p = next.pop_front()
			var P = func(x, z): return p + Vector3(x, 0, z)
			var w = walkRemaining[p]
			if w < 1:
				continue
			for q in [P.call(-1, 0), P.call(0, -1), P.call(1, 0), P.call(0, 1)]:
				walkRemaining[q] = w - 1
				next.push_back(q)
				prev[q] = p
		
		
		var tar = target.global_position
		var dest = global_position
		var dist = (dest - tar).length()
		for p in prev.keys():
			var d = (p - target.global_position).length()
			if d < dist:
				dest = p
				dist = d
				pass
		var path = []
		var p = dest
		while prev[p]:
			path.push_front(p)
			p = prev[p]
		
		for step in path:
			var t = get_tree().create_tween()
			t.set_ease(Tween.EASE_OUT)
			t.set_trans(Tween.TRANS_QUAD)
			t.tween_property(self, "global_position", step, 0.3)
			t.play()
			await t.finished
	is_turn_active = false
	pass

func can_occupy(pos: Vector3):
	return [[Vector3(0, 0, 0)], [Vector3(-0.5, 0, 0), Vector3(0.5, 0, 0)]].all(func(off):
		return can_walk(pos + off)
		)

func can_walk(pos: Vector3):
	var allow_walk = func():
		
		var param = PhysicsPointQueryParameters3D.new()
		param.position = pos + Vector3(0, 0.1, 0)
		param.collide_with_areas = true
		param.collide_with_bodies = false
		param.exclude = []
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
	
