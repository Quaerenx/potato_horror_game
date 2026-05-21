extends CanvasLayer

var objective_label: Label
var spray_label: Label
var hint_label: Label
var interaction_panel: ColorRect
var interaction_label: Label
var hint_time := 0.0

func _ready() -> void:
	layer = 10
	_build_ui()
	var manager := get_node_or_null("/root/GameManager")
	if manager != null:
		manager.objective_changed.connect(_on_objective_changed)
		manager.spray_changed.connect(_on_spray_changed)
		manager.hint_changed.connect(_on_hint_changed)
		manager.interaction_prompt_changed.connect(_on_interaction_prompt_changed)
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
	interaction_panel = ColorRect.new()
	interaction_panel.name = "InteractionPromptPanel"
	interaction_panel.color = Color(0.02, 0.025, 0.03, 0.78)
	interaction_panel.anchor_left = 0.5
	interaction_panel.anchor_right = 0.5
	interaction_panel.anchor_top = 1.0
	interaction_panel.anchor_bottom = 1.0
	interaction_panel.offset_left = -150.0
	interaction_panel.offset_right = 150.0
	interaction_panel.offset_top = -88.0
	interaction_panel.offset_bottom = -48.0
	interaction_panel.visible = false
	add_child(interaction_panel)
	interaction_label = Label.new()
	interaction_label.name = "InteractionPrompt"
	interaction_label.anchor_left = 0.5
	interaction_label.anchor_right = 0.5
	interaction_label.anchor_top = 1.0
	interaction_label.anchor_bottom = 1.0
	interaction_label.offset_left = -136.0
	interaction_label.offset_right = 136.0
	interaction_label.offset_top = -80.0
	interaction_label.offset_bottom = -54.0
	interaction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interaction_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	interaction_label.add_theme_font_size_override("font_size", 19)
	interaction_label.visible = false
	add_child(interaction_label)

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

func _on_interaction_prompt_changed(text: String) -> void:
	var has_prompt := not text.is_empty()
	if is_instance_valid(interaction_panel):
		interaction_panel.visible = has_prompt
	if is_instance_valid(interaction_label):
		interaction_label.text = text
		interaction_label.visible = has_prompt
