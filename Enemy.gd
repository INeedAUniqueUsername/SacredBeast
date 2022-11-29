extends Node3D
class_name Enemy
@export var enemyType: Resource

const Enemies = {
	Ashley = preload("res://EnemyType/Ashley.tres"),
	MaryKate = preload("res://EnemyType/Mary-Kate.tres"),
	Cannibal = preload("res://EnemyType/Cannibal.tres"),
	Crow = preload("res://EnemyType/Crow.tres"),
	Erlking = preload("res://EnemyType/Erlking.tres"),
	Fate = preload("res://EnemyType/Fate.tres"),
	Misery = preload("res://EnemyType/Misery.tres"),
	NoEyedGirl = preload("res://EnemyType/NoEyedGirl.tres")
}

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


@onready var title = enemyType.title
@onready var desc = enemyType.desc
@onready var hp = enemyType.hp_start
@onready var hp_max = enemyType.hp_max



func _ready():
	if $Behavior:
		$Behavior.init(self)
var turnTheLightsOff = false
var takenForARide = false
var waitingForTheDarkness = false


func begin_battle():
	if $Behavior:
		await $Behavior.begin_battle()
func begin_turn(turnTheLightsOff = false):
	takenForARide = false
	shadowOfNobodyThere = false
	self.turnTheLightsOff = turnTheLightsOff
	
	if turnTheLightsOff and waitingForTheDarkness:
		show_message.emit("*Waiting for the Darkness* activated!")
		await get_tree().create_timer(1).timeout
		waitingForTheDarkness = false
		await heal_announce(50)
	turnIndex += 1
	if timestop > 0:
		show_message.emit(title + " is timestopped and cannot act!")
		await get_tree().create_timer(1).timeout
		return
	
	is_turn_active = true
	await do_turn()
	is_turn_active = false

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
func get_active_tallies():
	return get_tree().get_nodes_in_group("Tally")
func teleport(dest:Vector3):
	var tw = get_tree().create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_QUAD)
	tw.tween_property(self, "global_position", dest, 1)
	tw.play()
	await tw.finished
