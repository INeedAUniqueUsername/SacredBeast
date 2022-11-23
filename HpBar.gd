extends Node3D



var barColor:int:
	set(n):
		$Color.modulate = [
			Color.RED, Color.YELLOW, Color.GREEN, Color.DODGER_BLUE, Color(0.5, 0.5, 0.5)
		][n]
var portion:float:
	set(f):
		var r = $Color.region_rect
		$Color.region_rect = Rect2(r.position.x, r.position.y,  clamp(int(f * 64), 1, 64), r.size.y)
