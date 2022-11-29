extends Node
func get_max(a:Array, c:Callable, min:int = -9223372036854775808):
	var result = null
	var value = min
	for item in a:
		var v = c.call(item)
		if v >= value:
			result = item
			value = v
	return result
func get_min(a:Array, c:Callable, max:int = 9223372036854775807):
	var result = null
	var value = max
	for item in a:
		var v = c.call(item)
		if v <= value:
			result = item
			value = v
	return result
func get_min_index(a:Array, c:Callable, max:int = 9223372036854775807):
	var result = null
	var value = max
	var index = 0
	for item in a:
		
		var v = c.call(item)
		if v <= value:
			result = index
			value = v
		index += 1
	return result
