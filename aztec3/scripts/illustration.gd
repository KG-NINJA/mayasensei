extends Control

var location = 1
var elapsed = 0.0
var animate = true
const INK = Color("354e48")
const JADE = Color("416c5c")
const LEAF = Color("6b8662")
const PAPER = Color("f4e8cd")
const STONE = Color("ddc9a5")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	if animate:
		elapsed += delta
		queue_redraw()

func poly(points: Array, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array(points), color)

func line(a: Vector2, b: Vector2, color: Color = INK, width: float = 2.0) -> void:
	draw_line(a, b, color, width, true)

func rect(x: float, y: float, w: float, h: float, color: Color) -> void:
	draw_rect(Rect2(x, y, w, h), color)

func tree(x: float, y: float, radius: float, shade: Color) -> void:
	line(Vector2(x,y), Vector2(x-10,y-radius*1.4), Color("64654c"), radius*0.12)
	for i in range(5):
		var angle = float(i) * 1.4
		draw_circle(Vector2(x+cos(angle)*radius*0.6,y-radius+sin(angle)*radius*0.3),radius*0.7,shade)
	for i in range(5):
		line(Vector2(x-30+i*15,y-radius*0.65), Vector2(x-10,y-radius*0.3), Color(shade,0.55),2)

func pyramid(center: Vector2, scale_factor: float) -> void:
	draw_set_transform(center,0,Vector2.ONE*scale_factor)
	poly([Vector2(-260,130),Vector2(90,150),Vector2(310,110),Vector2(80,85)], Color("c4b68b"))
	for i in range(9):
		var w = 254.0 - i*20.0
		var y = 100.0 - i*26.0
		poly([Vector2(-w,y),Vector2(40+w*0.51,y),Vector2(40+(w-17)*0.51,y-23),Vector2(-w+20,y-23)], PAPER.darkened(float(i)*0.008))
		poly([Vector2(40+w*0.51,y),Vector2(w+68,y-25),Vector2(w+48,y-47),Vector2(40+(w-17)*0.51,y-23)],STONE.darkened(0.08))
		line(Vector2(-w,y),Vector2(40+w*0.51,y),Color("bbaa87"),2)
		for j in range(7):
			var sx = -w+float(j)*w*0.24
			line(Vector2(sx,y-17),Vector2(sx+3,y-3),Color("d1c09f"),1)
	poly([Vector2(-85,107),Vector2(7,107),Vector2(8,-125),Vector2(-24,-125)],Color("b9a582"))
	poly([Vector2(-74,107),Vector2(-4,107),Vector2(1,-126),Vector2(-19,-126)],Color("ede0c2"))
	for i in range(23):
		var y = 105.0-i*10.0
		var ratio = float(i)/23.0
		line(Vector2(lerpf(-74,-19,ratio),y),Vector2(lerpf(-4,1,ratio),y),Color("a99b7f"),1.4)
	poly([Vector2(-83,-132),Vector2(82,-132),Vector2(82,-194),Vector2(-83,-194)],PAPER)
	poly([Vector2(82,-132),Vector2(132,-151),Vector2(132,-210),Vector2(82,-194)],STONE.darkened(0.1))
	rect(-91,-201,182,10,Color("e6d6b5"))
	rect(-86,-179,175,5,Color("bba783"))
	rect(-22,-170,26,38,INK)
	rect(42,-170,19,38,INK.lightened(0.1))
	line(Vector2(-83,-153),Vector2(-29,-153),Color("c7b590"))
	draw_set_transform(Vector2.ZERO,0,size/Vector2(1280,720))

