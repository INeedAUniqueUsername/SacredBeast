extends Node3D
@tool

enum TileColor {
	Red, Yellow, Green, Blue, Gray
}
@export var color: TileColor:
	set(t):
		print("color set to " + str(t))
		color = t
		if !is_inside_tree():
			await tree_entered
		$Sprite.texture = [
			preload("res://TileGlowRed.png"),
			preload("res://TileGlowYellow.png"),
			preload("res://TileGlowGreen.png"),
			preload("res://TileGlowBlue.png"),
			preload("res://TileGlowGray.png"),
		][color]
		
		var c = [
			Color.RED, Color.YELLOW, Color.GREEN, Color.BLUE, Color(0.5, 0.5, 0.5)
		][color]
		$Particles.mesh.material.albedo_color = c
		$Particles.mesh.material.emission = c
	get:
		return color
func set_emitting_selected(char: Node3D):
	var b = char.is_selected
	$Particles.emitting = b
	$Select.play({
		true:"Selected",
		false:"Deselected"
	}[b])
func dismiss():
	$Anim.play("Disappear")
