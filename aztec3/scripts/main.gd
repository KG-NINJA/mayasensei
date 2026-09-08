extends Control

const State = preload("res://scripts/game_state.gd")
const Save = preload("res://scripts/save_service.gd")
const Rules = preload("res://scripts/rules.gd")
const Illustration = preload("res://scripts/illustration.gd")
const Diagram = preload("res://scripts/diagram.gd")
const Numeral = preload("res://scripts/numeral.gd")
const DEFINITIONS = [preload("res://content/p001.tres"),preload("res://content/p002.tres"),preload("res://content/p003.tres")]
const FONT = preload("res://assets/fonts/NotoSansJP.ttf")
const INK = Color("284b42")
const GREEN = Color("365f50")
const PAPER = Color("f7f0dd")
const MUTED = Color("667465")
const GOLD = Color("bb854d")
const LOCATIONS = ["展示資料室", "エル・カスティーヨ前", "調査テント"]
const DESCRIPTIONS = ["薄い貝形と、抜け落ちた最後の一枚。", "影の向こうに、何が書かれていたのか。", "集めた証拠を、同じ一枚の上へ。"]
const OBS = [["notebook","model","ines"],["board","photo","haru"],["receipt","page","ines_tent"]]
const OBS_NAMES = [["翡翠の手帳", "数の展示模型", "イネスと話す"],["基準図を読む", "影の写真を見る", "ハルと話す"],["修復票を読む", "乾燥棚の一枚", "イネスと話す"]]
const EVIDENCE_NAMES = ["零という記録", "写真の正しい向き", "修復票"]
var state = State.new()
var saver = Save.new()
var layer: Control
var view = "title"
var previous_view = "explore"
var selected = -1
var overlay = false
var feedback = ""
var speaker = "イネス"
var speech = "展示の準備を始めましょう。手帳と模型を調べてから、私に声をかけて。"
var status = ""
var status_label: Label
var puzzle_id = "p001"
var result_reveal = false
var sound: AudioStreamPlayer
var music: AudioStreamPlayer
var interactive: Array[Button] = []

func _ready() -> void:
	theme = make_theme()
	state.data = saver.load_state()
	status = saver.message
	if OS.has_feature("web") and not OS.is_userfs_persistent():
		status = "一時保存のみ：ブラウザーの保存が無効です。閉じると失われます。"
	sound = AudioStreamPlayer.new()
	if ResourceLoader.exists("res://assets/tap.wav"):
		sound.stream = load("res://assets/tap.wav")
	add_child(sound)
	music = AudioStreamPlayer.new()
	if ResourceLoader.exists("res://assets/field_notes.wav"):
		music.stream = load("res://assets/field_notes.wav")
		music.volume_db = -17
	add_child(music)
	AudioServer.set_bus_mute(0,not state.data.settings.sound)
	if "--verify" in OS.get_cmdline_user_args():
		var suite = load("res://tests/suite.gd").new()
		var report = suite.run()
		print("AZTEC3_VERIFY ",JSON.stringify(report))
		if OS.has_feature("web"):
			JavaScriptBridge.eval("document.title = " + JSON.stringify("AZTEC3_VERIFY " + JSON.stringify(report)))
		else:
			get_tree().quit(0 if report.failures.is_empty() else 1)
		return
	render()
	if "--ui-verify" in OS.get_cmdline_user_args() and not OS.has_feature("web"):
		await load("res://tests/ui_walkthrough.gd").new().run(self)

func make_theme() -> Theme:
	var result = Theme.new()
	var readable_font = FontVariation.new()
	readable_font.base_font = FONT
	readable_font.variation_opentype = {2003265652:450.0}
	result.default_font = readable_font
	result.default_font_size = 19
	result.set_color("font_color","Label",INK)
	for kind in ["normal","hover","pressed","focus","disabled"]:
		var style = StyleBoxFlat.new()
		style.bg_color = PAPER if kind == "normal" else Color("e5dbc0")
		style.border_color = Color("b9b597") if kind != "focus" else GOLD
		style.set_border_width_all(1 if kind != "focus" else 3)
		style.set_corner_radius_all(7)
		style.content_margin_left = 14
		style.content_margin_right = 14
		if kind == "disabled":
			style.bg_color = Color("e4dfcf")
		if kind == "focus":
			style.bg_color = Color.TRANSPARENT
		result.set_stylebox(kind,"Button",style)
	result.set_color("font_color","Button",INK)
	result.set_color("font_hover_color","Button",INK)
	result.set_color("font_pressed_color","Button",INK)
	result.set_color("font_focus_color","Button",INK)
	result.set_color("font_disabled_color","Button",Color("848876"))
	return result

