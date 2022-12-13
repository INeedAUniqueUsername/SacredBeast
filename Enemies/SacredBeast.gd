extends Node

var actor : Enemy
@onready var world = get_tree().get_first_node_in_group("World") as Battle

func init(actor:Enemy):
	self.actor = actor
	actor.stepTime = 0.25

func begin_battle():
	pass
	
var walkRange = 0
var walkRemaining = 0

var shadow := false

@onready var SacredBeast = load("res://Enemies/SacredBeast.tscn")

func get_shadows():
	return get_tree().get_nodes_in_group("Shadow")
func do_turn():
	
	if shadow:
		var target = get_tree().get_nodes_in_group("Tally").pick_random()
		await actor.walk_towards(target.global_position, 8, 0)
		if target.global_position.distance_to(actor.global_position) < 2:
			var h = HitDesc.new(self, target.global_position, 10, null)
			await target.take_damage(h)
		return
	
	var shadows = get_shadows()
	if len(shadows) == 0:
		var count = min(5, actor.hp / 50 - len(shadows))
		actor.show_message.emit(actor.title + " used *Made of Lies*!")
		await world.wait(1)
		actor.show_message.emit(actor.title + " summoned clones!")
		for i in range(count):
			var p = actor.get_all_standable_positions().pick_random()
			
			var particles = preload("res://SummonParticle.tscn").instantiate()
			world.add_child(particles)
			particles.global_position = p
			await world.wait(0.5)
			
			var beast = SacredBeast.instantiate()
			world.add_child(beast)
			world.register(beast, true)
			
			beast.global_position = p
			
			beast.hp = 50
			beast.get_node("Behavior").shadow = true
			beast.add_to_group("Shadow")
	else:
		actor.show_message.emit(actor.title + " used *Only Truth*!")
		await world.wait(1)
		for s in shadows:
			await s.fall(null, 0, false)
		actor.heal_announce(len(shadows) * 10)
	pass
func take_damage(h:HitDesc, interrupt:bool = false):
	return await actor.std_take_damage(h, interrupt)
	return
	
	var callback = await actor.std_take_damage(h, true)
	
	var handle = func():
		
		await callback.call()
	
	if interrupt:
		return handle
	else:
		await handle.call()
