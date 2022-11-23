extends Resource
class_name EnemyType
@export var title:String
@export_multiline var desc:String
func _init(title:String, desc:String):
	self.title = title
	self.desc = desc
