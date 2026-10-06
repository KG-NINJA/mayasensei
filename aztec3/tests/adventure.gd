extends SceneTree

var game: Control
var failures: Array[String] = []
var checks = 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)

func press(text: String) -> void:
	for item in game.interactive:
		if item.text == text:
			item.pressed.emit()
			return
	failures.append("Missing button: "+text)

func run() -> void:
	game = load("res://main.tscn").instantiate()
	# Keep verification completely separate from the player's save.
	game.saver = game.Save.new("user://adventure-test.json")
	root.add_child(game)
	game.state.data = game.State.fresh()
	game.render()
	press("手帳をひらく")
	for stage in range(3):
		check(game.view == "chapter", "Chapter introduction missing")
		for line in range(3):
			game.advance_story()
		check(game.view == "explore", "Dialogue did not lead to exploration")
		check(not game.state.ready_for(game.Rules.IDS[stage]), "Puzzle unlocked before investigation")
		for item in range(3):
			game.inspect(item)
		press("資料を読み解く →")
		press("照合する")
		check(game.view == "puzzle", "Incorrect answer advanced story")
		press("解答と解説を見る")
		check(game.view == "reveal_confirm", "Reveal skipped confirmation")
		press("謎に戻る")
		check(not game.state.complete(game.puzzle_id), "Cancel revealed answer")
		game.open_notebook(false)
		game.back()
		check(game.view == "puzzle", "Notebook lost puzzle context")
		if stage == 1:
			press("解答と解説を見る")
			press("解答を読んで進む")
		else:
			game.state.data.puzzles[game.puzzle_id].board = game.Rules.SOLUTIONS[stage].duplicate()
			press("照合する")
		check(game.view == "result", "Solution did not reach result")
		check(game.State.valid(game.state.data), "Progress no longer save-compatible")
		press("記録を結末へ" if stage == 2 else "次の場所へ →")
	check(game.view == "ending", "Ending not reached")
	game.start_game()
	check(game.view == "ending", "Completed save did not resume at ending")
	game.state.data = game.State.fresh()
	game.start_game()
	game.back()
	check(game.view == "explore", "Escape did not skip intro safely")
	print("AZTEC3_ADVENTURE ", JSON.stringify({"checks":checks,"failures":failures}))
	game.music.stop()
	game.sound.stop()
	await create_timer(0.1).timeout
	await process_frame
	game.free()
	game = null
	await process_frame
	quit(0 if failures.is_empty() else 1)