func panel(bounds: Rect2, color: Color = PAPER, parent: Control = null) -> Panel:
	var element = Panel.new()
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(10)
	style.border_color = Color("c4bea3")
	style.set_border_width_all(1)
	element.add_theme_stylebox_override("panel",style)
	element.position = bounds.position
	element.size = bounds.size
	element.mouse_filter = Control.MOUSE_FILTER_IGNORE
	(parent if parent else layer).add_child(element)
	return element

func label(text: String, bounds: Rect2, font_size: int = 20, color: Color = INK, parent: Control = null) -> Label:
	var element = Label.new()
	element.add_theme_font_size_override("font_size",font_size)
	element.add_theme_color_override("font_color",color)
	element.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	element.text = text
	element.position = bounds.position
	element.size = bounds.size
	element.mouse_filter = Control.MOUSE_FILTER_IGNORE
	(parent if parent else layer).add_child(element)
	return element

func button(text: String, bounds: Rect2, action: Callable, primary: bool = false, disabled: bool = false) -> Button:
	var element = Button.new()
	element.text = text
	element.position = bounds.position
	element.size = bounds.size
	element.disabled = disabled
	element.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if primary:
		for kind in ["normal","hover","pressed"]:
			var style = theme.get_stylebox(kind,"Button").duplicate()
			style.bg_color = GREEN if kind == "normal" else GREEN.lightened(0.12)
			element.add_theme_stylebox_override(kind,style)
		for kind in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
			element.add_theme_color_override(kind,Color("fff5dc"))
	element.pressed.connect(func():
		if state.data.settings.sound and sound.stream:
			sound.play()
		action.call())
	layer.add_child(element)
	if not disabled:
		interactive.append(element)
	return element

func illustration(bounds: Rect2, location: int) -> void:
	var art = Illustration.new()
	art.position = bounds.position
	art.size = bounds.size
	art.location = location
	art.clip_contents = true
	layer.add_child(art)

func persist() -> void:
	saver.save_state(state.data)
	status = saver.message
	if is_instance_valid(status_label):
		status_label.text = status

func render() -> void:
	var old_focus = get_viewport().gui_get_focus_owner()
	var old_text = old_focus.text if old_focus is Button else ""
	if is_instance_valid(layer):
		remove_child(layer)
		layer.queue_free()
	layer = Control.new()
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(layer)
	interactive.clear()
	match view:
		"title": render_title()
		"explore": render_explore()
		"puzzle": render_puzzle()
		"notebook": render_notebook(false)
		"log": render_notebook(true)
		"result": render_result()
		"ending": render_ending()
		"restart": render_restart()
	status_label = label(status,Rect2(30,694,990,24),14,Color("79674b"))
	label("クリック / Tab・Enter　｜　N 手帳　Esc 戻る",Rect2(899,695,367,21),13,MUTED)
	var focus: Button = null
	for item in interactive:
		if item.text == old_text:
			focus = item
	if focus == null and not interactive.is_empty():
		focus = interactive[0]
	if focus:
		focus.grab_focus()

func header(subtitle: String) -> void:
	label("AZTEC3",Rect2(28,17,245,51),36,INK)
	label(subtitle,Rect2(248,24,645,38),18,MUTED)
	button("音：ON" if state.data.settings.sound else "音：OFF",Rect2(969,24,115,40),toggle_sound)
	button("タイトル",Rect2(1096,24,156,40),func(): view="title"; render())

