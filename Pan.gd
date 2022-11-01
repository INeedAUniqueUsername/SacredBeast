extends Control
	
signal clicked
signal dragged(delta: Vector2)
var hover = false
var pressed = false
func _ready():
	mouse_entered.connect(func():
		hover = true
	)
	mouse_exited.connect(func():
		hover = false
	)
	gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton:

			var mb = ev as InputEventMouseButton
			if !mb.pressed and pressed:
				self.clicked.emit()
			self.pressed = mb.pressed
		if ev is InputEventMouseMotion:
			var mo = ev as InputEventMouseMotion
			if pressed and hover:
				dragged.emit(mo.velocity)
		)
