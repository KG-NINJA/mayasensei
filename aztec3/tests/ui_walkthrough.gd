extends RefCounted

var failures: Array[String] = []
var captures: Array[String] = []
var game: Control

func run(target: Control) -> void:
	game=target
	game.state.data=game.State.fresh()
	game.saver=game.Save.new("user://aztec3-ui-test-"+str(Time.get_ticks_usec())+".json")
	game.status="UI verification (isolated save)"
	for dimensions in [Vector2i(1280,720),Vector2i(1920,1080)]:
		game.get_tree().root.size=dimensions
		await game.get_tree().create_timer(0.4).timeout
		game.state.data=game.State.fresh()
		game.view="title"
		game.render()
		await capture("title-"+str(dimensions.x))
		await press("手帳をひらく")
		for stage in range(3):
			await capture("explore-%d-%d" % [stage,dimensions.x])
			for i in range(3):
				game.inspect(i)
			await capture("dialogue-%d-%d" % [stage,dimensions.x])
			await press("資料を読み解く →")
			await press("照合する")
			if game.view!="puzzle":
				failures.append("incorrect board advanced")
			for hint in range(3):
				game.use_hint()
			await capture("puzzle-hints-%d-%d" % [stage,dimensions.x])
			await press("配置をリセット")
			game.open_notebook(false)
			await capture("notebook-%d-%d" % [stage,dimensions.x])
			game.back()
			await press("解答と解説を見る")
			await capture("result-%d-%d" % [stage,dimensions.x])
			await press("記録を結末へ" if stage==2 else "次の場所へ →")
		if game.view!="ending" or not game.state.complete("p003"):
			failures.append("ending not reached")
		await capture("ending-"+str(dimensions.x))
		game.view="explore"
		game.render()
		game.toggle_sound()
		game.view="restart"
		game.render()
		await press("新しい手帳で始める")
		if AudioServer.is_bus_mute(0) != not game.state.data.settings.sound:
			failures.append("restart sound mismatch")
	print("AZTEC3_UI ",JSON.stringify({"failures":failures,"captures":captures,"resolutions":[[1280,720],[1920,1080]],"platform":OS.get_name()}))
	game.get_tree().quit(0 if failures.is_empty() else 1)

func press(text: String) -> void:
	for item in game.interactive:
		if item.text==text:
			item.pressed.emit()
			await game.get_tree().process_frame
			return
	failures.append("missing button: "+text)

func capture(name: String) -> void:
	await game.get_tree().process_frame
	await RenderingServer.frame_post_draw
	var directory=OS.get_executable_path().get_base_dir()+"/ui-captures"
	if DirAccess.make_dir_recursive_absolute(directory)!=OK:
		failures.append("capture directory unavailable")
		return
	var image=game.get_viewport().get_texture().get_image()
	var expected_width=int(name.get_slice("-",name.get_slice_count("-")-1))
	if image.get_width()!=expected_width:
		failures.append("capture resolution %s: expected %d actual %d" % [name,expected_width,image.get_width()])
	var path=directory+"/"+name+".png"
	if image.save_png(path)!=OK:
		failures.append("capture write failed: "+name)
	else:
		captures.append(path)
