extends RefCounted

const State = preload("res://scripts/game_state.gd")
const Save = preload("res://scripts/save_service.gd")
const Rules = preload("res://scripts/rules.gd")
var checks = 0
var failures: Array[String] = []

func check(condition: bool, name: String) -> void:
	checks += 1
	if not condition:
		failures.append(name)

func prepare(state: RefCounted, stage: int) -> void:
	state.data.started = true
	state.data.location = stage
	for id in [["notebook","model","ines"],["board","photo","haru"],["receipt","page","ines_tent"]][stage]:
		state.observe(id,id+"の記録")

func permutations(values: Array) -> Array:
	var result: Array = []
	for a in values:
		for b in values:
			for c in values:
				if a!=b and b!=c and a!=c:
					result.append([a,b,c])
	return result

func run() -> Dictionary:
	checks = 0
	failures.clear()
	for id in Rules.IDS:
		var d=load("res://content/"+id+".tres")
		check(d.hints.size()==3,"three exported hints: "+id)
		for i in range(d.hints.size()):
			check(d.hints[i] is String and d.hints[i].length()>10,"exported hint text: %s/%d" % [id,i])
		check(d.explanation.length()>30 and d.evidence_text.length()>30,"exported explanation and evidence: "+id)
		check(Rules.accepts(id,d.solution),"resource solution matches evaluator: "+id)
	var solutions: Array = []
	for board in permutations([0,5,10]):
		if Rules.accepts("p001",board):
			solutions.append(board)
	check(solutions==[[10,0,5]],"P001 exhaustive 6 inputs / one solution")
	solutions.clear()
	for turn in range(4):
		for slot in range(3):
			if Rules.accepts("p002",[turn,slot]):
				solutions.append([turn,slot])
	check(solutions==[[2,1]],"P002 exhaustive 12 inputs / one solution")
	solutions.clear()
	for cards in permutations([0,1,2]):
		for hypothesis in range(3):
			var board = cards+[hypothesis]
			if Rules.accepts("p003",board):
				solutions.append(board)
	check(solutions==[[0,1,2,2]],"P003 exhaustive 18 inputs / one solution")
	check(not Rules.accepts("unknown",[]),"unknown puzzle rejected")
	check(not Rules.accepts("p001",[5,5,0]),"duplicate tile rejected")
	check(Rules.place([10,0,5],0,5,3)==[5,0,10],"occupied placement swaps without losing tile")
	check(Rules.place([-1,0,5],0,5,3)==[5,0,-1],"empty placement moves previous tile")
	check(State.valid(State.fresh()),"fresh state valid")
	var complete_state: Dictionary = {}
	for reveal in [false,true]:
		var state = State.new()
		check(not state.ready_for("p001"),"initial clue gate")
		check(not state.accessible(1) and not state.accessible(2),"initial location gates")
		check(not state.finish("p003",true),"cannot skip prerequisites through reveal")
		for stage in range(3):
			var id = Rules.IDS[stage]
			prepare(state,stage)
			check(state.ready_for(id),"stage %d clues ready" % stage)
			state.data.puzzles[id].status = "in_progress"
			state.data.puzzles[id].hints = 3
			check(not state.finish(id,false),"stage %d wrong board stays in progress" % stage)
			check(State.valid(state.data),"stage %d midway valid" % stage)
			state.data.puzzles[id].board=Rules.SOLUTIONS[stage].duplicate()
			if reveal:
				state.data.puzzles[id].board=Rules.blank(id)
			check(state.finish(id,reveal),"stage %d complete/reveal" % stage)
			check(state.data.puzzles[id].status==("revealed" if reveal else "solved"),"reveal distinction %d" % stage)
			check(State.valid(state.data),"stage %d completion valid" % stage)
			check(state.finish(id,reveal),"stage %d completion idempotent" % stage)
			check(State.valid(state.data),"idempotent completion does not duplicate evidence")
		check(state.data.chapter==3 and state.complete("p003"),"ending reachable")
		for location in range(3):
			check(state.accessible(location),"all locations remain revisitable")
		complete_state=state.data.duplicate(true)
	check(State.valid(JSON.parse_string(JSON.stringify(complete_state))),"JSON number roundtrip")
	var malformed_values = [null, [], "save", 1, {}, {"schema_version":2}]
	for value in malformed_values:
		check(not State.valid(value),"malformed root safely rejected")
	for key in complete_state.keys():
		var broken=complete_state.duplicate(true)
		broken.erase(key)
		check(not State.valid(broken),"missing required key "+key)
	var bad=complete_state.duplicate(true)
	bad.puzzles.p002.board=[0,1]
	check(not State.valid(bad),"completed puzzle wrong board rejected")
	bad=complete_state.duplicate(true)
	bad.puzzles.p001.hints=4
	check(not State.valid(bad),"hint bounds")
	bad=complete_state.duplicate(true)
	bad.evidence.append("zero")
	check(not State.valid(bad),"duplicate evidence")
	bad=complete_state.duplicate(true)
	bad.observations.erase("receipt")
	check(not State.valid(bad),"receipt observation / evidence consistency")
	bad=complete_state.duplicate(true)
	bad.settings.sound="true"
	check(not State.valid(bad),"settings type")
	bad=complete_state.duplicate(true)
	bad.log=[12]
	check(not State.valid(bad),"log type")
	bad=complete_state.duplicate(true)
	bad.location=0.5
	check(not State.valid(bad),"fractional location")
	bad=complete_state.duplicate(true)
	bad.puzzles.p001.board=[true,0,5]
	check(not State.valid(bad),"boolean is not an integer tile")
	var source_test = OS.has_feature("editor") and not OS.has_feature("web")
	var stem = "res://.qa/test-" if source_test else "user://aztec3-test-"
	if source_test:
		DirAccess.make_dir_recursive_absolute("res://.qa")
	var path = stem+str(Time.get_ticks_usec())+".json"
	var save=Save.new(path)
	check(save.load_state()==State.fresh(),"absent save uses defaults")
	var partial=State.new()
	prepare(partial,0)
	partial.data.puzzles.p001.status="in_progress"
	partial.data.puzzles.p001.board=[10,-1,-1]
	partial.data.puzzles.p001.hints=2
	partial.data.settings.sound=false
	check(save.save_state(partial.data),"save midway board/hints/log/settings")
	check(save.load_state()==partial.data,"midway roundtrip exact")
	check(save.save_state(complete_state),"second save writes primary and backup")
	check(save.load_state()==complete_state,"completed state roundtrip")
	check(save.read_valid(path+".bak")==partial.data,"backup is last valid state")
	var file=FileAccess.open(path,FileAccess.WRITE)
	if file:
		file.store_string("{bad json")
		file.close()
	check(save.load_state()==partial.data and not save.message.is_empty(),"corrupt primary recovers backup with warning")
	check(save.save_state(complete_state),"recovery can save again")
	check(save.read_valid(path+".bak")==partial.data,"corrupt primary never overwrites valid backup")
	check(not save.save_state({}),"invalid data never overwrites valid save")
	check(save.load_state()==complete_state,"failed save leaves valid data")
	var blocked=Save.new("res://.qa/no-such-parent/file.json" if source_test else "user://no-such-parent/file.json")
	check(not blocked.save_state(complete_state) and not blocked.message.is_empty(),"unwritable destination reports failure")
	return {"checks":checks,"failures":failures,"platform":OS.get_name(),"solutions":[1,1,1],"ending_solved_and_revealed":true}
