extends Node3D

func set_emitting_selected(char: Node3D):
	var b = char.is_selected
	$Particles.emitting = b
	$Select.play({
		true:"Selected",
		false:"Deselected"
	}[b])
		
func dismiss():
	$Anim.play("Disappear")
