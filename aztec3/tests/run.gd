extends SceneTree

func _initialize() -> void:
	var result=preload("res://tests/suite.gd").new().run()
	print("AZTEC3_TESTS ",JSON.stringify(result))
	quit(0 if result.failures.is_empty() else 1)
