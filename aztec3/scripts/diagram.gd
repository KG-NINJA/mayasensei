extends Control

var turns = 0
var photograph = false
var overlay = false
var font: Font
const INK = Color("304f47")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var center = size / 2.0
	var scale_factor = minf(size.x, size.y) / 250.0
	draw_set_transform(center, 0, Vector2.ONE * scale_factor)
	draw_rect(Rect2(-119,-119,238,238),Color("eadfbe"))
	for i in range(-2,3):
		draw_line(Vector2(-105,i*49),Vector2(105,i*49),Color("cabb98"),1)
		draw_line(Vector2(i*49,-105),Vector2(i*49,105),Color("cabb98"),1)
	if photograph:
		draw_set_transform(center, (turns+2)*PI/2.0, Vector2.ONE*scale_factor)
	draw_arc(Vector2(-88,-88),11,0,TAU,32,INK,4,true)
	draw_colored_polygon(PackedVector2Array([Vector2(88,-101),Vector2(101,-78),Vector2(75,-78)]),INK)
	draw_rect(Rect2(-100,76,24,24),INK)
	if photograph:
		draw_rect(Rect2(40,-24,68,48),Color("8d927b"))
		for i in range(5):
			draw_line(Vector2(43+i*12,22),Vector2(60+i*12,-22),INK,2,true)
	else:
		for i in range(3):
			var p = [Vector2(0,-57), Vector2(74,0), Vector2(0,62)][i]
			draw_rect(Rect2(p-Vector2(23,21),Vector2(46,42)),Color("faf2d9"))
			draw_rect(Rect2(p-Vector2(23,21),Vector2(46,42)),INK,false,2)
			if font:
				draw_string(font,p+Vector2(-8,9),["A","B","C"][i],HORIZONTAL_ALIGNMENT_LEFT,-1,25,INK)
	if overlay and photograph:
		draw_set_transform(center,0,Vector2.ONE*scale_factor)
		for i in range(3):
			var p = [Vector2(0,-57),Vector2(74,0),Vector2(0,62)][i]
			draw_rect(Rect2(p-Vector2(23,21),Vector2(46,42)),Color("c47746"),false,3)
			if font:
				draw_string(font,p+Vector2(-8,9),["A","B","C"][i],HORIZONTAL_ALIGNMENT_LEFT,-1,25,Color("57351e"))
