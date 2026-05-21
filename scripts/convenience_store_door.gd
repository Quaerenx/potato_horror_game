extends InteractionArea
class_name ConvenienceStoreDoor

func interact(_player: Node) -> void:
	var manager := get_node_or_null("/root/GameManager")
	if manager != null:
		manager.handle_store_door()
