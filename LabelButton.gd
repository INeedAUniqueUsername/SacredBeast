extends Label
class_name LabelButton

@export var clickable : bool = true:
	set(b):
		clickable = b
		updateTexture()
	get:
		return clickable
var texture : Texture:
	set(t):
		$NinePatchRect.texture = t
	get:
		return $NinePatchRect.texture
@onready var idle = $NinePatchRect.texture
const yellow = preload("res://YellowRect.png")
const orange = preload("res://OrangeRect.png")
const gray = preload("res://LightGrayRect.png")

var hover := false
var pressed := false
signal clicked
func updateTexture():
	if clickable:
		if hover:
			texture = {true:orange, false:yellow}[pressed]
			return
	
	texture = { true:idle, false:gray }[clickable]
func _ready():
	mouse_entered.connect(func():
		hover = true
		updateTexture()
		)
	mouse_exited.connect(func():
		hover = false
		updateTexture()
		)
	gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton:
			var mb = ev as InputEventMouseButton
			if !mb.pressed and pressed and hover and clickable:
				self.clicked.emit()
			self.pressed = mb.pressed
			updateTexture()
		)
