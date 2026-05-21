extends Node

signal dialogue_started
signal dialogue_finished

var dialogues := {}
var ui: CanvasLayer
var active := false
var current_lines: Array = []
var current_index := -1
var finished_callback := Callable()

func _ready() -> void:
	load_dialogues()

func register_ui(dialogue_ui: CanvasLayer) -> void:
	ui = dialogue_ui
	if is_instance_valid(ui):
		ui.hide_dialogue()

func load_dialogues() -> void:
	var path := "res://data/dialogues.json"
	if not FileAccess.file_exists(path):
		dialogues = {}
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		dialogues = {}
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		dialogues = parsed
	else:
		dialogues = {}

func is_active() -> bool:
	return active

func start_dialogue(key: String, callback := Callable()) -> void:
	var lines: Array = dialogues.get(key, [])
	start_lines(lines, callback)

func start_lines(lines: Array, callback := Callable()) -> void:
	if lines.is_empty():
		if callback.is_valid():
			callback.call()
		return
	current_lines = lines.duplicate(true)
	current_index = -1
	finished_callback = callback
	active = true
	var manager := _game_manager()
	if manager != null:
		manager.set_player_locked(true)
	emit_signal("dialogue_started")
	advance()

func advance() -> void:
	if not active:
		return
	current_index += 1
	if current_index >= current_lines.size():
		_finish()
		return
	var line = current_lines[current_index]
	var speaker := str(line.get("speaker", ""))
	var text := str(line.get("text", ""))
	if is_instance_valid(ui):
		ui.show_line(speaker, text)

func _finish() -> void:
	active = false
	current_lines.clear()
	current_index = -1
	if is_instance_valid(ui):
		ui.hide_dialogue()
	var manager := _game_manager()
	if manager != null:
		manager.set_player_locked(false)
	emit_signal("dialogue_finished")
	var callback := finished_callback
	finished_callback = Callable()
	if callback.is_valid():
		callback.call()

func _game_manager() -> Node:
	return get_node_or_null("/root/GameManager")