var shadowOfNobodyThere = false
var target: TallyChar = null
func do_turn():
	if $Behavior:
		await $Behavior.do_turn()
		return
	
	var summon_no_eyed_girl = func():
		show_message.emit(title + " summoned a No Eyed Girl!")
		await get_tree().create_timer(0.5).timeout
		
		var pos
		if self.enemyType == Enemies.NoEyedGirl:
			pos = get_all_standable_positions().filter(func(p):
				return p != global_position and p.distance_to(self.global_position) < 5
				).pick_random()
		else:
			pos = target.get_all_standable_positions().filter(func(p):
				return p != target.global_position and p.distance_to(self.global_position) < 5
			).pick_random()
			
		var p = preload("res://SummonParticle.tscn").instantiate()
		world.add_child(p)
		p.global_position = pos
		
		await get_tree().create_timer(0.2).timeout
			
		var r = preload("res://Enemies/NoEyedGirl.tscn").instantiate()
		world.add_child(r)
		world.register(r)
		r.global_position = pos
		
		#world.extra_turns.push_back(r)
		
		await get_tree().create_timer(0.8).timeout
	if enemyType in [Enemies.Ashley, Enemies.MaryKate]:
		
		if not target:
			target = get_tree().get_first_node_in_group("Zubin") as TallyChar
			if not target:
				target = get_active_tallies().pick_random() as TallyChar
				if not target:
					return
		
		if len(get_tree().get_nodes_in_group("NoEyedGirl")) < 7:
			await summon_no_eyed_girl.call()
		if randi()%2 > 5:
			show_message.emit(title + " used *Drew a Mural* on the Tallies")
			await get_tree().create_timer(1).timeout
			var dmg = 10
			var callbacks = []
			for t in get_active_tallies():
				var h = HitDesc.new(self, t.global_position + Vector3.UP/2, dmg, null, false)
				callbacks.push_back(await t.take_damage(h, true))
				t.bleeding = {
					duration = 4,
					dmg = 10,
					source = self
				}
				await get_tree().create_timer(0.2).timeout
			show_message.emit("The Tallies are bleeding!")
			for c in callbacks:
				await c.call()
			await get_tree().create_timer(2).timeout
			return
		
		await walk_towards(target.global_position + Vector3(1, 0, 0), 6, 2)
		if global_position.distance_to(target.global_position) < 4:
			if randi()%2 == 0:
				show_message.emit(title + " used *Key to my Heart* on " + target.tallyName)
				
				get_tree().create_timer(0.5).timeout.connect($KeyToMyHeart.play)
				await get_tree().create_timer(2).timeout
				
				var dmg = 20 + total_damage_taken/5.0
				
				var h = HitDesc.new(self, target.global_position + Vector3.UP/2, dmg, null)
				await target.take_damage(h)
				await get_tree().create_timer(1.5).timeout
				
				await heal_announce(h.dmgTaken / 2)
			else:
				show_message.emit(title + " used *Great Eyes* on " + target.tallyName)
				
				get_tree().create_timer(0.5).timeout.connect($KeyToMyHeart.play)
				await get_tree().create_timer(2).timeout
				target.greatEyes = 2
				
				show_message.emit(target.tallyName + " is mesmerized by *Great Eyes*")
				
				await get_tree().create_timer(1.5).timeout
		return
	elif enemyType == Enemies.NoEyedGirl:
		if not target:
			target = get_active_tallies().pick_random() as TallyChar
			if not target:
				return
		
		await walk_towards(target.global_position, 6, 1)
		
		if global_position.distance_to(target.global_position) > 1:
			return
		
		show_message.emit(title + " used *Chemical Reactions* on " + target.tallyName)
		
		await get_tree().create_timer(1.5).timeout
		

		var h = HitDesc.new(self, target.global_position + Vector3.UP/2, hp/10, null)
		await target.take_damage(h)
		await get_tree().create_timer(1).timeout
		target.hp_max -= h.dmgTaken
		show_message.emit(target.tallyName + " lost " + str(h.dmgTaken) + " Max HP!")
		await get_tree().create_timer(2).timeout
		
		for i in range(2):
			await summon_no_eyed_girl.call()
		
		show_message.emit(title + " disintegrated!")
		await fall(null, 0, false)
		pass
	elif enemyType == Enemies.Cannibal:
		if not (target and is_instance_valid(target)):
			target = get_active_tallies().pick_random()
			if not target:
				return
				
		var inRange = ((target.global_position + Vector3(1, 0, 0)) - global_position).length() <= 0.5
		if target.willingVictim > 0 or inRange:
			
			if not inRange:
				show_message.emit("Cannibal makes her way towards " + target.tallyName)
				await get_tree().create_timer(1).timeout
				await walk_towards(target.global_position + Vector3(1, 0, 0), 16, 0)
				
				if ((target.global_position + Vector3(1, 0, 0)) - global_position).length() > 0.5:
					return
			show_message.emit("Cannibal used *Tear Open Wide* on " + target.tallyName + "!")
			await get_tree().create_timer(1).timeout
			
			
			$Anim.play("Bite")
			await $Anim.animation_finished
			
			playSound(preload("res://Sounds/cannibal_bite.wav"), target)
			var dmg = {
				true:70,
				false:35
			}[target.willingVictim > 0]
			await target.take_damage(HitDesc.new(self, target.global_position + Vector3.UP/2, dmg, null))
			await get_tree().create_timer(1).timeout
			
			if is_instance_valid(target):
				target.willingVictim = 2
			$Anim.play("Idle")
			
			turn_priority = 100
			return
			

		if !turnTheLightsOff and !waitingForTheDarkness and randi()%2 == 0:
			show_message.emit(title + " used *Waiting for the Darkness*!")
			waitingForTheDarkness = true
			await get_tree().create_timer(2).timeout
			show_message.emit(title + " will heal if the lights are off next turn")
			await get_tree().create_timer(1).timeout
			return
			
		show_message.emit("Cannibal used *Willing Victim* on " + target.tallyName)
		get_tree().create_timer(0.5).timeout.connect($CurseInhale.play)
		await get_tree().create_timer(2).timeout
		$CurseEffect.play()
		show_message.emit(target.tallyName + " is unable to walk!")
		target.willingVictim = 2
		
		turn_priority = 1
		await get_tree().create_timer(1).timeout
		return
	elif enemyType == Enemies.Erlking:
		var useShadow = func():
			show_message.emit(title + " used *Shadow of Nobody There*!")
			await get_tree().create_timer(1.5).timeout
			shadowOfNobodyThere = true
			show_message.emit(title + " prepares to teleport away!")
			await get_tree().create_timer(1).timeout
			
		if turnIndex%2 == 1:
			await useShadow.call()
			
		if not (target and is_instance_valid(target)):
			target = get_active_tallies().pick_random() as TallyChar
			if not target:
				return
		var tar = target
		var slashAttack = func():
			if tar.has_node("LeavesBrokeAbove"):
				tar.remove_child(get_node("LeavesBrokeAbove"))
				show_message.emit(title + " used *Fell Below* on " + tar.tallyName + "!")
				await get_tree().create_timer(1).timeout
				await tar.take_damage(HitDesc.new(self, tar.global_position + Vector3.UP/2, 40, null, false))
				await get_tree().create_timer(1).timeout
				return
			show_message.emit(title + " used *Broke Above* on " + tar.tallyName + "!")
			await get_tree().create_timer(1).timeout
			
			for i in range(4):
				if tar.hp < 1:
					break
				await get_tree().create_timer(0.1).timeout
				await tar.take_damage(HitDesc.new(self, tar.global_position + Vector3.UP/2, 10, null, false))
			var n = Node.new()
			n.name = "LeavesBrokeAbove"
			tar.add_child(n)
			await get_tree().create_timer(1).timeout
		
		if turnTheLightsOff:
			var dest = global_position
			var destDist = global_position.distance_squared_to(target.global_position)
			var positions = get_all_standable_positions()
			for p in positions:
				var pDist = p.distance_squared_to(target.global_position)
				if pDist < destDist:
					dest = p
					destDist = pDist
			if dest.distance_to(target.global_position) < 2.5:
				show_message.emit(title + " used *Darker Terrors*!")
				await get_tree().create_timer(1).timeout
				await teleport(dest)
				await get_tree().create_timer(0.5).timeout
				await slashAttack.call()
				return
		await walk_towards(target.global_position, 4, 1)
		if global_position.distance_to(target.global_position) < 2.5:
			await slashAttack.call()
		return
	elif enemyType == Enemies.Misery:
		
		if not (target and is_instance_valid(target)):
			for t in ["Andrew", "Ross", "Rob", "Joe", "Zubin"]:
				target = get_tree().get_first_node_in_group(t)
				if target:
					break
			if not target:
				return
		if randi()%2 == 0:
			show_message.emit(title + " used *Faith in Above* on " + target.tallyName + "!")
			await get_tree().create_timer(2).timeout
			
			var roll = 1 + randi()%20
			show_message.emit(title + " rolled " + str(roll))
			await get_tree().create_timer(1).timeout
			var d = HitDesc.new(self, target.global_position, roll * target.hp / 20, null)
			await target.take_damage(d)
			await get_tree().create_timer(1).timeout
			return
			
		if turnTheLightsOff:
			show_message.emit(title + " is unable to act while the lights are off!")
			await get_tree().create_timer(2).timeout
			return
		show_message.emit(title + " used *Surrender Their Chemistry Books* on " + target.tallyName + "!")
		await get_tree().create_timer(2).timeout
		
		target.surrenderTheirChemistryBooks = 2
		show_message.emit(target.tallyName + " is unable to use magic!")
		await get_tree().create_timer(1).timeout
		return
	
	
	return
	
	target = get_tree().get_nodes_in_group("Tally").pick_random() as Node3D
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
var stepTime:float = 0.3
func walk_towards(target_pos: Vector3, range:int, separation:int, onStep = null):
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
		t.tween_property(self, "global_position", step, stepTime)
		t.play()
		await t.finished
		if onStep:
			onStep.call()
	return len(path)
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
signal fell
var total_damage_taken = 0

