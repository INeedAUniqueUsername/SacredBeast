extends Control
const parts = [
	'One day in 2010, the band was getting ready for a concert at the park when something strange happened.',
	'"Guys!! Look what I just found!!" Joe said excitedly, pointing at a tornado that he had just found. "This will take us to the Kingdom of Good & Evil!"',
	'"Wait, what? There\'s a Kingdom of Good & Evil? I thought that was just something we made up? Also, is that a TORNADO??" Rob said.',
	'Little did he know, the Kingdom of Good & Evil was definitely a real thing. It was never something the band were meant to know about - until... it was time.',
	'Suddenly, the tornado swept the entire band into the sky. (One could say they were Taken for a Ride.)',
	'The band went up and up and up - far from the Earth, far past the obscure. They went so high up that they could see anything - out in the twilight.',
	'Eventually, the winds stopped and the band began falling... but not towards the park.',
	'When they landed, the band found themselves in a land above the clouds - Talhalla.',
]
var scroll : Tween = null
func showText(st):
	$Label.modulate = Color(1, 1, 1, 1)
	$Label.text = st
	
	var t = get_tree().create_tween()
	scroll = t
	
	var l = len(st)
	$Label.visible_characters = 0
	t.tween_property($Label, "visible_characters", l, (l / 24.0) / scrollSpeed)
	t.play()
	await t.finished
	
	await get_tree().create_timer(1.5 / scrollSpeed).timeout
	
	t = get_tree().create_tween()
	t.tween_property($Label, "modulate", Color(1, 1, 1, 0), 0.5 / scrollSpeed)
	t.play()
	await t.finished
	
	await get_tree().create_timer(0.5).timeout
	
var scrollSpeed = 1
func _ready():
	for st in parts:
		await showText(st)
	next()
func next():
	$Anim.play("Disappear")
	await $Anim.animation_finished
	get_tree().change_scene_to_file("res://Overworld.tscn")
func _process(delta):
	if Input.is_key_pressed(KEY_SPACE):
		scrollSpeed = 2
		scroll.set_speed_scale(scrollSpeed)
	if Input.is_key_pressed(KEY_ESCAPE):
		next()
	pass
