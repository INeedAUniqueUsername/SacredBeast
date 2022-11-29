extends Resource
class_name EnemyType
@export var title:String
@export_multiline var desc:String
@export var hp_max:int
@export var hp_start:int
func _ready(title:String, desc:String):
	self.title = title
	self.desc = desc