func person(origin: Vector2, factor: float, ines: bool) -> void:
	draw_set_transform(origin,0,size/Vector2(1280,720)*factor)
	var skin = Color("b7825e") if ines else Color("d2a07b")
	var shirt = Color("d8aa69") if ines else Color("648b89")
	poly([Vector2(-70,135),Vector2(-56,26),Vector2(-24,8),Vector2(24,8),Vector2(61,30),Vector2(75,135)],shirt)
	poly([Vector2(-22,7),Vector2(0,34),Vector2(27,6),Vector2(27,-21),Vector2(-20,-21)],skin)
	draw_circle(Vector2(0,-50),43,Color("343b32"))
	if ines:
		draw_circle(Vector2(30,-5),20,Color("343b32"))
	draw_circle(Vector2(0,-43),34,skin)
	poly([Vector2(-34,-55),Vector2(-29,-83),Vector2(22,-84),Vector2(37,-62),Vector2(13,-71),Vector2(-7,-54)],Color("343b32"))
	line(Vector2(-21,-46),Vector2(-11,-47),INK,3)
	line(Vector2(10,-47),Vector2(20,-46),INK,3)
	line(Vector2(-2,-41),Vector2(-6,-30),skin.darkened(0.22),2)
	line(Vector2(-10,-20),Vector2(8,-20),Color("784d3d"),2)
	line(Vector2(-20,12),Vector2(-7,133),shirt.darkened(0.18),3)
	line(Vector2(-51,43),Vector2(-43,114),shirt.darkened(0.18),2)
	line(Vector2(46,45),Vector2(53,111),shirt.darkened(0.18),2)
	if ines:
		for i in range(5):
			rect(-52+i*24,49,9,5,Color("f3e7ce"))
		line(Vector2(-35,25),Vector2(51,111),INK,8)
	else:
		line(Vector2(-26,14),Vector2(0,79),INK,4)
		line(Vector2(24,14),Vector2(0,79),INK,4)
		rect(-18,75,40,28,Color("ddd6bd"))
		rect(-8,83,19,12,INK)
	draw_set_transform(Vector2.ZERO,0,size/Vector2(1280,720))

