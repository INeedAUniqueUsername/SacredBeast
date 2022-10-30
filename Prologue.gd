extends Control

const parts = [
	'One day in 2010, the band was getting ready for a concert at the park when something strange happened.',
	'"Guys!! Look what I just found!!" Joe said excitedly, pointing at a wormhole that he had just found. "This will take us to the Kingdom of Good & Evil!"',
	'"Wait, what? There\'s a Kingdom of Good & Evil? I thought that was something we just made up?" Rob said.',
	'(little did Rob know, the Kingdom of Good & Evil was definitely real.)',
	'Suddenly, an unknown force pulled the whole band into the portal.',
	'When they landed on the other side, the band found themselves in a world above the clouds - Talhalla.',
]


var scroll : Tween = null

func showText(st):
	$Label.modulate = Color(1, 1, 1, 1)
	$Label.text = st
	
	
	var t = get_tree().create_tween()
	scroll = t
	
	var l = len(st)
	$Label.visible_characters = 0
	t.tween_property($Label, "visible_characters", l, l / 24.0)
	t.play()
	await t.finished
	
	await get_tree().create_timer(1.5).timeout
	
	t = get_tree().create_tween()
	t.tween_property($Label, "modulate", Color(1, 1, 1, 0), 0.5)
	t.play()
	await t.finished
	
	await get_tree().create_timer(0.5).timeout
	
func _ready():
	for st in parts:
		await showText(st)
	pass # Replace with function body.
func _process(delta):
	if Input.is_key_pressed(KEY_SPACE):
		scroll.set_speed_scale(2)
		pass
	
	pass
