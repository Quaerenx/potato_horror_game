extends Area2D
class_name InteractionArea

@export var interaction_id := ""
@export var prompt := "조사하기"

func _ready() -> void:
	add_to_group("interactable")
	if get_child_count() == 0:
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 30.0
		shape.shape = circle
		add_child(shape)

func interact(_player: Node) -> void:
	var manager := get_node_or_null("/root/GameManager")
	if manager != null:
		manager.handle_interaction(interaction_id)
