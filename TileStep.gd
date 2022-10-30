extends Node3D

signal clicked
var parent : Node3D
# Called when the node enters the scene tree for the first time.
func _ready():
	$Area.mouse_entered.connect(anim.bind("Hover"))
	$Area.mouse_exited.connect(anim.bind("Rest"))
	$Area.input_event.connect(func(camera, event, a, b, c):
		if event.is_pressed():
			self.clicked.emit()
		)
	if parent:
		parent.tree_exited.connect(func():self.parent = null)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
func anim(a:String):
	if dismissed:
		return
	match a:
		"Hover", "Rest":
			$Hover.play(a)
		_:
			$Anim.play(a)
	if parent:
		parent.anim(a)
func get_tile_path() -> Array[Node3D]:
	var result := [self as Node3D]
	var p = parent
	while p:
		result.push_front(p)
		p = p.parent as Node3D
	return result
var dismissed := false
func dismiss():
	dismissed = true
	$Anim.play("Disappear")