func render_title() -> void:
	illustration(Rect2(0,0,1280,720),1)
	panel(Rect2(39,47,583,611),Color(0.97,0.94,0.85,0.97))
	label("FIELD NOTES  /  CHICHÉN ITZÁ",Rect2(77,75,498,34),16,MUTED)
	label("AZTEC3",Rect2(72,112,514,102),78,INK)
	label("翡翠の手帳と\n太陽の記憶",Rect2(78,232,495,120),40,INK)
	label("影ではなく、影が隠したものを読め。",Rect2(79,371,475,45),22,MUTED)
	label("3つの場所、3つの謎。\n失われた一枚から、人々の記録を取り戻す。",Rect2(79,426,480,69),19,INK)
	button("つづきから" if state.data.started else "手帳をひらく",Rect2(78,521,323,54),start_game,true)
	button("はじめから",Rect2(415,521,170,54),func(): view="restart"; render(),false,not state.data.started)
	label("Godot製 パズルアドベンチャー · 3問体験版\n実在のマヤの都市を舞台にした創作。AZTEC3は作品名です。",Rect2(79,588,500,50),14,MUTED)
	label("YUCATÁN  /  MÉXICO",Rect2(965,28,281,43),18,INK)

func start_game() -> void:
	state.data.started = true
	AudioServer.set_bus_mute(0,not state.data.settings.sound)
	if not music.playing and music.stream:
		music.play()
	view = "ending" if state.complete("p003") else "explore"
	if not state.data.log.is_empty():
		speech = state.data.log[-1]
		speaker = "前回の記録"
	persist()
	render()

func render_restart() -> void:
	header("新しい手帳")
	panel(Rect2(220,176,840,356))
	label("今の進行を、新しい手帳で上書きします。",Rect2(263,225,750,55),27)
	label("このブラウザー／PCのセーブが最初に戻ります。",Rect2(263,303,750,53),20,MUTED)
	button("今の手帳へ戻る",Rect2(263,407,339,58),func(): view="title"; render())
	button("新しい手帳で始める",Rect2(623,407,339,58),func():
		state.data = State.fresh()
		speech = "展示の準備を始めましょう。手帳と模型を調べてから、私に声をかけて。"
		speaker = "イネス"
		start_game(),true)

func render_explore() -> void:
	var location = int(state.data.location)
	var id = Rules.IDS[location]
	header("翡翠の手帳と太陽の記憶　　%02d / 03 記録を理解" % state.data.chapter)
	for i in range(3):
		button("%02d  %s" % [i+1,LOCATIONS[i]],Rect2(28+i*276,88,263,42),func():
			state.data.location=i
			speaker="手帳"
			speech=DESCRIPTIONS[i]
			persist()
			render(),i==location,not state.accessible(i))
	illustration(Rect2(28,144,815,385),location)
	if state.data.settings.hotspots:
		var positions = [[Vector2(230,472),Vector2(478,470),Vector2(760,454)],[Vector2(185,449),Vector2(495,458),Vector2(758,475)],[Vector2(676,471),Vector2(619,327),Vector2(254,412)]][location]
		for i in range(3):
			button(str(i+1),Rect2(positions[i]-Vector2(19,19),Vector2(38,38)),func(): inspect(i))
	panel(Rect2(864,88,388,441))
	label("調査 %02d　/　%s" % [location+1,LOCATIONS[location]],Rect2(889,109,335,39),20)
	label("解読済み。再調査で意味を確かめよう。" if state.complete(id) else "3つの手掛かりを集め、資料を読み解く。",Rect2(889,160,332,57),17,MUTED)
	for i in range(3):
		var mark = "✓ " if OBS[location][i] in state.data.observations else "%d  " % (i+1)
		button(mark+OBS_NAMES[location][i],Rect2(889,233+i*59,338,47),func(): inspect(i))
	button("解読の記録を見る" if state.complete(id) else "資料を読み解く →",Rect2(889,426,338,58),open_puzzle,true,not state.ready_for(id))
	label("調べていない手掛かりも、いつでも再訪できます。",Rect2(890,489,335,28),13,MUTED)
	panel(Rect2(28,547,815,135))
	label(speaker,Rect2(49,560,761,30),18,GOLD)
	label(speech,Rect2(49,596,762,76),18,INK)
	button("手帳 / 証拠 %d" % state.data.evidence.size(),Rect2(864,547,187,53),func(): open_notebook(false))
	button("会話ログ",Rect2(1064,547,188,53),func(): open_notebook(true))
	button("調査点：表示" if state.data.settings.hotspots else "調査点：非表示",Rect2(864,613,187,53),func(): state.data.settings.hotspots=not state.data.settings.hotspots; persist(); render())
	if state.complete(id) and location < 2:
		button("次の場所へ →",Rect2(1064,613,188,53),func(): state.data.location=location+1; speaker="手帳"; speech=DESCRIPTIONS[location+1]; persist(); render(),true)
	elif state.complete("p003"):
		button("結末を読む",Rect2(1064,613,188,53),func(): view="ending"; render(),true)

