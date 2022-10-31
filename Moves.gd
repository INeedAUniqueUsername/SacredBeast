extends Node
class MoveInfo:
	var title:String
	var desc:String
	func _init(title: String, desc:String):
		self.title=title
		self.desc=desc

var JoeHawley := MoveInfo.new(
	"Joe Hawley",
	"Short-range single-strike attack that hits a single enemy. When Joe Hawley attacks, no one makes it out alive."
)
var RotaryPark := MoveInfo.new(
	"Rotary Park",
	"Short-range multi-strike attack that targets a single enemy."
)
var HymnForAScarecrow := MoveInfo.new(
	"Hymn for a Scarecrow",
	"Hymn for a Scarecrow"
	)
