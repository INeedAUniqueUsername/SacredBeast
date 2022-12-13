@tool
extends Node

@export var color:int:
	set(i):
		if not is_inside_tree():
			await tree_entered
		get_parent().get_node("Sprite").modulate = [Color(1, 0.5, 0.5), Color(1, 0.9, 0.5), Color(0.5, 1, 0.5), Color(0.25, 0.5, 1), Color(0.75, 0.75, 0.75)][i]
		color = i
var actor:Enemy
var world: Battle
func init(actor:Enemy):
	self.actor = actor
	self.world = actor.world
	actor.title = ["Red", "Yellow", "Green", "Blue", "Grey"][color] + " " + actor.title
	pass
func begin_battle():
	pass
	
@onready var sprite := get_parent().get_node("Sprite") as Sprite3D
var spiritGame = false:
	set(s):
		
		if s:
			sprite.frame = 2
		else:
			sprite.frame = 0
		spiritGame = s
		
var summons = 0
var chanted = false
func do_turn():
	var bananaMan = get_tree().get_first_node_in_group("BananaMan") as Enemy
	if not bananaMan:
		var birds = get_tree().get_nodes_in_group("Songbird")
		
		world.showMessage(actor.title + " used *Chant*")
		await world.wait(1)

		var pos = Helper.get_min(actor.get_all_standable_positions(), func(p):
			return p.length_squared()
			)
		
		var p = preload("res://SummonParticle.tscn").instantiate()
		world.add_child(p)
		p.global_position = pos
		await world.wait(0.2)
		
				
		


			
		bananaMan = preload("res://Enemies/BananaMan.tscn").instantiate()
		world.add_child(bananaMan)
		bananaMan.global_position = pos
		world.register(bananaMan, true)
		await world.wait(0.3)
		
		if summons == 0:
			world.showMessage("Banana Man was summoned!")
		else:
			world.showMessage("Banana Man was resurrected!")
		get_tree().get_nodes_in_group("Songbird").map(func(b):
			b.get_node("Behavior").summons += 1
			)
		
		await world.wait(1.5)
		#if len(birds) == 5:	
			#world.showMessage(actor.title + " used *Chant*")
			#chanted = true
			#await world.wait(1)
			#if birds.all(func(b): return b.get_node("Behavior").chanted):
			#	world.showMessage("Banana Man was summoned")
			#	await world.wait(1)
			#	
			#	var pos = Helper.get_min(actor.get_all_standable_positions(), func(p):
			#		return p.length_squared()
			#		)
			#	
			#	bananaMan = preload("res://Enemies/BananaMan.tscn").instantiate()
			#	world.add_child(bananaMan)
			#	bananaMan.global_position = pos
		return
	world.showMessage(actor.title + " used *Chant*")
	await world.wait(1)
	if bananaMan.timestop > 0:
		bananaMan.timestop -= 1
		world.showMessage(bananaMan.title + " is no longer timestopped!")
	else:
		bananaMan.get_node("Behavior").songbirdChant += 1
		world.showMessage(bananaMan.title + " gained walk range!")
	await world.wait(1)
	
	if bananaMan.get_node("Behavior").spiritGame:
		var delta = await actor.heal_announce(5, false)
		world.showMessage(actor.title + " restored " + str(delta) + " HP!")
	
func take_damage(h:HitDesc, interrupt:bool = false):
	if h.attacker.tally != color:
		h.dmg = 0
	var callback = await actor.std_take_damage(h, true)
	
	var ourCallback = func():
		callback.call()
		if h.attacker.tally != color:
			world.showMessage(actor.title + " took no damage!")
			await world.wait(1)
		else:
			var bananaMan = get_tree().get_first_node_in_group("BananaMan")
			if bananaMan:
				bananaMan = bananaMan.get_node("Behavior")
				await bananaMan.retaliate(h.attacker)
	if interrupt:
		return ourCallback
	ourCallback.call()