func inspect(index: int) -> void:
	var location = int(state.data.location)
	var id = OBS[location][index]
	speaker = ["観察", "観察", "イネス" if location != 1 else "ハル"][index]
	var lines = [
		["翡翠の手帳の最後の一枚がない。『持ち出した遺物の数』の横には薄い貝形。余白に『影ではなく、影が隠したものを読め』とある。",
		 "点は1、棒は5、貝形は0。まずは0・5・10だけの模型で確かめよう。札を選んで箱へ置く。これは現代の展示教材だ。",
		 "私はイネス、資料修復士。最後の一枚は乾燥のため移したわ。行き先はテントの修復票にある。先に薄い記録を読んで、展示の誤解を直しましょう。"],
		["基準図：丸は左上、三角は右上、四角は左下。記録枠は A＝撮影班（上中央）、B＝地域協力者（右中央）、C＝設備提供（下中央）。",
		 "写真の向きが怪しい。斜線部分は影で文字が隠れている。丸・三角・四角は写真にも写り、同じ資料だと分かる。図版はゲーム用の模式図だ。",
		 "映像担当のハルです。影が宝の方角を示すのかと思った。でも、持出数は0だったね。まずこの写真を基準図と同じ向きに直してみよう。"],
		["修復票：『対象・手帳の最後の1枚／処置・乾燥／移動先・棚2／担当・イネス』。票とページの整理番号は J-03 で一致している。",
		 "棚2の紙に J-03。手帳の切れ目と紙端が一致する。薄い文字で地域協力者の名前が並ぶ。ページは盗まれず、ここで保護されていた。",
		 "乾燥は終わったわ。修復票も現物もそろっている。何が資料から直接分かるのか整理して。協力者の名前を確認し、私が展示に戻します。"]][location]
	speech = lines[index]
	if state.complete("p001") and location == 0:
		speech = ["貝形は空白ではなかった。『持ち出した遺物の数：0』。同じ手帳なのに、数字を読めると意味が変わる。", "B=0 が二つの式をつないでいる。書かれたゼロを、情報の欠落として扱ってはいけない。", "記録を照合できたわ。持出数は0。次は、影が何を隠したのかを確かめましょう。"][index]
	if state.complete("p002") and location == 1:
		speech = ["B は地域協力者の名前欄。基準図と写真の向きが一致すると、読めない文字の位置まで説明できる。", "写真は180度逆さだった。影が重なるのは B。矢印に見えた形は、方向の指示ではなかった。", "最初の解釈は間違っていたね。影が隠した名前を展示から落としてしまった。元の一枚を確認しよう。"][index]
	if state.complete("p003") and location == 2:
		speech = "記録と現物の照合を終え、最後の一枚は手帳に戻った。イネスが協力者の名前を確認して展示を訂正した。"
	state.observe(id,speaker+"："+speech)
	persist()
	render()

func open_puzzle() -> void:
	puzzle_id = Rules.IDS[int(state.data.location)]
	if not state.ready_for(puzzle_id):
		return
	if state.complete(puzzle_id):
		view = "result"
	else:
		state.data.puzzles[puzzle_id].status = "in_progress"
		view = "puzzle"
	selected=-1
	feedback=""
	persist()
	render()

func definition() -> Resource:
	return DEFINITIONS[Rules.IDS.find(puzzle_id)]

