extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: PackedScene = load("res://scenes/Main.tscn")
	if scene == null:
		_fail("cannot load Main.tscn")
		_finish()
		return
	var main := scene.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	_check_rect_collider(main, "HomeSouthHedgeCollision", Vector2(560, 45))
	_check_rect_collider(main, "SafetyFenceRoadBlockCollision", Vector2(20, 2800))
	_check_rect_collider(main, "UpperEscapeLeftBoundaryCollision", Vector2(55, 500))
	_check_rect_collider(main, "UpperEscapeRightBoundaryCollision", Vector2(55, 500))
	_check_rect_collider(main, "FactoryApproachLeftBlockCollision", Vector2(35, 160))
	_check_rect_collider(main, "FactoryApproachRightBlockCollision", Vector2(35, 160))
	_check_rect_collider(main, "RescueNorthRoadblockCollision", Vector2(500, 45))
	_check_visual(main, "StoreShoppingBasket")
	_check_visual(main, "StoreCctvHousing")
	_check_visual(main, "FactoryWarningStripe0")
	_check_visual(main, "FactoryLockerRow")
	_check_visual(main, "RescueTireSkidA")
	_check_visual(main, "RescueRoadSignPlate")
	_check_dog_motion_atlas(main)
	_finish()

func _check_rect_collider(main: Node, node_name: String, min_size: Vector2) -> void:
	var body := main.get_node_or_null(node_name)
	if body == null:
		_fail("missing collider: " + node_name)
		return
	if not body is StaticBody2D:
		_fail("not a StaticBody2D: " + node_name)
		return
	var shape_node := _find_collision_shape(body)
	if shape_node == null:
		_fail("missing shape: " + node_name)
		return
	var rect := shape_node.shape as RectangleShape2D
	if rect == null:
		_fail("not a RectangleShape2D: " + node_name)
		return
	if rect.size.x < min_size.x or rect.size.y < min_size.y:
		_fail("collider too small: " + node_name)

func _find_collision_shape(node: Node) -> CollisionShape2D:
	for child in node.get_children():
		if child is CollisionShape2D:
			return child
	return null

func _check_visual(main: Node, node_name: String) -> void:
	if main.get_node_or_null(node_name) == null:
		_fail("missing visual detail: " + node_name)

func _check_dog_motion_atlas(main: Node) -> void:
	var baekgu := main.get_node_or_null("Baekgu")
	if baekgu == null:
		_fail("missing Baekgu node")
		return
	var animation := baekgu.get_node_or_null("MotionAtlas") as AnimatedSprite2D
	if animation == null:
		_fail("missing Baekgu motion atlas animation")
		return
	var frames := animation.sprite_frames
	var expected := {
		"idle-alert": 6,
		"run-to-protect": 8,
		"guard-block": 8,
		"bark-warning": 6,
		"bite-lunge": 6,
		"hurt-recover": 8,
	}
	for animation_name in expected.keys():
		if not frames.has_animation(animation_name):
			_fail("missing Baekgu animation: " + animation_name)
			continue
		if frames.get_frame_count(animation_name) != int(expected[animation_name]):
			_fail("wrong Baekgu frame count: " + animation_name)
			continue
		var frame_texture := frames.get_frame_texture(animation_name, 0) as AtlasTexture
		if frame_texture == null:
			_fail("Baekgu frame is not an AtlasTexture: " + animation_name)
			continue
		if frame_texture.region.size != Vector2(448, 640):
			_fail("Baekgu frame does not use a full 448x640 cell: " + animation_name)

func _fail(message: String) -> void:
	failures.append(message)

func _finish() -> void:
	if failures.size() > 0:
		for failure in failures:
			print("MAP_BOUNDS_FAIL: ", failure)
		quit(1)
		return
	print("MAP_BOUNDS_OK")
	quit(0)
