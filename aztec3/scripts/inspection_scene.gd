extends "res://scripts/illustration.gd"

signal inspected(index: int)
signal walked(point: Vector2)
# Regions use the illustration's original 1280x720 coordinates.
const REGIONS = [
	[Rect2(240,560,290,150),Rect2(586,578,300,89),Rect2(1000,380,210,220)],
	[Rect2(125,495,250,185),Rect2(560,505,270,150),Rect2(982,432,182,238)],
	[Rect2(950,550,165,104),Rect2(855,295,176,260),Rect2(260,390,162,220)]
]
var markers = true
var visited = [false,false,false]
var actor = Vector2(660,685)
var target = Vector2(660,685)
var hover = -1
var pending = -1
var font: Font
var names: Array = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_exited.connect(func(): hover=-1; queue_redraw())

func hit(point: Vector2) -> int:
	for i in range(3):
		if REGIONS[location][i].has_point(point):
			return i
	return -1

func interact(index: int) -> void:
	pending=index
	target=Vector2(clampf(REGIONS[location][index].get_center().x,100,1180),685)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		hover=hit(event.position*Vector2(1280,720)/size)
		queue_redraw()
	elif event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		var point=event.position*Vector2(1280,720)/size
		var index=hit(point)
		if index>=0:
			interact(index)
		else:
			pending=-1
			target=Vector2(clampf(point.x,100,1180),685)

func _process(delta: float) -> void:
	elapsed+=delta
	actor=actor.move_toward(target,520*delta)
	if actor.distance_to(target)<1 and pending>=0:
		var index=pending
		pending=-1
		walked.emit(actor)
		inspected.emit(index)
	queue_redraw()

func _draw() -> void:
	super._draw()
	draw_set_transform(Vector2.ZERO,0,size/Vector2(1280,720))
	# The photograph is an actual clickable object in the outdoor scene.
	if location==1:
		draw_colored_polygon(PackedVector2Array([Vector2(565,523),Vector2(795,514),Vector2(820,649),Vector2(579,658)]),Color("f4e8cd"))
		draw_rect(Rect2(585,535,203,97),Color("759583"))
		draw_line(Vector2(585,535),Vector2(788,632),Color("425e54"),22)
	for i in range(3):
		var region: Rect2=REGIONS[location][i]
		if hover==i:
			draw_rect(region,Color("bb854d"),false,4)
			if font and names.size()==3:
				draw_string(font,Vector2(26,40),names[i],HORIZONTAL_ALIGNMENT_LEFT,-1,25,Color("284b42"))
		if markers:
			var center=region.get_center()
			draw_circle(center,19,Color("365f50") if visited[i] else Color("f4e8cd"))
			if font:
				draw_string(font,center+Vector2(-7,8),"✓" if visited[i] else str(i+1),HORIZONTAL_ALIGNMENT_LEFT,-1,23,Color("f4e8cd") if visited[i] else Color("365f50"))
	draw_circle(actor+Vector2(0,3),20,Color(0.2,0.25,0.2,0.2))
	draw_rect(Rect2(actor+Vector2(-13,-42),Vector2(26,36)),Color("365f50"))
	draw_circle(actor+Vector2(0,-55),12,Color("d2a07b"))
	draw_rect(Rect2(actor+Vector2(-17,-68),Vector2(34,9)),Color("b8864a"))
	draw_line(actor+Vector2(-7,-6),actor+Vector2(-7,5),INK,5)
	draw_line(actor+Vector2(7,-6),actor+Vector2(7,5),INK,5)