func render_puzzle() -> void:
	var d = definition()
	var puzzle = state.data.puzzles[puzzle_id]
	header("解読 %02d　/　%s" % [Rules.IDS.find(puzzle_id)+1,d.title])
	panel(Rect2(28,88,1224,590))
	label(d.prompt,Rect2(54,108,1147,70),21)
	panel(Rect2(870,195,352,399),Color("ede4cc"))
	label("手帳の余白",Rect2(891,211,305,32),21)
	var hint_text = "ヒントは3段階。使っても減点はありません。最後は解答を見て先へ進めます。"
	if puzzle.hints > 0:
		hint_text = ""
		for i in range(int(puzzle.hints)-1,-1,-1):
			hint_text += "%d. %s\n" % [i+1,d.hints[i]]
	var hint_box = RichTextLabel.new()
	hint_box.position=Vector2(891,254)
	hint_box.size=Vector2(306,193)
	hint_box.text=hint_text
	hint_box.autowrap_mode=TextServer.AUTOWRAP_ARBITRARY
	hint_box.add_theme_font_override("normal_font",theme.default_font)
	hint_box.add_theme_font_size_override("normal_font_size",17)
	hint_box.add_theme_color_override("default_color",MUTED)
	hint_box.focus_mode=Control.FOCUS_ALL
	layer.add_child(hint_box)
	button("ヒント %d / 3" % puzzle.hints,Rect2(891,462,306,46),use_hint,false,puzzle.hints>=3)
	button("解答と解説を見る",Rect2(891,523,306,46),reveal_solution)
	if puzzle_id == "p001":
		render_placement(puzzle.board)
	elif puzzle_id == "p002":
		render_comparison(puzzle.board)
	else:
		render_evidence(puzzle.board)
	label(feedback,Rect2(60,554,790,43),17,Color("935b37"))
	button("探索へ戻る",Rect2(54,616,180,44),back)
	button("手帳 / 再読",Rect2(247,616,185,44),func(): open_notebook(false))
	button("配置をリセット",Rect2(446,616,211,44),reset_board)
	button("照合する",Rect2(672,611,177,54),submit,true)
	label("途中の配置・ヒントも自動保存",Rect2(893,615,301,35),15,MUTED)

func render_placement(board: Array) -> void:
	label("① 札を選ぶ　→　② 置きたい箱を選ぶ",Rect2(65,197,780,37),19,MUTED)
	for i in range(3):
		var value = [0,5,10][i]
		button(("選択中　" if selected==value else "") + str(value),Rect2(93+i*247,246,213,71),func(): selected=value; render(),selected==value)
		var glyph = Numeral.new()
		glyph.position=Vector2(98+i*247,256)
		glyph.size=Vector2(54,50)
		glyph.value=value
		layer.add_child(glyph)
	label("貝形 = 0　　棒1本 = 5　　棒2本 = 10",Rect2(117,326,681,35),17,MUTED)
	for i in range(3):
		button(["A","B","C"][i]+"\n"+("？" if board[i]<0 else str(int(board[i]))),Rect2(93+i*247,377,213,109),func():
			if selected<0:
				feedback="先に上の札を選んでください。"
			else:
				state.data.puzzles[puzzle_id].board=Rules.place(board,i,selected,3)
				persist()
				feedback="配置しました。使われていた札は交換されます。"
			render())
	label("A + B = 10                         B + C = 5",Rect2(133,507,652,38),24,INK)

func render_comparison(board: Array) -> void:
	label("基準図",Rect2(91,186,273,34),18)
	label("写真  /  時計回り %d°" % (board[0]*90),Rect2(438,186,380,34),18)
	for i in range(2):
		var diagram = Diagram.new()
		diagram.position = Vector2(100+i*345,227)
		diagram.size = Vector2(250,250)
		diagram.photograph = i==1
		diagram.turns = int(board[0])
		diagram.overlay = overlay
		diagram.font = FONT
		layer.add_child(diagram)
	button("90° 回す",Rect2(415,485,171,42),func(): state.data.puzzles[puzzle_id].board[0]=(int(board[0])+1)%4; feedback=""; persist(); render())
	button("枠を重ねる" if not overlay else "重ね表示 OFF",Rect2(600,485,220,42),func(): overlay=not overlay; render())
	for i in range(3):
		button(["A","B","C"][i],Rect2(91+i*91,485,80,42),func(): state.data.puzzles[puzzle_id].board[1]=i; feedback=""; persist(); render(),board[1]==i)