func _draw() -> void:
	draw_set_transform(Vector2.ZERO,0,size/Vector2(1280,720))
	for y in range(0,720,8):
		rect(0,y,1280,8,Color("d6dfcd").lerp(Color("f1d6a2"),float(y)/720.0))
	draw_circle(Vector2(1030,145),67,Color("f4e5b8"))
	for i in range(5):
		var x = fmod(float(i)*317.0 + elapsed*2.0,1600.0)-160.0
		cloud_ellipse(Rect2(x,90+i%2*65,220,28), Color("e9ead6"))
	poly([Vector2(0,325),Vector2(290,274),Vector2(480,312),Vector2(810,272),Vector2(1280,302),Vector2(1280,720),Vector2(0,720)],Color("afba8b"))
	for i in range(13):
		tree(i*114,370,48+float(i%3)*10,Color("83956e"))
	rect(0,427,1280,293,Color("bdc297"))
	poly([Vector2(250,720),Vector2(610,410),Vector2(780,410),Vector2(1100,720)],Color("e4d4ad"))
	if location == 1:
		pyramid(Vector2(610,390)*size/Vector2(1280,720),1.1*size.x/1280.0)
		tree(76,598,154,JADE)
		tree(1245,540,135,LEAF)
		for i in range(7):
			line(Vector2(250+i*144,550),Vector2(250+i*144,586),INK,3)
		line(Vector2(250,555),Vector2(1114,555),Color("a09a77"),2)
		poly([Vector2(126,674),Vector2(154,505),Vector2(346,505),Vector2(368,674)],Color("b1a080"))
		rect(146,514,196,114,PAPER)
		for i in range(4):
			line(Vector2(164,542+i*19),Vector2(317-i%2*45,542+i*19),Color("b9ad8e"),3)
		person(Vector2(1063,542)*size/Vector2(1280,720),1.05,false)
	elif location == 0:
		rect(0,0,420,720,Color("e8d8ba"))
		rect(960,0,320,720,Color("d7c4a2"))
		rect(400,0,580,70,Color("e8d8ba"))
		rect(407,62,17,468,Color("b09d7c"))
		rect(943,62,20,468,Color("b09d7c"))
		pyramid(Vector2(700,374)*size/Vector2(1280,720),0.58*size.x/1280.0)
		rect(400,500,580,30,Color("b09d7c"))
		rect(0,540,1280,180,Color("9b9779"))
		rect(45,88,285,396,Color("bba883"))
		for shelf in range(3):
			for b in range(9):
				var colors = [Color("6e8270"),Color("b77d59"),Color("d8caa6"),Color("838d7b")]
				rect(65+b*26,128+shelf*113-b%3*9,20,66+b%3*9,colors[(b+shelf)%4])
			rect(55,199+shelf*113,267,12,Color("927e61"))
		person(Vector2(1094,479)*size/Vector2(1280,720),1.45,true)
		poly([Vector2(173,546),Vector2(847,539),Vector2(983,720),Vector2(59,720)],Color("aa825d"))
		poly([Vector2(241,577),Vector2(472,558),Vector2(526,693),Vector2(255,710)],JADE)
		poly([Vector2(259,581),Vector2(464,569),Vector2(502,678),Vector2(271,690)],PAPER)
		line(Vector2(363,575),Vector2(380,686),Color("bca989"),2)
		for i in range(4):
			line(Vector2(284,608+i*14),Vector2(346,604+i*14),Color("bca989"),2)
		for i in range(3):
			rect(592+i*96,594,76,55,PAPER)
			rect(603+i*96,603,55,37,Color("d5c39e"))
	else:
		poly([Vector2(0,0),Vector2(1280,0),Vector2(1280,286),Vector2(642,58),Vector2(0,326)],Color("d7bc88"))
		poly([Vector2(0,0),Vector2(302,0),Vector2(160,568),Vector2(0,619)],Color("d0b482"))
		poly([Vector2(1090,0),Vector2(1280,0),Vector2(1280,605),Vector2(1020,552)],Color("bda278"))
		line(Vector2(641,0),Vector2(641,530),Color("826f52"),9)
		line(Vector2(0,228),Vector2(641,54),Color("947c58"),4)
		line(Vector2(1280,239),Vector2(641,54),Color("947c58"),4)
		rect(858,297,170,253,Color("bba278"))
		for i in range(4):
			rect(868,310+i*52,149,42,Color("e8d9b6"))
			line(Vector2(934,329+i*52),Vector2(950,329+i*52),Color("957f61"),3)
		person(Vector2(337,487)*size/Vector2(1280,720),1.25,true)
		poly([Vector2(482,489),Vector2(1190,495),Vector2(1280,720),Vector2(390,720)],Color("ad8962"))
		poly([Vector2(553,527),Vector2(856,537),Vector2(901,695),Vector2(497,678)],PAPER)
		for i in range(6):
			line(Vector2(584,557+i*17),Vector2(813-i%2*32,560+i*17),Color("afaa8a"),2)
		rect(961,557,144,85,Color("e5cca0"))
		line(Vector2(978,583),Vector2(1084,583),Color("a89876"),3)
		line(Vector2(978,605),Vector2(1043,605),Color("a89876"),3)
	for i in range(90):
		var x = fmod(float(i)*137.23,1280.0)
		var y = 626+fmod(float(i)*49.17,88.0)
		line(Vector2(x,y),Vector2(x+12,y-3),Color(0.30,0.36,0.23,0.12),1)
	draw_rect(Rect2(2,2,1276,716),Color(0.25,0.32,0.26,0.35),false,3)

func cloud_ellipse(bounds: Rect2, color: Color) -> void:
	var vertices = PackedVector2Array()
	for i in range(40):
		var a = TAU*float(i)/40.0
		vertices.append(bounds.get_center()+Vector2(cos(a)*bounds.size.x/2,sin(a)*bounds.size.y/2))
	draw_colored_polygon(vertices,color)

