extends CanvasLayer

var panel: ColorRect
var speaker_label: Label
var text_label: Label
var hint_label: Label

func _ready() -> void:
	layer = 20
	_build_ui()
	hide_dialogue()
	var dialogue := get_node_or_null("/root/DialogueManager")
	if dialogue != null:
		dialogue.register_ui(self)

func _build_ui() -> void:
	panel = ColorRect.new()
	panel.color = Color(0.015, 0.012, 0.018, 0.86)
	panel.anchor_left = 0.09
	panel.anchor_top = 0.70
	panel.anchor_right = 0.91
	panel.anchor_bottom = 0.95
	add_child(panel)
	speaker_label = Label.new()
	speaker_label.anchor_left = 0.11
	speaker_label.anchor_top = 0.72
	speaker_label.anchor_right = 0.89
	speaker_label.anchor_bottom = 0.77
	speaker_label.add_theme_font_size_override("font_size", 22)
	add_child(speaker_label)
	text_label = Label.new()
	text_label.anchor_left = 0.11
	text_label.anchor_top = 0.78
	text_label.anchor_right = 0.89
	text_label.anchor_bottom = 0.89
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.add_theme_font_size_override("font_size", 24)
	add_child(text_label)
	hint_label = Label.new()
	hint_label.anchor_left = 0.11
	hint_label.anchor_top = 0.90
	hint_label.anchor_right = 0.89
	hint_label.anchor_bottom = 0.94
	hint_label.text = "E: 다음"
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint_label.add_theme_font_size_override("font_size", 16)
	add_child(hint_label)

func show_line(speaker: String, text: String) -> void:
	panel.visible = true
	speaker_label.visible = true
	text_label.visible = true
	hint_label.visible = true
	speaker_label.text = "[" + speaker + "]"
	text_label.text = text

func hide_dialogue() -> void:
	panel.visible = false
	speaker_label.visible = false
	text_label.visible = false
	hint_label.visible = false