func render_evidence(board: Array) -> void:
	for i in range(3):
		button(("✓ " if selected==i else "")+EVIDENCE_NAMES[i],Rect2(61+i*262,210,248,50),func(): selected=i; render(),selected==i)
	for i in range(3):
		label(["① 持ち出した遺物の数", "② 影に隠れた記録欄", "③ 最後の一枚の行き先"][i],Rect2(61+i*262,279,254,36),17)
		button("証拠を置く" if board[i]<0 else EVIDENCE_NAMES[int(board[i])],Rect2(61+i*262,324,248,61),func():
			if selected<0:
				feedback="先に証拠カードを選んでください。"
			else:
				state.data.puzzles[puzzle_id].board=Rules.place(board,i,selected,3)
				persist()
				feedback="この証拠が直接確かめることを照合しましょう。"
			render())
	label("証拠すべてに合う展示文を選ぶ",Rect2(62,397,776,33),18)
	var hypotheses = ["影は財宝の方角。遺物を探すため発掘する。", "遺物は盗まれ、最後の一枚は隠蔽された。", "持出数は0。修復した一枚から協力者の名前を戻す。"]
	for i in range(3):
		var b = button(("● " if board[3]==i else "○ ")+hypotheses[i],Rect2(62,436+i*38,779,33),func(): state.data.puzzles[puzzle_id].board[3]=i; feedback=""; persist(); render(),board[3]==i)
		b.add_theme_font_size_override("font_size",17)

func use_hint() -> void:
	var puzzle = state.data.puzzles[puzzle_id]
	puzzle.hints = mini(int(puzzle.hints)+1,3)
	persist()
	render()

func reset_board() -> void:
	state.data.puzzles[puzzle_id].board = Rules.blank(puzzle_id)
	selected=-1
	feedback="配置を戻しました。ヒントの履歴は残っています。"
	persist()
	render()

func submit() -> void:
	if state.finish(puzzle_id,false):
		finish_display(false)
	else:
		feedback="まだ一致しません。問題の条件をもう一度確認しよう。減点はありません。"
		render()

func reveal_solution() -> void:
	if state.finish(puzzle_id,true):
		finish_display(true)

func finish_display(reveal: bool) -> void:
	result_reveal=reveal
	state.add_log(definition().title+"："+definition().explanation)
	view="result"
	persist()
	render()

func render_result() -> void:
	var d = definition()
	header("解読の記録")
	panel(Rect2(109,108,1062,538))
	label("解答を見て理解" if state.data.puzzles[puzzle_id].status=="revealed" else "照合できた",Rect2(151,133,970,42),21,GOLD)
	label(d.title,Rect2(151,183,970,62),36)
	label(d.explanation,Rect2(151,260,955,107),23)
	panel(Rect2(150,397,965,130),Color("e4e6d0"))
	label("手帳に記録　/　"+d.evidence_title,Rect2(172,410,919,33),20)
	label(d.evidence_text,Rect2(172,452,918,69),18,MUTED)
	button("探索へ戻る",Rect2(151,561,250,52),func(): view="explore"; render())
	button("記録を結末へ" if puzzle_id=="p003" else "次の場所へ →",Rect2(822,561,294,52),func():
		if puzzle_id=="p003":
			view="ending"
		else:
			state.data.location=Rules.IDS.find(puzzle_id)+1
			view="explore"
			speaker="手帳"
			speech=DESCRIPTIONS[int(state.data.location)]
		persist()
		render(),true)

func open_notebook(logs: bool) -> void:
	previous_view=view
	view="log" if logs else "notebook"
	render()

