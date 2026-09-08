extends RefCounted

const State = preload("res://scripts/game_state.gd")
const MAX_BYTES = 400000
var path: String
var message = ""

func _init(save_path: String = "user://aztec3-v1.json") -> void:
	path = save_path

func read_valid(filename: String) -> Variant:
	if not FileAccess.file_exists(filename):
		return null
	var file = FileAccess.open(filename, FileAccess.READ)
	if file == null or file.get_length() > MAX_BYTES:
		return null
	var parser = JSON.new()
	var error = parser.parse(file.get_as_text())
	file.close()
	if error != OK or not State.valid(parser.data):
		return null
	return State.canonical(parser.data)

func load_state() -> Dictionary:
	message = ""
	var primary = read_valid(path)
	if primary != null:
		return primary
	var backup = read_valid(path + ".bak")
	if backup != null:
		message = "保存データに問題があったため、1つ前のバックアップを復元しました。"
		return backup
	if FileAccess.file_exists(path) or FileAccess.file_exists(path + ".bak"):
		message = "保存データを読み込めませんでした。新規状態で開始します。"
	return State.fresh()

func save_state(data: Dictionary) -> bool:
	if not State.valid(data):
		message = "保存できません：進行データの整合性を確認できません。"
		return false
	var temporary = path + ".tmp"
	var file = FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		message = "保存できません：書き込み先を開けません。今は閉じずに続けてください。"
		return false
	file.store_string(JSON.stringify(data))
	file.flush()
	var write_error = file.get_error()
	file.close()
	if write_error != OK or read_valid(temporary) == null:
		message = "保存できません：書き込み確認に失敗しました。"
		return false
	if read_valid(path) != null:
		if DirAccess.copy_absolute(path, path + ".bak") != OK:
			message = "保存できません：バックアップの作成に失敗しました。"
			return false
	if DirAccess.rename_absolute(temporary, path) != OK:
		message = "保存できません：保存ファイルの置換に失敗しました。"
		return false
	message = "保存済み" if not OS.has_feature("web") else "保存済み・このブラウザーで再開"
	if OS.has_feature("web") and not OS.is_userfs_persistent():
		message = "一時保存のみ：ブラウザーの保存が無効です。閉じると失われます。"
	return true
