extends RefCounted

const Rules = preload("res://scripts/rules.gd")
const OBSERVATIONS = ["notebook", "model", "ines", "board", "photo", "haru", "receipt", "page", "ines_tent"]
const EVIDENCE = ["zero", "orientation", "receipt", "truth"]
var data: Dictionary

func _init() -> void:
	data = fresh()

static func fresh() -> Dictionary:
	return {"schema_version": 1, "started": false, "location": 0, "chapter": 0,
		"observations": [], "knowledge": [], "evidence": [], "dialogue_flags": [], "log": [],
		"puzzles": {"p001": {"status": "unseen", "board": [-1,-1,-1], "hints": 0}, "p002": {"status": "unseen", "board": [0,-1], "hints": 0}, "p003": {"status": "unseen", "board": [-1,-1,-1,-1], "hints": 0}},
		"settings": {"sound": true, "hotspots": true}}

func complete(id: String) -> bool:
	return data.puzzles[id].status in ["solved", "revealed"]

func accessible(location: int) -> bool:
	return location == 0 or (location == 1 and complete("p001")) or (location == 2 and complete("p002"))

func ready_for(id: String) -> bool:
	match id:
		"p001": return "notebook" in data.observations and "model" in data.observations and "ines" in data.observations
		"p002": return complete("p001") and "board" in data.observations and "photo" in data.observations and "haru" in data.observations
		"p003": return complete("p002") and "receipt" in data.evidence and "page" in data.observations and "ines_tent" in data.observations
	return false

func observe(id: String, line: String) -> void:
	if id not in data.observations:
		data.observations.append(id)
	if id in ["ines", "haru", "ines_tent"] and id not in data.dialogue_flags:
		data.dialogue_flags.append(id)
	if id == "receipt" and "receipt" not in data.evidence:
		data.evidence.append("receipt")
	add_log(line)

func add_log(line: String) -> void:
	if data.log.is_empty() or data.log[-1] != line:
		data.log.append(line)
	if data.log.size() > 80:
		data.log.pop_front()

func finish(id: String, reveal: bool) -> bool:
	if not ready_for(id):
		return false
	if complete(id):
		return true
	var index = Rules.IDS.find(id)
	if reveal:
		data.puzzles[id].board = Rules.SOLUTIONS[index].duplicate()
	if not Rules.accepts(id, data.puzzles[id].board):
		return false
	data.puzzles[id].status = "revealed" if reveal else "solved"
	var evidence_id = ["zero", "orientation", "truth"][index]
	data.evidence.append(evidence_id)
	data.knowledge.append(evidence_id)
	data.chapter = index + 1
	return true

static func integer(value: Variant, low: int, high: int) -> bool:
	return (typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT) and is_finite(float(value)) and float(value) == floor(float(value)) and value >= low and value <= high

static func string_set(value: Variant, allowed: Array) -> bool:
	if not value is Array or value.size() > allowed.size():
		return false
	var seen: Array = []
	for item in value:
		if not item is String or item not in allowed or item in seen:
			return false
		seen.append(item)
	return true

# Strict validation: reject malformed saves rather than silently manufacturing progress.
static func valid(raw: Variant) -> bool:
	if not raw is Dictionary or not raw.has_all(fresh().keys()):
		return false
	if not integer(raw.schema_version, 1, 1) or not raw.started is bool or not integer(raw.location, 0, 2) or not integer(raw.chapter, 0, 3):
		return false
	if not string_set(raw.observations, OBSERVATIONS) or not string_set(raw.evidence, EVIDENCE) or not string_set(raw.knowledge, ["zero", "orientation", "truth"]) or not string_set(raw.dialogue_flags, ["ines", "haru", "ines_tent"]):
		return false
	if not raw.log is Array or raw.log.size() > 80:
		return false
	for line in raw.log:
		if not line is String or line.length() > 4000:
			return false
	if not raw.settings is Dictionary or not raw.settings.has_all(["sound", "hotspots"]) or not raw.settings.sound is bool or not raw.settings.hotspots is bool:
		return false
	if not raw.puzzles is Dictionary or not raw.puzzles.has_all(Rules.IDS):
		return false
	var finished_count = 0
	for n in range(3):
		var id = Rules.IDS[n]
		var puzzle = raw.puzzles[id]
		if not puzzle is Dictionary or not puzzle.has_all(["status", "board", "hints"]):
			return false
		if puzzle.status not in ["unseen", "in_progress", "solved", "revealed"] or not integer(puzzle.hints, 0, 3) or not puzzle.board is Array or puzzle.board.size() != Rules.blank(id).size():
			return false
		for i in range(puzzle.board.size()):
			var value = puzzle.board[i]
			if not integer(value, -1, 10):
				return false
			value = int(value)
			if n == 0 and value not in [-1, 0, 5, 10]:
				return false
			if n == 1 and ((i == 0 and value not in [0, 1, 2, 3]) or (i == 1 and value not in [-1, 0, 1, 2])):
				return false
			if n == 2 and value not in [-1, 0, 1, 2]:
				return false
		var used: Array = []
		if n != 1:
			for value in puzzle.board.slice(0, 3):
				if int(value) != -1 and int(value) in used:
					return false
				used.append(int(value))
		var done = puzzle.status in ["solved", "revealed"]
		var evidence_id = ["zero", "orientation", "truth"][n]
		if done != (evidence_id in raw.evidence) or done != (evidence_id in raw.knowledge):
			return false
		if done:
			if finished_count != n or not Rules.accepts(id, puzzle.board):
				return false
			finished_count += 1
	if finished_count != raw.chapter or raw.location > mini(finished_count, 2):
		return false
	if ("receipt" in raw.evidence) != ("receipt" in raw.observations):
		return false
	var state = new()
	state.data = raw
	for id in Rules.IDS:
		if raw.puzzles[id].status != "unseen" and not state.ready_for(id):
			return false
	return true

static func canonical(raw: Dictionary) -> Dictionary:
	var result = raw.duplicate(true)
	for key in ["schema_version", "location", "chapter"]:
		result[key] = int(result[key])
	for id in Rules.IDS:
		result.puzzles[id].hints = int(result.puzzles[id].hints)
		for i in range(result.puzzles[id].board.size()):
			result.puzzles[id].board[i] = int(result.puzzles[id].board[i])
	return result