func render_notebook(logs: bool) -> void:
	header("会話と解読の履歴" if logs else "翡翠の手帳　/　観察と解釈")
	panel(Rect2(28,89,1224,588))
	button("← 戻る",Rect2(54,105,141,41),back)
	label("会話ログ" if logs else "集めた証拠",Rect2(224,103,698,46),26)
	var scroll = ScrollContainer.new()
	scroll.position=Vector2(54,169)
	scroll.size=Vector2(1166,483)
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	layer.add_child(scroll)
	var column = VBoxContainer.new()
	column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation",17)
	scroll.add_child(column)
	if logs:
		if state.data.log.is_empty():
			notebook_line(column,"まだ会話の記録はありません。",20)
		for item in state.data.log:
			notebook_line(column,item,20)
	else:
		notebook_line(column,"観察済み %d / 9　　理解済み %d / 3\n調べただけの記録と、照合して理解した記録は別に残ります。" % [state.data.observations.size(),state.data.chapter],18)
		for id in state.data.evidence:
			if id=="receipt":
				notebook_line(column,"03　修復票\n最後の1枚／乾燥／棚2／担当イネス。整理番号 J-03 は現物と一致。",21)
			else:
				for d in DEFINITIONS:
					if d.evidence_id==id:
						notebook_line(column,d.evidence_title+"\n"+d.evidence_text,21)
		for i in range(3):
			var p = state.data.puzzles[Rules.IDS[i]]
			if p.status!="unseen":
				notebook_line(column,"解読 %02d　%s　/　%s　/　ヒント %d\n%s" % [i+1,DEFINITIONS[i].title,{"in_progress":"途中","solved":"自力で照合","revealed":"解答を見て理解"}[p.status],p.hints,DEFINITIONS[i].prompt],18)
		for i in range(3):
			notebook_line(column,"史実と創作　%02d\n%s" % [i+1,DEFINITIONS[i].classification],17)
		notebook_line(column,"チチェン・イッツァはメキシコ・ユカタンのマヤの都市。マヤの人々と文化は現在にも続いています。登場人物・事件・施設は創作です。外観は模式的なオリジナル画で、測量資料ではありません。\n参考：UNESCO World Heritage 483 / メキシコ教育省『Los mayas y su sistema de numeración』。URLと素材の権利表記は配布READMEに掲載。",17)

func notebook_line(parent: Control, text: String, font_size: int) -> void:
	var item = Label.new()
	item.text=text
	item.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	item.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	item.add_theme_font_size_override("font_size",font_size)
	parent.add_child(item)

func render_ending() -> void:
	illustration(Rect2(0,0,1280,720),1)
	panel(Rect2(71,55,1138,608),Color(0.97,0.94,0.85,0.97))
	label("AZTEC3  /  EPILOGUE",Rect2(113,82,1034,34),17,GOLD)
	label("名前を、光の中へ。",Rect2(112,138,1034,72),48)
	label("イネスは乾燥を終えた一枚を、翡翠の手帳に戻した。\n持ち出した遺物はゼロ。消えていたのは、展示の中の名前だった。\n\n「撮影した人だけでなく、この記録を支えた人々も。\n　誰の仕事だったのか、私たちの展示で伝えましょう」",Rect2(115,235,1029,238),25)
	var solved = 0
	for id in Rules.IDS:
		if state.data.puzzles[id].status=="solved":
			solved+=1
	label("3つの謎を理解　/　自力で照合 %d　解答を見て理解 %d\n体験版 終　・　人物、資料、事件はフィクションです。" % [solved,3-solved],Rect2(115,487,1009,65),18,MUTED)
	button("記録を読み返す",Rect2(115,582,308,51),func(): view="explore"; state.data.location=2; persist(); render(),true)
	button("タイトルへ",Rect2(851,582,308,51),func(): view="title"; render())

func toggle_sound() -> void:
	state.data.settings.sound=not state.data.settings.sound
	AudioServer.set_bus_mute(0,not state.data.settings.sound)
	persist()
	render()

func back() -> void:
	if view in ["notebook","log"]:
		view=previous_view
	elif view in ["puzzle","result","ending"]:
		view="explore"
	else:
		view="title"
	render()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_ESCAPE:
			back()
			get_viewport().set_input_as_handled()
		elif event.keycode==KEY_N and view in ["explore","puzzle","result"]:
			open_notebook(false)
			get_viewport().set_input_as_handled()
