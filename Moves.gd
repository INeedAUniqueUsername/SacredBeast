extends Node
class MoveInfo:
	var title:String
	var desc:String
	func _init(title: String, desc:String):
		self.title=title
		self.desc=desc

# Joe
var JoeHawley := MoveInfo.new(
	"Joe Hawley",
	"Punches a single enemy directly in front of Joe. When Joe Hawley attacks, no one makes it out alive."
)
var RotaryPark := MoveInfo.new(
	"Rotary Park",
	"Short-range multi-strike attack that targets a single enemy."
)
var AllOfMyFriends := MoveInfo.new(
	"All of my Friends",
	"For the next turn, damage taken is reduced by 20% for each active Tally."
)

# Rob
var JustApathy := MoveInfo.new(
	"Just Apathy",
	"Shoots an arrow that deals between 1 and 100 damage. Might be too much or not enough."
	)
var Greener := MoveInfo.new(
	"Greener",
	"Shoots an arrow that deals more damage based on Rob's remaining walk range. After using this attack, Rob cannot walk until the next turn."
)
var AnotherMinute := MoveInfo.new(
	"Another Minute",
	"Increases a Tally's walk range by 8 tiles for this turn"
)
var Haiku := MoveInfo.new(
	"Haiku",
	"Shoots "
)

# Andrew
var TheWholeWorldAndYou := MoveInfo.new(
	"The Whole World and You",
	"Stops time on a single enemy until the next turn."
)
var GoodDay := MoveInfo.new(
	"Good Day",
	"Restores 20 HP to all Tallies"
)
var TakenForARide := MoveInfo.new(
	"Taken for a Ride",
	"Teleports an enemy to another location"
)

# Zubin
var ColorBeGone := MoveInfo.new(
	"Color Be Gone",
	"Zubin brings down the hammer on an enemy directly in front of him."
)

# Ross
var TheTrap := MoveInfo.new(
	"The Trap",
	"Strikes an enemy with lightning. Nearby enemies take damage too."
)
var RulerOfEverything := MoveInfo.new(
	"Ruler of Everything",
	"Allows the Tallies to take a double turn. The Enemies get a double turn as well."
)
var TurnTheLightsOff := MoveInfo.new(
	"Turn the Lights Off",
	"Damages all enemies. Also increases their attack damage by 50%."
)
