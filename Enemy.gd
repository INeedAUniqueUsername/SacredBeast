extends Node3D


signal took_damage(hitDesc)
func take_damage(hitDesc):
	took_damage.emit(hitDesc)
	pass
