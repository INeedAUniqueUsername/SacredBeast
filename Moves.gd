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

var JustApathy := MoveInfo.new(
	"Just Apathy",
	"Shoots an arrow that deals between 1 and 100 damage. Might be too much or not enough."
	)
	
var Greener := MoveInfo.new(
	"Greener",
	"Shoots an arrow that deals more damage from a long distance"
)
var AnotherMinute := MoveInfo.new(
	"Another Minute",
	"Increases a Tally's walk range by 8 tiles for this turn"
)
var Haiku := MoveInfo.new(
	"Haiku",
	"Shoots "
	
)
