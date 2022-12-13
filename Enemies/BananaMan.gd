extends Node

var actor : Enemy
@onready var world = get_tree().get_first_node_in_group("World") as Battle

func init(actor:Enemy):
	self.actor = actor
	actor.stepTime = 0.25
	world.turn_the_lights_off_ended.connect(func():
		self.spiritGame = false
		)
	pass

func begin_battle():
	var f = world.focus(actor)
	await use_banana_tree()
	f.queue_free()
func use_banana_tree():
	world.showMessage("Banana Man used *Banana Tree*")
	await world.wait(1)
	
	var places = actor.get_all_standable_positions()
	
	for i in range(16):
		var p = places.pick_random()
		places.erase(p)
		
		var b = preload("res://Banana.tscn").instantiate()
		world.add_child(b)
		b.global_position = p
		await world.wait(0.05)
	
	world.showMessage("Bananas have appeared!")
	await world.wait(1)
func use_spirit_game():
	spiritGame = true
	
	world.showMessage("Banana Man used *Spirit Game*")
	await world.wait(1)
	
	world.turnTheLightsOff = 4
	world.set_background_brightness(0)
	get_tree().create_timer(1).timeout.connect(func():
		world.flameBorder = true
		)
	world.turn_the_lights_off_ended.connect(func():
		world.flameBorder = false
		)
	
	for b in get_tree().get_nodes_in_group("Songbird"):
		b.get_node("Behavior").spiritGame = true
	
	world.showMessage("Spirit Game has started!")
func on_step():
	if not spiritGame:
		return


	for other in actor.get_node("Hitbox").get_overlapping_areas():
		if other.is_in_group("Fire"):
			return

	var f = preload("res://FlameTile.tscn").instantiate()
	world.add_child(f)
	f.global_position = actor.global_position
	world.turn_the_lights_off_ended.connect(f.get_node("Anim").play.bind("Disappear"))

var spiritGame = false
var songbirdChant = 0
var bananas = 0

var walkRange = 0
var walkRemaining = 0

func do_turn():
	walkRange = 4 + songbirdChant * 4
	walkRemaining = walkRange
	songbirdChant = 0
	var nearbyBananas = get_tree().get_nodes_in_group("Banana")
	if len(nearbyBananas) < 8:
		await use_banana_tree()
		nearbyBananas = get_tree().get_nodes_in_group("Banana")
	world.showMessage(actor.title + " is collecting bananas!")
	await world.wait(1.5)
	while walkRemaining > 0:
		nearbyBananas = nearbyBananas.filter(func(b): return is_instance_valid(b))
		var nearest = Helper.get_min(nearbyBananas, func(b):
			return b.global_position.distance_to(actor.global_position)
		)
		if nearest == null:
			break
		nearbyBananas.erase(nearest)
		walkRemaining -= await actor.walk_towards(nearest.global_position, walkRemaining, 0, on_step)
		await take_banana()
	world.showMessage(actor.title + " has " + str(bananas) + " bananas!")
	await world.wait(2)
	if not spiritGame:
		if bananas >= 8:
			await use_spirit_game()
	else:
		if bananas >= 8:
			world.turnTheLightsOff = 4
			world.set_background_brightness(0)
			
			world.showMessage("*Spirit Game* continues!")
			await world.wait(2)
	if spiritGame:
		await actor.heal_announce(bananas * 5)
		bananas = 0
		await world.wait(1.5)
	return
	
	var markers = get_tree().get_nodes_in_group("Waypoint")
	var index = Helper.get_min_index(markers, func(w):
		return w.global_position.distance_to(actor.global_position)
		)
	var walkRemaining = 12
	while walkRemaining > 0:
		var next = markers[(index + 1)%len(markers)] as Node3D
		var walked = await actor.walk_towards(next.global_position, walkRemaining, 0)
		walkRemaining -= walked
		index += 1
func take_banana():
	for other in actor.get_node("Hitbox").get_overlapping_areas():
		if other.is_in_group("Banana"):
			other.get_parent().get_node("Anim").play("Disappear")
			world.showMessage(actor.title + " took a Banana!")
			bananas += 1
			await world.wait(0.5)
var busy = false
func retaliate(t:TallyChar):
	if actor.timestop > 0 or busy or not spiritGame:
		return
	busy = true
	var f = world.focus(actor)
	await world.wait(1)
	world.showMessage("Banana Man retaliated!")
	var p = t.global_position
	await actor.walk_towards(t.global_position, walkRange, 1, on_step)
	if p.distance_to(actor.global_position) <= 1:
		world.showMessage("Banana Man used *You Do Not Banana All The Time* on " + t.tallyName)
		await world.wait(1)
		await t.take_damage(HitDesc.new(actor, p, 20, null, true))
		await world.wait(1)
	f.queue_free()
	busy = false
func take_damage(h:HitDesc, interrupt:bool = false):
	var callback = await actor.std_take_damage(h, true)
	
	var handle = func():
		if actor.hp > 0:

			if h.announce:
				world.showMessage("Banana Man took " + str(h.dmg) + " damage!")
				h.announce = false
			retaliate(h.attacker)
		
		callback.call()
	
	if interrupt:
		return handle
	else:
		await handle.call()
