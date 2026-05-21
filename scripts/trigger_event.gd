extends Area2D
class_name TriggerEvent

@export var trigger_id := ""
@export var one_shot := true
@export var required_stage := -1

var used := false

func reset() -> void:
	used = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if used and one_shot:
		return
	if not body.is_in_group("player"):
		return
	var manager := get_node_or_null("/root/GameManager")
	if manager == null:
		return
	if required_stage >= 0 and manager.stage != required_stage:
		return
	used = true
	manager.handle_trigger(trigger_id)
