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
	"Punches a single enemy directly in front of Joe. Deals more damage when used repeatedly until the next enemy turn. When Joe Hawley attacks, no one makes it out alive."
)
var RotaryPark := MoveInfo.new(
	"Rotary Park",
	"Spins around, dealing damage to surrounding enemies."
)
var AllOfMyFriends := MoveInfo.new(
	"All of my Friends",
	"For the next turn, Joe takes 20% less damage for each active Tally and deals 20% more damage for each fallen Tally."
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
var GardenOfEden := MoveInfo.new(
	"Garden of Eden",
	"TO DO"
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
	"Teleports an enemy to another location. The enemy takes double damage until the next turn."
)

# Zubin
var ColorBeGone := MoveInfo.new(
	"Color Be Gone",
	"Zubin swings the hammer at an enemy directly in front of him."
)

# Ross
var TheTrap := MoveInfo.new(
	"The Trap",
	"Strikes an enemy with lightning. Also hits nearby enemies."
)
var RulerOfEverything := MoveInfo.new(
	"Ruler of Everything",
	"Allows the Tallies to take a double turn. The Enemies get a double turn as well."
)
var TurnTheLightsOff := MoveInfo.new(
	"Turn the Lights Off",
	"The lights will be off at the end of the turn for the next two turns. All damage is doubled while the lights are off."
)

