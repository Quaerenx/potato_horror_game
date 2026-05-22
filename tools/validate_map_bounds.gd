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
	_check_visual(main, "WorldOuterBackdrop")
	_check_visual(main, "WorldFarLeftForestMass")
	_check_visual(main, "WorldFarRightRoadDark")
	_check_visual(main, "OuterForestLumpL0")
	_check_visual(main, "OuterRoadCrack0")
	_check_visual(main, "StoreShoppingBasket")
	_check_visual(main, "StorePropDoorMatAsset")
	_check_visual(main, "StoreCctvHousing")
	_check_visual(main, "FactoryWarningStripe0")
	_check_visual(main, "FactoryBacksideBackgroundAsset")
	_check_visual(main, "FactoryBacksideSecurityLightBloom")
	_check_visual(main, "FactoryMachineAssetA")
	_check_visual(main, "FactoryLockerRow")
	_check_visual(main, "BushMazeFloor")
	_check_visual(main, "BushMazePathTileAsset0")
	_check_visual(main, "BushMazePathWash0")
	_check_visual(main, "BushMazeFlashlightReveal0")
	_check_visual(main, "PowerBoxCase")
	_check_visual(main, "KeyCat")
	_check_rect_collider(main, "BushMazeOuterLeftCollision", Vector2(45, 760))
	_check_rect_collider(main, "BushMazeOuterRightCollision", Vector2(45, 760))
	_check_rect_collider(main, "BushMazeNorthWallCollision", Vector2(500, 45))
	_check_rect_collider(main, "BushMazeDarknessBlocker", Vector2(380, 45))
	_check_bush_maze_corridor(main)
	_check_dog_motion_atlas(main)
	_check_key_cat(main)
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

func _check_bush_maze_corridor(main: Node) -> void:
	var wall_a := _get_rect_size(main, "BushMazeWallACollision")
	var wall_b := _get_rect_size(main, "BushMazeWallBCollision")
	var wall_c := _get_rect_size(main, "BushMazeWallCCollision")
	var wall_d := _get_rect_size(main, "BushMazeWallDCollision")
	var wall_e := _get_rect_size(main, "BushMazeWallECollision")
	if wall_a.x > 220 or wall_a.y > 42:
		_fail("BushMazeWallA leaves the entry corridor too tight")
	if wall_b.y > 150:
		_fail("BushMazeWallB closes the mid-maze gap")
	if wall_c.x > 180:
		_fail("BushMazeWallC blocks the turn too tightly")
	if wall_d.y > 180:
		_fail("BushMazeWallD blocks the cat clearing approach")
	if wall_e.x > 170:
		_fail("BushMazeWallE blocks the final cat clearing gap")

func _get_rect_size(main: Node, node_name: String) -> Vector2:
	var body := main.get_node_or_null(node_name)
	if body == null:
		_fail("missing collider: " + node_name)
		return Vector2.ZERO
	var shape_node := _find_collision_shape(body)
	if shape_node == null:
		_fail("missing shape: " + node_name)
		return Vector2.ZERO
	var rect := shape_node.shape as RectangleShape2D
	if rect == null:
		_fail("not a RectangleShape2D: " + node_name)
		return Vector2.ZERO
	return rect.size

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

func _check_key_cat(main: Node) -> void:
	var cat := main.get_node_or_null("KeyCat")
	if cat == null:
		_fail("missing KeyCat node")
		return
	var animation := cat.get_node_or_null("KeyCatSprite") as AnimatedSprite2D
	if animation == null:
		_fail("missing KeyCat animation sprite")
		return
	var frames := animation.sprite_frames
	if frames == null:
		_fail("missing KeyCat sprite frames")
		return
	for animation_name in ["idle-key", "walk-approach", "sniff-key", "startled"]:
		if not frames.has_animation(animation_name):
			_fail("missing KeyCat animation: " + animation_name)
			continue
		var frame_texture := frames.get_frame_texture(animation_name, 0) as AtlasTexture
		if frame_texture == null:
			_fail("KeyCat frame is not an AtlasTexture: " + animation_name)
			continue
		if frame_texture.region.size != Vector2(128, 128):
			_fail("KeyCat frame does not use a full 128x128 cell: " + animation_name)
	if animation.scale.x < 0.60:
		_fail("KeyCat visual scale is too small")

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
