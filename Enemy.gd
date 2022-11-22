extends Node3D
class_name Enemy

enum EnemyType {
	Ashley,
	Crow,
	Cannibal,
	Erlking,
	Fate,
	MaryKate,
	Misery,
	Animal
}
class EnemyInfo:
	var title:String
	var desc:String
	func _init(title:String, desc:String):
		self.title = title
		self.desc = desc
var EnemyDict = {
	EnemyType.Ashley: 	EnemyInfo.new("Ashley", "When this enemy falls, any excess damage from the killing hit is converted to healing for all nearby enemies"),
	EnemyType.Cannibal: EnemyInfo.new("Cannibal", "This enemy gains unlimited movement range on every other turn."),
	EnemyType.Crow: 	EnemyInfo.new("Crow", ""),
	EnemyType.Erlking: 	EnemyInfo.new("Erlking", ""),
	EnemyType.Fate: 	EnemyInfo.new("Fate", ""),
	EnemyType.MaryKate: EnemyInfo.new("Mary-Kate", "When this enemy falls, any excess damage from the killing hit is dealt to all Tallies"),
	EnemyType.Misery: 	EnemyInfo.new("Misery", "")
}
@export var enemyType: EnemyType
var title:String:
	get:
		return EnemyDict[enemyType].title
var desc:String:
	get: return EnemyDict[enemyType].desc
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
var turnIndex = 0

var timestop = 0:
	set(t):
		timestop = t
		if t > 0:
			$Anim.play("Hurt")
		else:
			$Anim.play("Idle")

var turnTheLightsOff = false
var takenForARide = false
func begin_turn(turnTheLightsOff = false):
	takenForARide = false
	self.turnTheLightsOff = turnTheLightsOff
	turnIndex += 1
	if timestop > 0:
		show_message.emit(title + " cannot act!")
		await get_tree().create_timer(1).timeout
		return
	
	is_turn_active = true
	await do_turn()
	is_turn_active = false

var cannibal_target: TallyChar = null

var turn_priority = 100
func do_turn():
	if enemyType == EnemyType.Cannibal:
		if cannibal_target:
			var inRange = ((cannibal_target.global_position + Vector3(1, 0, 0)) - global_position).length() <= 0.5
			if cannibal_target.willingVictim > 0 or inRange:
				
				if not inRange:
					show_message.emit("Cannibal makes her way towards " + cannibal_target.tallyName)
					await get_tree().create_timer(1).timeout
					await walk_towards(cannibal_target.global_position + Vector3(1, 0, 0), 16, 0)
					
					if ((cannibal_target.global_position + Vector3(1, 0, 0)) - global_position).length() > 0.5:
						return
				show_message.emit("Cannibal used *Tear Open Wide*!")
				await get_tree().create_timer(1).timeout
				$Anim.play("Bite")
				await $Anim.animation_finished
				
				var a = AudioStreamPlayer3D.new()
				cannibal_target.add_child(a)
				a.stream = preload("res://Sounds/cannibal_bite.wav")
				a.play()
				a.finished.connect(a.queue_free)
				
				
				var dmg = {
					true:70,
					false:35
				}[cannibal_target.willingVictim > 0]
				cannibal_target.take_damage(HitDesc.new(self, cannibal_target.global_position + Vector3(0, 0.5, 0), dmg, null))
				await get_tree().create_timer(1).timeout
				
				cannibal_target.willingVictim = 2
				$Anim.play("Idle")
				
				turn_priority = 100
				return
				
		cannibal_target = get_tree().get_nodes_in_group("Tally").pick_random()
		show_message.emit("Cannibal used *Willing Victim*")
		get_tree().create_timer(0.5).timeout.connect($CurseInhale.play)
		await get_tree().create_timer(2).timeout
		$CurseEffect.play()
		show_message.emit(cannibal_target.tallyName + " is unable to walk!")
		cannibal_target.willingVictim = 2
		
		turn_priority = 1
		await get_tree().create_timer(1).timeout
		return
	
	var target = get_tree().get_nodes_in_group("Tally").pick_random() as Node3D
	if target:
		await walk_towards(target.global_position, 4, 1)
		if (global_position - target.global_position).length() < 1:
			show_message.emit(title + " attacks!")
			
			if $Anim.has_animation("Flash"):
				$Anim.play("Flash")
				await $Anim.animation_finished
			#target.take_damage(HitDesc.new(self, self.global_position, 10))
			await get_tree().create_timer(1).timeout
			$Anim.play("Idle")
func walk_towards(target_pos: Vector3, range:int, separation:int):
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
		if d > range + 3:
			continue
		for q in [P.call(-1, 0), P.call(0, -1), P.call(1, 0), P.call(0, 1)]:
			if seen.has(q):
				continue
			seen.push_back(q)
			distanceTo[q] = d + 1
			if !can_occupy(q):
				continue
			next.push_back(q)
			prev[q] = p
	var dest = global_position
	var D = func(p): return abs(separation - (p - target_pos).length())
	
	var dist = D.call(dest)
	for p in prev.keys():
		var d = D.call(p)
		if d < dist:
			dest = p
			dist = d
	while not (distanceTo[dest] <= range):
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


func spin():
	$Spin.play("Spin")

	if timestop < 1:
		$Anim.play("Hurt")
		await $Anim.animation_finished
		$Anim.play("Idle")
signal died
signal took_damage(hitDesc:HitDesc)

var hp = 100
func take_damage(hitDesc:HitDesc):
	if turnTheLightsOff:
		hitDesc.dmg *= 2
	if takenForARide:
		hitDesc.dmg *= 2
	
	took_damage.emit(hitDesc)
	
	$Anim.play("Hurt")
	await $Anim.animation_finished
	
	var extra = hitDesc.dmg - hp
	hp -= hitDesc.dmg
	if hp > 0:
		
		if timestop < 1:
			$Anim.play("Idle")
		return
	die(extra)
func heal(amount:int):
	hp += amount
var alive = true
@onready var world = get_tree().get_first_node_in_group("World")
func die(extra_dmg:int = 0):
	alive = false
	show_message.emit(title + " fell!")
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
	
	match enemyType:
		EnemyType.Ashley:
			await get_tree().create_timer(0.5).timeout
			for e in get_tree().get_nodes_in_group("Enemy"):
				e.heal(extra_dmg)
			show_message.emit("Nearby enemies regained HP!")
		EnemyType.MaryKate:
			
			await get_tree().create_timer(0.5).timeout
			for t in get_tree().get_nodes_in_group("Tally"):
				t.take_damage(HitDesc.new(self, t.global_position, extra_dmg, null))
			show_message.emit("The Tallies took damage!")
	
	queue_free()
	
func get_all_standable_positions() -> Array[Vector3]:
	var seen = [global_position]
	var next = [global_position]
	var result = []
	while len(next) > 0:
		var p = next.pop_front()
		var P = func(x, z) -> Vector3: return p + Vector3(x, 0, z)
		if not can_occupy(p):
			continue
		result.push_back(p)
		for q in [P.call(-1, 0), P.call(0, -1), P.call(1, 0), P.call(0, 1)]:
			if seen.has(q):
				continue
			seen.push_back(q)
			next.push_back(q)
	return result
	
