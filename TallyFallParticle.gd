@tool
extends Node3D
enum Tally {
	Joe, Rob, Andrew, Ross, Zubin
}
@export var tallyColor: Tally:
	set(t):
		if not is_inside_tree():
			await tree_entered
		var c = [
				Color.RED, Color.YELLOW, Color.GREEN, Color.BLUE, Color(0.5, 0.5, 0.5)
		][t]
		$Particles.mesh.material.albedo_color = c
		$Particles.mesh.material.emission = c
