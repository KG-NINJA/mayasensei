extends SceneTree

const Map = preload("res://scripts/field_map.gd")
const Scene = preload("res://scripts/inspection_scene.gd")
var failures: Array[String] = []
var checks = 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks+=1
	if not condition:
		failures.append(message)

func run() -> void:
	# Every walkable tile must be reachable without crossing solid terrain.
	var start=Vector2i(4,5)
	for y in range(Map.ROWS):
		for x in range(Map.COLS):
			var target=Vector2i(x,y)
			var path=Map.route(start,target)
			if not Map.walkable(target) or target==start:
				check(path.is_empty(),"Path accepted an obstacle")
				continue
			check(not path.is_empty() and path[-1]==target,"Unreachable walkable tile")
			var previous=start
			for point in path:
				check(Map.walkable(point) and absi(point.x-previous.x)+absi(point.y-previous.y)==1,"Path crosses terrain or jumps")
				previous=point
	var map=Map.new()
	root.add_child(map)
	var entries: Array[int]=[]
	map.entered.connect(func(location: int): entries.append(location))
	map.cell=Vector2i(4,4)
	check(not map.step(Vector2i.UP),"Player walked into building")
	check(map.cell==Vector2i(4,4),"Collision moved player")
	map.enter_nearby()
	check(entries==[0],"Unlocked door failed")
	map.cell=Map.DOORS[1]
	map.enter_nearby()
	check(entries==[0],"Locked door entered")
	map.unlocked[1]=true
	map.enter_nearby()
	check(entries==[0,1],"Newly unlocked door failed")
	map.cell=Vector2i(7,6)
	map.enter_nearby()
	check(entries.size()==2,"Distant door entered")
	map.destination(Map.DOORS[2])
	while not map.path.is_empty():
		map._process(0.12)
	check(map.cell==Map.DOORS[2],"Click route did not finish")
	map.free()
	# Test actual scene input at a scaled viewport with markers disabled.
	for location in range(3):
		for index in range(3):
			var scene=Scene.new()
			scene.location=location
			scene.size=Vector2(815,459)
			scene.markers=false
			root.add_child(scene)
			var observations: Array[int]=[]
			scene.inspected.connect(func(value: int): observations.append(value))
			var event=InputEventMouseButton.new()
			event.button_index=MOUSE_BUTTON_LEFT
			event.pressed=true
			event.position=Scene.REGIONS[location][index].get_center()*scene.size/Vector2(1280,720)
			scene._gui_input(event)
			check(observations.is_empty(),"Investigation happened before walking")
			scene._process(5.0)
			check(observations==[index],"Scaled scene click lost correct object")
			scene._process(5.0)
			check(observations.size()==1,"Observation emitted twice")
			scene.free()
	var game=load("res://main.tscn").instantiate()
	game.saver=game.Save.new("user://exploration-test.json")
	root.add_child(game)
	game.state.data=game.State.fresh()
	game.open_map()
	check(game.view=="map","Map did not open")
	game.enter_from_map(2)
	check(game.state.data.location==0,"Map bypassed story lock")
	game.open_notebook(false)
	game.back()
	check(game.view=="map" and game.field_map.cell==game.map_cell,"Notebook lost map position")
	game.field_map.step(Vector2i.RIGHT)
	var saved_position=game.saver.load_state().get("map_position",[])
	check(saved_position==[game.map_cell.x,game.map_cell.y],"Map position not saved")
	game.enter_from_map(0)
	check(game.view=="chapter","First entry missed introduction")
	game.skip_story()
	game.inspect(0)
	game.open_map()
	game.enter_from_map(0)
	check(game.view=="explore" and "notebook" in game.state.data.observations,"Revisit lost observations")
	check(game.State.valid(game.state.data),"Exploration broke legacy save compatibility")
	var legacy=game.state.data.duplicate(true)
	legacy.erase("map_position")
	check(game.State.valid(legacy),"Legacy save rejected")
	var invalid=legacy.duplicate(true)
	invalid.map_position=[2,1]
	check(not game.State.valid(invalid),"Saved position inside building accepted")
	invalid.map_position=[100,1]
	check(not game.State.valid(invalid),"Out-of-bounds saved position accepted")
	game.music.stop()
	game.sound.stop()
	await create_timer(0.1).timeout
	game.queue_free()
	await process_frame
	print("AZTEC3_EXPLORATION ",JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
