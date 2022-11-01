var attacker: Node
var pos: Vector3
var damage_hp: int
func _init(attacker:Node, pos:Vector3, damage_hp:int):
	self.attacker = attacker
	self.pos = pos
	self.damage_hp = damage_hp
