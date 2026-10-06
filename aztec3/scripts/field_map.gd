extends Control

signal entered(location: int)
signal moved(cell: Vector2i)
signal message(text: String)
const COLS = 22
const ROWS = 12
const TILE = 44
const DOORS = [Vector2i(4,4),Vector2i(11,4),Vector2i(18,8)]
const NAMES = ["展示資料室", "エル・カスティーヨ", "調査テント"]
const BLOCKS = [Rect2i(2,1,5,3),Rect2i(9,0,5,4),Rect2i(16,5,5,3),Rect2i(0,7,3,5),Rect2i(14,9,2,3),Rect2i(0,0,2,2),Rect2i(20,0,2,4)]
var cell = Vector2i(4,5)
var path: Array[Vector2i] = []
var unlocked = [true,false,false]
var font: Font
var tick = 0.0
var facing = Vector2i.DOWN

static func walkable(point: Vector2i) -> bool:
	if point.x < 0 or point.y < 0 or point.x >= COLS or point.y >= ROWS:
		return false
	for block in BLOCKS:
		if block.has_point(point):
			return false
	return true

static func route(start: Vector2i, target: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if not walkable(start) or not walkable(target) or start == target:
		return result
	var frontier: Array[Vector2i] = [start]
	var visited = {start:start}
	var index = 0
	while index < frontier.size():
		var current = frontier[index]
		index += 1
		for offset in [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]:
			var next = current + offset
			if walkable(next) and not visited.has(next):
				visited[next] = current
				frontier.append(next)
				if next == target:
					var cursor = target
					while cursor != start:
						result.push_front(cursor)
						cursor = visited[cursor]
					return result
	return result

func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	queue_redraw()

func destination(target: Vector2i) -> void:
	path = route(cell,target)
	if path.is_empty() and target != cell:
		message.emit("そこには歩いて行けません。道や草地を選んでください。")
	queue_redraw()

func step(direction: Vector2i) -> bool:
	path.clear()
	facing = direction
	if not walkable(cell+direction):
		return false
	cell += direction
	moved.emit(cell)
	queue_redraw()
	return true

func nearby() -> int:
	for i in range(DOORS.size()):
		var distance = cell-DOORS[i]
		if absi(distance.x)+absi(distance.y) <= 1:
			return i
	return -1

func enter_nearby() -> void:
	var location = nearby()
	if location < 0:
		message.emit("入口のそばまで歩いてから、Enterか「建物に入る」を選んでください。")
	elif not unlocked[location]:
		message.emit("前の場所の謎を解くと、この調査先が開きます。")
	else:
		entered.emit(location)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		var direction = Vector2i.ZERO
		match event.keycode:
			KEY_UP,KEY_W: direction=Vector2i.UP
			KEY_DOWN,KEY_S: direction=Vector2i.DOWN
			KEY_LEFT,KEY_A: direction=Vector2i.LEFT
			KEY_RIGHT,KEY_D: direction=Vector2i.RIGHT
			KEY_ENTER,KEY_KP_ENTER:
				# Preserve Enter activation for focused UI buttons.
				if get_viewport().gui_get_focus_owner() == self:
					enter_nearby()
					get_viewport().set_input_as_handled()
		if direction != Vector2i.ZERO:
			step(direction)
			grab_focus()
			get_viewport().set_input_as_handled()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		grab_focus()
		destination(Vector2i(floor(event.position.x/TILE),floor(event.position.y/TILE)))

func _process(delta: float) -> void:
	if path.is_empty():
		return
	tick += delta
	if tick >= 0.11:
		tick = 0.0
		var next = path.pop_front()
		facing = next-cell
		cell = next
		moved.emit(cell)
		queue_redraw()

func _draw() -> void:
	for y in range(ROWS):
		for x in range(COLS):
			var road = y in [4,8] or x in [4,11,18]
			var shade = Color("ddc99b") if road else Color("91a87c")
			draw_rect(Rect2(x*TILE,y*TILE,TILE,TILE),shade.lightened(float((x+y)%3)*0.025))
			if not road:
				draw_line(Vector2(x*TILE+12,y*TILE+28),Vector2(x*TILE+15,y*TILE+22),Color("789565"),2)
	# Pond and dense woodland are solid obstacles.
	draw_rect(Rect2(0,7*TILE,3*TILE,5*TILE),Color("699e9b"))
	for y in range(8,12):
		draw_line(Vector2(12,y*TILE+12),Vector2(115,y*TILE+12),Color("a5c8b5"),2)
	for p in [Vector2(640,439),Vector2(679,485),Vector2(635,514),Vector2(38,35),Vector2(911,51),Vector2(935,145)]:
		draw_circle(p+Vector2(0,10),20,Color("728466"))
		draw_circle(p,23,Color("416c5c"))
	# Reading room, stepped pyramid and canvas tent, all original vector art.
	draw_rect(Rect2(88,44,220,132),Color("806951"))
	draw_rect(Rect2(96,52,204,112),Color("d8c29c"))
	for x in [113,157,245]:
		draw_rect(Rect2(x,88,25,37),Color("66877c"))
	draw_rect(Rect2(172,139,48,37),Color("3b594e"))
	for i in range(4):
		draw_rect(Rect2(396+i*17,8+i*17,220-i*34,166-i*34),Color("d9c7a2").lightened(i*0.035))
		draw_rect(Rect2(396+i*17,8+i*17,220-i*34,166-i*34),Color("a39370"),false,2)
	draw_rect(Rect2(489,107,34,69),Color("bcaa84"))
	draw_colored_polygon(PackedVector2Array([Vector2(704,340),Vector2(814,221),Vector2(924,340)]),Color("ecd8ad"))
	draw_colored_polygon(PackedVector2Array([Vector2(814,221),Vector2(924,340),Vector2(830,323)]),Color("c9ae80"))
	draw_rect(Rect2(780,308,70,44),Color("715d45"))
	for i in range(3):
		var p = Vector2(DOORS[i])*TILE+Vector2(TILE/2,TILE/2)
		draw_circle(p,13,Color("f4e8cd") if unlocked[i] else Color("7a8268"))
		if font:
			draw_string(font,p+(Vector2(-153,40) if i==2 else Vector2(18,7)),NAMES[i]+("" if unlocked[i] else "（未開放）"),HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("284b42"))
	for point in path:
		draw_circle(Vector2(point)*TILE+Vector2(22,22),3,Color("fff0c7"))
	var player = Vector2(cell)*TILE+Vector2(22,22)
	draw_ellipse_shadow(player)
	draw_rect(Rect2(player+Vector2(-10,-8),Vector2(20,20)),Color("365f50"))
	draw_circle(player+Vector2(0,-14),9,Color("d2a07b"))
	draw_rect(Rect2(player+Vector2(-12,-23),Vector2(24,7)),Color("b8864a"))
	draw_line(player+Vector2(-5,12),player+Vector2(-5,17),Color("394b43"),4)
	draw_line(player+Vector2(5,12),player+Vector2(5,17),Color("394b43"),4)
	draw_rect(Rect2(1,1,COLS*TILE-2,ROWS*TILE-2),Color("65755c"),false,2)

func draw_ellipse_shadow(point: Vector2) -> void:
	draw_circle(point+Vector2(0,10),15,Color(0.2,0.3,0.2,0.2))

func focus_if_attached() -> void:
	if is_inside_tree():
		grab_focus()
