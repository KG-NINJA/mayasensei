extends RefCounted

const IDS = ["p001", "p002", "p003"]
const SOLUTIONS = [[10, 0, 5], [2, 1], [0, 1, 2, 2]]

static func unique_values(values: Array, domain: Array) -> bool:
	if values.size() != domain.size():
		return false
	for value in domain:
		var occurrences = 0
		for item in values:
			if item == value:
				occurrences += 1
		if occurrences != 1:
			return false
	return true

static func accepts(id: String, board: Array) -> bool:
	match id:
		"p001":
			return unique_values(board, [0, 5, 10]) and board[0] + board[1] == 10 and board[1] + board[2] == 5
		"p002":
			return board.size() == 2 and board[0] == 2 and board[1] == 1
		"p003":
			return board.size() == 4 and unique_values(board.slice(0, 3), [0, 1, 2]) and board[0] == 0 and board[1] == 1 and board[2] == 2 and board[3] == 2
	return false

static func blank(id: String) -> Array:
	match id:
		"p001": return [-1, -1, -1]
		"p002": return [0, -1]
		"p003": return [-1, -1, -1, -1]
	return []

static func place(board: Array, slot: int, value: int, count: int) -> Array:
	var result = board.duplicate()
	var previous = result[slot]
	for i in range(count):
		if result[i] == value:
			result[i] = previous
	result[slot] = value
	return result
