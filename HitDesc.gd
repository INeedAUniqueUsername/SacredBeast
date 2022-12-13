class_name HitDesc
var attacker: Node
var pos: Vector3
var dmg: int
const MoveInfo = preload("res://Moves.gd").MoveInfo
var move:MoveInfo
var announce:bool = true

var dmgTaken := 0
var grapple = false
func _init(attacker:Node, pos:Vector3, dmg: int, move:MoveInfo, announce:bool = true):
	self.attacker = attacker
	self.pos = pos
	self.dmg = dmg
	self.move = move
	self.announce = announce

func get_action_text() -> String:
	
	if move == Moves.JoeHawley:
		return "JOE HAWLEY!"
	elif move == Moves.JustApathy:
		return "Apathy!"
	return str(dmgTaken)
