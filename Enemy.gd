extends Node3D

@export var title: String

enum Width {
	Single, Double
}
@export var width : Width

signal show_message(message:String)

const HitDesc = preload("res://HitDesc.gd")

var is_turn_active:bool:
	set(b):
		if $Aura:
			$Aura.emitting = b
func begin_turn():
	is_turn_active = true
	
	var target = get_tree().get_first_node_in_group("Tally") as Node3D
	if target:
		await walk_towards(target.global_position)
		if (global_position - target.global_position).length() < 4:
			show_message.emit(title + " attacks!")
			
			if $Anim.has_animation("Flash"):
				$Anim.play("Flash")
				await $Anim.animation_finished
			target.take_damage(HitDesc.new(self, self.global_position, 10))
			await get_tree().create_timer(1).timeout
			$Anim.play("Idle")
	is_turn_active = false
func walk_towards(target_pos: Vector3):
	var distanceTo = {
		global_position: 0
	}
	var prev = {
		global_position: null
	}
	var seen = [global_position]
	var next = [global_position]
	while len(next) > 0:
		var p = next.pop_front()
		var P = func(x, z): return p + Vector3(x, 0, z)
		var d = distanceTo[p]
		if d > 12:
			continue
		for q in [P.call(-1, 0), P.call(0, -1), P.call(1, 0), P.call(0, 1)]:
			distanceTo[q] = d + 1
			if seen.has(q):
				continue
			seen.push_back(q)
			if !can_occupy(q):
				continue
			next.push_back(q)
			prev[q] = p
	var dest = global_position
	var D = func(p): return abs(3 - (p - target_pos).length())
	
	var dist = D.call(dest)
	for p in prev.keys():
		var d = D.call(p)
		if d < dist:
			dest = p
			dist = d
	while distanceTo[dest] > 6:
		dest = prev[dest]
	var path = []
	var p = dest
	while prev[p] != null:
		path.push_front(p)
		p = prev[p]
		print(p)
	
	for step in path:
		var t = get_tree().create_tween()
		t.set_ease(Tween.EASE_OUT)
		t.set_trans(Tween.TRANS_QUAD)
		t.tween_property(self, "global_position", step, 0.3)
		t.play()
		await t.finished
func can_occupy(pos: Vector3):
	return [[Vector3(0, 0, 0)], [Vector3(-0.5, 0, 0), Vector3(0.5, 0, 0)]][width].all(func(off):
		return can_walk(pos + off)
		)
func can_walk(pos: Vector3):
	var allow_walk = func():
		var param = PhysicsPointQueryParameters3D.new()
		param.position = pos + Vector3(0, 0.1, 0)
		param.collide_with_areas = true
		param.collide_with_bodies = false
		param.exclude = [$NoWalk]
		param.collision_mask = -1
		return get_world_3d().direct_space_state.intersect_point(param).all(func(e):
			return !e.collider.is_in_group("NoWalk")
			)
	return has_ground(pos) and allow_walk.call()
func has_descendant(n:Node):
	while n:
		if n == self:
			return true
		n = n.get_parent()
	return false
func has_ground(pos: Vector3):
	var param = PhysicsPointQueryParameters3D.new()
	param.position = pos + Vector3(0, -0.1, 0)
	param.collide_with_areas = false
	param.collide_with_bodies = true
	param.exclude = []
	param.collision_mask = -1
	
	var b = get_world_3d().direct_space_state.intersect_point(param).any(func(e):
		return e.collider.is_in_group("Ground")
		)
	if !b:
		pass
	return b
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
	world.add_child(dp)
	dp.global_position = global_position + Vector3(0, 0.5, 0)
	
	await get_tree().create_timer(0.5).timeout
	$Anim.play("Die")
	await $Anim.animation_finished
	queue_free()
	
