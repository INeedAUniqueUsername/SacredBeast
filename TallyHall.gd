extends Node

const MoveInfo = preload("res://Moves.gd").MoveInfo
class TallyInfo:
	var title:String
	var desc:String
	var move_list:Array[MoveInfo]
	func _init(title:String, desc:String, move_list:Array[MoveInfo]):
		self.title = title
		self.desc = desc
		self.move_list = move_list

var Joe := TallyInfo.new("Joe",
	"Class: Songfighter\nKnown for his fabled attack, this singer can act twice per turn.",
	[Moves.JoeHawley, Moves.AristotlesDenial, Moves.AllOfMyFriends, Moves.SpringAndAStorm]
	)
var Rob := TallyInfo.new("Rob",
	"Class: Guitarcher\nThis suave fellow happens to be a skilled archer. His sharp arrows are known to break hearts.",
	[Moves.JustApathy, Moves.Greener, Moves.AnotherMinute, Moves.GardenOfEden]
	)
var Andrew := TallyInfo.new("Andrew",
	"Class: Keybard\nThis keyboardist supports the party with the power of whimsical magic.",
	[Moves.TheWholeWorldAndYou, Moves.TakenForARide, Moves.Misfortune, Moves.GoodDay]
	)
var Zubin := TallyInfo.new("Zubin",
	"Class: Basskeeper\nHe wields a hammer and specializes in slaying the toughest of enemies.",
	[Moves.ColorBeGone, Moves.RotaryPark, Moves.WhiteBall, Moves.SeaCucumber]
	)
var Ross := TallyInfo.new("Ross",
	"Class: Rhythmagician\nThis drummer can use musical magic to switch up the rhythm of battle.",
	[Moves.TheTrap, Moves.TurnTheLightsOff, Moves.RulerOfEverything, Moves.HotRodDuncan]
	)
var TallyHall := [Joe, Rob, Andrew, Zubin, Ross]
