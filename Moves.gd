extends Node
class MoveInfo:
	var title:String
	var desc:String
	func _init(title: String, desc:String):
		self.title=title
		self.desc=desc

# Joe
var JoeHawley := MoveInfo.new("Joe Hawley",
	"Punches a single enemy directly in front of Joe. Deals more damage when used repeatedly until the next enemy turn. When Joe Hawley attacks, no one makes it out alive."
)
var AristotlesDenial := MoveInfo.new("Aristotle's Denial",
	"If Joe falls during the next Enemy Turn, all enemies take damage based on the total damage taken by active Tallies (increased if *All of my Friends* is active)"
)
var AllOfMyFriends := MoveInfo.new("All of my Friends",
	"During the next Enemy Turn, reduces damage taken by 20% for each fallen Tally."
)
var SpringAndAStorm := MoveInfo.new("Spring and a Storm",
	"Until the next Tally Turn, Tallies are healed based on damage dealt to enemies."
)
# Rob
var JustApathy := MoveInfo.new("Just Apathy",
	"Shoots an arrow that deals between 1 and 100 damage. Might be too much or not enough."
)
var Greener := MoveInfo.new("Greener",
	"Shoots an arrow that deals more damage based on Rob's remaining walk range. After using this attack, Rob cannot walk until the next turn."
)
var AnotherMinute := MoveInfo.new("Another Minute",
	"Increases a Tally's walk range by 8 tiles for this turn"
)
var GardenOfEden := MoveInfo.new("Garden of Eden",
	"Restores a Tally to full health"
)
# Andrew
var TheWholeWorldAndYou := MoveInfo.new("The Whole World and You",
	"Stops time on an enemy until the next turn."
)
var TakenForARide := MoveInfo.new("Taken for a Ride",
	"Teleports an enemy to another location. The enemy takes double damage until the next turn."
)
var Misfortune := MoveInfo.new("Misfortune",
	"Curses an enemy with a terrible fate. On the next Tally turn, the enemy takes damage equal to 50% of Andrew's HP (100% if used twice)."
)
var GoodDay := MoveInfo.new("Good Day",
	"Restores 20 HP to all Tallies"
)


# Zubin
var ColorBeGone := MoveInfo.new("Color Be Gone",
	"Zubin swings the hammer at an enemy directly in front of him."
)
var RotaryPark := MoveInfo.new("Rotary Park",
	"Zubin spins around, dealing damage to surrounding enemies."
)
var WhiteBall := MoveInfo.new("White Ball",
	"Smashes the ground with the hammer, sending a shockwave across the ground"
)
var SeaCucumber := MoveInfo.new("Sea Cucumber",
	""
)

# Ross
var TheTrap := MoveInfo.new("The Trap",
	"Strikes an enemy with lightning. Also hits nearby enemies."
)
var RulerOfEverything := MoveInfo.new("Ruler of Everything",
	"Adds a Part II to the current turn. The enemies get a Part II as well."
)
var TurnTheLightsOff := MoveInfo.new("Turn the Lights Off",
	"The lights will be off at the end of the turn for the next two turns. All damage is doubled while the lights are off."
)
var HotRodDuncan := MoveInfo.new("The Apologue of Hot Rod Duncan",
	""
)
