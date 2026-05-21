extends CanvasLayer

var objective_label: Label
var spray_label: Label
var hint_label: Label
var hint_time := 0.0

func _ready() -> void:
	layer = 10
	_build_ui()
	var manager := get_node_or_null("/root/GameManager")
	if manager != null:
		manager.objective_changed.connect(_on_objective_changed)
		manager.spray_changed.connect(_on_spray_changed)
		manager.hint_changed.connect(_on_hint_changed)
		_on_objective_changed(manager.get_objective_for_stage(manager.stage))
		_on_spray_changed(manager.spray_uses, manager.MAX_SPRAY_USES)

func _process(delta: float) -> void:
	if hint_time <= 0.0:
		return
	hint_time = maxf(0.0, hint_time - delta)
	if hint_time <= 0.0 and is_instance_valid(hint_label):
		hint_label.text = ""
		hint_label.modulate = Color(1.0, 1.0, 1.0, 0.0)
	elif is_instance_valid(hint_label):
		hint_label.modulate = Color(1.0, 1.0, 1.0, minf(1.0, hint_time))

func _build_ui() -> void:
	var panel := ColorRect.new()
	panel.color = Color(0.02, 0.025, 0.03, 0.72)
	panel.position = Vector2(18, 18)
	panel.size = Vector2(430, 110)
	add_child(panel)
	objective_label = Label.new()
	objective_label.position = Vector2(34, 28)
	objective_label.size = Vector2(300, 26)
	objective_label.add_theme_font_size_override("font_size", 18)
	add_child(objective_label)
	spray_label = Label.new()
	spray_label.position = Vector2(34, 58)
	spray_label.size = Vector2(300, 26)
	spray_label.add_theme_font_size_override("font_size", 18)
	add_child(spray_label)
	hint_label = Label.new()
	hint_label.position = Vector2(34, 92)
	hint_label.size = Vector2(390, 28)
	hint_label.add_theme_font_size_override("font_size", 18)
	hint_label.modulate = Color(1.0, 1.0, 1.0, 0.0)
	add_child(hint_label)

func _on_objective_changed(text: String) -> void:
	objective_label.text = "목표: " + text

func _on_spray_changed(current: int, maximum: int) -> void:
	spray_label.text = "스프레이: %d/%d" % [current, maximum]

func _on_hint_changed(text: String) -> void:
	if not is_instance_valid(hint_label):
		return
	hint_label.text = text
	hint_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
	hint_time = 1.8
