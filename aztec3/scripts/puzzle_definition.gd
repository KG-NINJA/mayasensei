extends Resource
class_name PuzzleDefinition

@export var id: String = ""
@export var title: String = ""
@export_multiline var prompt: String = ""
@export var input_domain: String = ""
@export var correct_rule: String = ""
@export var solution: Array[int] = []
@export var hints: Array[String] = []
@export_multiline var explanation: String = ""
@export var evidence_id: String = ""
@export var evidence_title: String = ""
@export_multiline var evidence_text: String = ""
@export_multiline var classification: String = ""
