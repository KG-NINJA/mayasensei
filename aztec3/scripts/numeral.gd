extends Control

var value = 0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var ink=Color("68765e")
	if value==0:
		draw_ellipse(Vector2(26,25),22,12,ink,false,2,true)
		draw_arc(Vector2(26,28),9,PI,TAU,24,ink,2,true)
		draw_line(Vector2(6,28),Vector2(46,28),ink,2,true)
	else:
		for i in range(value/5):
			draw_line(Vector2(7,19+i*12),Vector2(46,19+i*12),ink,5,true)
