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


var max_hp:int = 200
var hp:int = 200
func _ready():
	pass

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

func playSound(stream:AudioStream, parent:Node3D = null, action = null):
	var a = AudioStreamPlayer3D.new()
	if not parent:
		parent = self
	a.stream = stream
	parent.add_child(a)
	if action is Callable:
		action.call(a)
	a.play()
	a.finished.connect(a.queue_free)
func do_turn():
	if enemyType in [EnemyType.Ashley, EnemyType.MaryKate]:
		var target : TallyChar = get_tree().get_first_node_in_group("Zubin")
		if not target:
			target = get_tree().get_nodes_in_group("Tally").pick_random()
		if not target:
			return
		await walk_towards(target.global_position + Vector3(1, 0, 0), 6, 2)
		
		
		if global_position.distance_to(target.global_position) < 4:
			show_message.emit(title + " used *Key to my Heart* on " + target.tallyName)
			
			get_tree().create_timer(1).timeout.connect($KeyToMyHeart.play)
			await get_tree().create_timer(2.5).timeout
			
			var dmg = 20 + total_damage_taken/5.0
			
			var h = HitDesc.new(self, target.global_position + Vector3.UP/2, dmg, null)
			await target.take_damage(h)
			await get_tree().create_timer(1.5).timeout
			
			playSound(preload("res://Sounds/staff_heal.wav"))
			heal(h.dmgTaken)
			add_child(preload("res://HealParticle.tscn").instantiate())
			show_message.emit(title + " healed " + str(h.dmgTaken) + " HP!")
			
			await get_tree().create_timer(2).timeout
		return
		
	if enemyType == EnemyType.Cannibal:
		if cannibal_target and is_instance_valid(cannibal_target):
			var inRange = ((cannibal_target.global_position + Vector3(1, 0, 0)) - global_position).length() <= 0.5
			if cannibal_target.willingVictim > 0 or inRange:
				
				if not inRange:
					show_message.emit("Cannibal makes her way towards " + cannibal_target.tallyName)
					await get_tree().create_timer(1).timeout
					await walk_towards(cannibal_target.global_position + Vector3(1, 0, 0), 16, 0)
					
					if ((cannibal_target.global_position + Vector3(1, 0, 0)) - global_position).length() > 0.5:
						return
				show_message.emit("Cannibal used *Tear Open Wide* on " + cannibal_target.tallyName + "!")
				await get_tree().create_timer(1).timeout
				$Anim.play("Bite")
				await $Anim.animation_finished
				
				playSound(preload("res://Sounds/cannibal_bite.wav"), cannibal_target)
				
				
				var dmg = {
					true:70,
					false:35
				}[cannibal_target.willingVictim > 0]
				await cannibal_target.take_damage(HitDesc.new(self, cannibal_target.global_position + Vector3.UP/2, dmg, null))
				await get_tree().create_timer(1).timeout
				
				if is_instance_valid(cannibal_target):
					cannibal_target.willingVictim = 2
				$Anim.play("Idle")
				
				turn_priority = 100
				return
				
		cannibal_target = get_tree().get_nodes_in_group("Tally").pick_random()
		if not cannibal_target:
			return
		show_message.emit("Cannibal used *Willing Victim* on " + cannibal_target.tallyName)
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
var total_damage_taken = 0
func take_damage(h:HitDesc):
	h.dmgTaken = h.dmg
	if turnTheLightsOff:
		h.dmgTaken *= 2
	if takenForARide:
		h.dmgTaken *= 2
	
	var extra = h.dmgTaken - hp
	h.dmgTaken = min(h.dmgTaken, hp)
	
	hp -= h.dmgTaken
	total_damage_taken += h.dmgTaken
	

	var at = preload("res://ActionText.tscn").instantiate()
	add_child(at)
	at.global_position = h.pos + Vector3(0, 0.5, 0.5)
	var st = str(h.dmgTaken)
	if h.move == Moves.JoeHawley:
		st = "JOE HAWLEY!"
	elif h.move == Moves.JustApathy:
		st = "Apathy!"
	at.get_node("Label3D").text = st
	
	var au = AudioStreamPlayer3D.new()
	au.stream = preload("res://Sounds/punch_hit.wav")
	add_child(au)
	au.play()
	au.finished.connect(au.queue_free)
	
	if h.announce:
		show_message.emit(title + " took " + str(h.dmgTaken) + " damage!")
	
	$Anim.play("Hurt")
	await $Anim.animation_finished
	
	if hp > 0:
		
		if timestop < 1:
			$Anim.play("Idle")
		return
	await die(extra)
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
			var any = false
			for e in get_tree().get_nodes_in_group("Enemy"):
				any = true
				await get_tree().create_timer(0.1).timeout
				e.heal(extra_dmg)
				e.add_child(preload("res://HealParticle.tscn").instantiate())
			
			playSound(preload("res://Sounds/staff_heal.wav"), get_parent(), func(a):
				a.global_position = global_position)
			show_message.emit("Nearby enemies regained HP!")
		EnemyType.MaryKate:
			
			await get_tree().create_timer(0.5).timeout
			for t in get_tree().get_nodes_in_group("Tally"):
				await get_tree().create_timer(0.1).timeout
				await t.take_damage(HitDesc.new(self, t.global_position, extra_dmg, null))
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
	
