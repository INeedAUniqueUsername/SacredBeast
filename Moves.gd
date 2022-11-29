extends Node
class MoveInfo:
	var title:String
	var desc:String
	func _init(title: String, desc:String):
		self.title=title
		self.desc=desc
	func print():
		print("- " + title + ": " + desc)
func print_all():
	for m in [JoeHawley, AristotlesDenial, AllOfMyFriends, SpringAndAStorm]:
		m.print()
	print()
	for m in [JustApathy, Greener, AnotherMinute, GardenOfEden]:
		m.print()
	print()
	for m in [TheWholeWorldAndYou, TakenForARide, Misfortune, GoodDay]:
		m.print()
	print()
	for m in [ColorBeGone, RotaryPark, WhiteBall, SeaCucumber]:
		m.print()
	print()
	for m in [TheTrap, RulerOfEverything, TurnTheLightsOff, HotRodDuncan]:
		m.print()
# Joe
var JoeHawley := MoveInfo.new("Joe Hawley Attacks",
	"Punches a single enemy directly in front of Joe. Deals more damage when used repeatedly until the next enemy turn. When Joe Hawley attacks, no one makes it out alive."
)
var AristotlesDenial := MoveInfo.new("Aristotle's Denial",
	"Tallies build up Rage from taking damage. If Joe takes damage during the next Enemy Turn, the attacker takes damage based on the Rage of all active Tallies."
)
var AllOfMyFriends := MoveInfo.new("All of my Friends",
	"Joe gains defense for each active Tally, and gains attack for each fallen Tally."
)
var SpringAndAStorm := MoveInfo.new("Spring and a Storm",
	"Creates rain which lasts until the next Tally Turn. During the rain, Tallies are healed based on damage dealt to enemies."
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
	"Restores all HP to a Tally"
)
# Andrew
var TheWholeWorldAndYou := MoveInfo.new("The Whole World and You",
	"Stops time on an enemy until the next turn."
)
var TakenForARide := MoveInfo.new("Taken for a Ride",
	"Teleports an enemy to another location. The enemy takes double damage until the next turn."
)
var Misfortune := MoveInfo.new("Misfortune",
	"Curses an enemy with a terrible fate. On the next Tally turn, the enemy takes damage equal to Andrew's HP. If used again during Part II, the damage is doubled."
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
	"Smashes the ground with the hammer, sending a wave of columns across the ground."
)
var SeaCucumber := MoveInfo.new("Sea Cucumber",
	"Restores HP to a Tally. +10 HP restored for each turn that passes since the last use."
)
# Ross
var TheTrap := MoveInfo.new("The Trap",
	"Strikes an enemy with lightning. Also hits nearby enemies. Deals more damage if Ross is close to the enemy."
)
var RulerOfEverything := MoveInfo.new("Ruler of Everything",
	"Adds a Part II to the current turn. The enemies get a Part II as well."
)
var TurnTheLightsOff := MoveInfo.new("Turn the Lights Off",
	"After this turn, the lights turn off for the next two turns. All damage dealt and taken is doubled while the lights are off."
)
var HotRodDuncan := MoveInfo.new("The Apologue of Hot Rod Duncan",
	"Gives a Tally two more actions for this turn. Can only be used once per Tally Turn."
)

# Casey
var LifeInACube := MoveInfo.new("Life in a Cube",
	"")
var SinceIDontHaveYou := MoveInfo.new("Since I Don't Have You",
	"")
# Bora
var MoonWaltz := MoveInfo.new("Moon Waltz",
	"")
var Pluto := MoveInfo.new("134340 Pluto",
	"")
var InsideTheMindOfSimon := MoveInfo.new("Inside The Mind Of Simon",
	"")