func take_damage(h:HitDesc, interrupt:bool = false):
	if has_node("Behavior"):
		return await $Behavior.take_damage(h, interrupt)
	else:
		return await std_take_damage(h, interrupt)









func std_take_damage(h:HitDesc, interrupt:bool = false):
	
	h.dmgTaken = h.dmg
	if turnTheLightsOff:
		h.dmgTaken *= 2
	if takenForARide:
		h.dmgTaken *= 2
	var msg = ""
	if shadowOfNobodyThere and not (takenForARide or timestop > 0):	
		msg += "*Shadow of Nobody There* activated! " + title + " teleported away! "
		var dest = Helper.get_max(get_all_standable_positions(),
		(func(p):
			return p.distance_to(h.attacker.global_position)
		), 10)
		if dest:
			teleport(dest)
		shadowOfNobodyThere = false
	var extra = h.dmgTaken - hp
	h.dmgTaken = min(h.dmgTaken, hp)
	hp -= h.dmgTaken
	total_damage_taken += h.dmgTaken
	if h.dmgTaken > 0:
		var at = preload("res://ActionText.tscn").instantiate()
		add_child(at)
		at.global_position = h.pos + Vector3(0, 0.5, 0.5)
		at.get_node("Label3D").text = h.get_action_text()
	
	var au = AudioStreamPlayer3D.new()
	au.stream = preload("res://Sounds/punch_hit.wav")
	add_child(au)
	au.play()
	au.finished.connect(au.queue_free)
	
	if timestop < 1:
		(func():
			$Anim.play("Hurt")
			await $Anim.animation_finished
			$Anim.play("Idle")
		).call()
	var handle_damage = func():
		msg += title + " took " + str(h.dmgTaken) + " damage! "
		if h.announce:
			show_message.emit(msg)
			await get_tree().create_timer(1).timeout
		if hp == 0:
			await fall(h, extra)
	if interrupt:
		return handle_damage
	await handle_damage.call()












