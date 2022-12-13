extends CheckBox

# Called when the node enters the scene tree for the first time.
func _ready():
	button_pressed = AudioServer.get_bus_volume_db(1) > -100
	pressed.connect(func():
		AudioServer.set_bus_volume_db(1, {
			true:-3,
			false:-999
		}[self.button_pressed])
		)
