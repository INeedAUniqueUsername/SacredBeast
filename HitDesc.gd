class_name HitDesc
var attacker: Node
var pos: Vector3
var dmg: int
const MoveInfo = preload("res://Moves.gd").MoveInfo
var move:MoveInfo
var announce:bool

var dmgTaken := 0

func _init(attacker:Node, pos:Vector3, dmg: int, move:MoveInfo, announce:bool = true):
	self.attacker = attacker
	self.pos = pos
	self.dmg = dmg
	self.move = move
	self.announce = announce