func heal(amount:int):
	hp += amount
	return amount
func heal_announce(amount:int):
	
	show_message.emit(title + " healed " + str(amount) + " HP!")
	add_child(preload("res://HealParticle.tscn").instantiate())
	playSound(preload("res://Sounds/staff_heal.wav"))
	heal(amount)
	await get_tree().create_timer(1.5).timeout
var alive = true
@onready var world = get_tree().get_first_node_in_group("World")
func fall(h:HitDesc, extra_dmg:int = 0, announce:bool = true):
	alive = false
	if announce:
		show_message.emit(title + " fell!")
	
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
	
	if enemyType == Enemies.Ashley:
		await get_tree().create_timer(0.5).timeout
		show_message.emit("Ashley activated *And Let The Love Shine Through*!")
		await get_tree().create_timer(1.5).timeout
		var any = false
		var enemies = get_tree().get_nodes_in_group("Enemy")
		extra_dmg /= len(enemies)
		for e in enemies:
			any = true
			await get_tree().create_timer(0.1).timeout
			e.heal(extra_dmg)
			e.add_child(preload("res://HealParticle.tscn").instantiate())
		playSound(preload("res://Sounds/staff_heal.wav"), get_parent(), func(a):
			a.global_position = global_position)
		show_message.emit("Nearby enemies regained HP!")		
	elif enemyType == Enemies.MaryKate:
		await get_tree().create_timer(0.5).timeout
		show_message.emit("Mary-Kate activated *How It's Gone and It's Gone and It's Gone*!")
		await get_tree().create_timer(1.5).timeout
		var tallies = get_tree().get_nodes_in_group("Tally")
		extra_dmg /= len(tallies)
		var callbacks = []
		for t in tallies:
			await get_tree().create_timer(0.1).timeout
			callbacks.push_back(await t.take_damage(HitDesc.new(self, t.global_position, extra_dmg, null), true))
			
		show_message.emit("The Tallies took damage!")
		await get_tree().create_timer(2).timeout
		for c in callbacks:
			await c.call()
	fell.emit()
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
	
