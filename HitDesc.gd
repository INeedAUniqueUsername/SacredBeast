class_name HitDesc
var attacker: Node
var pos: Vector3
var dmg: int
const MoveInfo = preload("res://Moves.gd").MoveInfo
var move:MoveInfo
func _init(attacker:Node, pos:Vector3, dmg: int, move:MoveInfo):
	self.attacker = attacker
	self.pos = pos
	self.dmg = dmg
	self.move = move
