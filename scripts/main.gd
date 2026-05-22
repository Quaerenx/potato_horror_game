extends Node2D

const PlayerScene := preload("res://scenes/Player.tscn")
const EnemyScene := preload("res://scenes/Enemy.tscn")
const CarScene := preload("res://scenes/BoyfriendCar.tscn")
const HudScene := preload("res://scenes/UI_HUD.tscn")
const DialogueScene := preload("res://scenes/UI_Dialogue.tscn")

const STORE_SPRITE_PATH := "res://assets/source/buildings/convenience-store-potato-style.png"
const BAEKGU_ATLAS_PATH := "res://assets/source/animals/baekgu-protector-motion-atlas.png"
const BAEKGU_ATLAS_WEBP_PATH := "res://assets/source/animals/baekgu-protector-motion-atlas.webp"
const BAEKGU_MOTION_MANIFEST_PATH := "res://assets/source/animals/baekgu-protector-motion-manifest.json"
const STORE_VISUAL_SCALE := 0.22
const BAEKGU_VISUAL_SCALE := 0.145
const BAEKGU_CELL_SIZE := Vector2i(448, 640)
const BAEKGU_ANIMATION_SPECS := {
	"idle-alert": {"row": 0, "frame_count": 6, "duration_ms": 120, "loop": true},
	"run-to-protect": {"row": 1, "frame_count": 8, "duration_ms": 80, "loop": true},
	"guard-block": {"row": 2, "frame_count": 8, "duration_ms": 95, "loop": true},
	"bark-warning": {"row": 3, "frame_count": 6, "duration_ms": 90, "loop": true},
	"bite-lunge": {"row": 4, "frame_count": 6, "duration_ms": 85, "loop": false},
	"hurt-recover": {"row": 5, "frame_count": 8, "duration_ms": 110, "loop": false},
}
const BAEKGU_STATE_TO_ANIMATION := {
	"idle": "idle-alert",
	"run": "run-to-protect",
	"guard": "guard-block",
	"bark": "bark-warning",
	"bite": "bite-lunge",
	"hurt": "hurt-recover",
}
const FINAL_ESCAPE_Y := -640.0
const FINAL_ESCAPE_LEFT_X := -145.0
const FINAL_ESCAPE_RIGHT_X := 145.0
const FINAL_CHASE_START_GAP := 320.0
const FIRST_CHASE_START_GAP := 260.0
const FACTORY_CHASE_DURATION := 40.0
const FACTORY_CHASE_SPEED := 138.0
const EXHAUSTED_CHASE_SPEED := 92.0
const STREETLIGHT_GLIMPSE_POSITION := Vector2(-118, -248)
const EVENT_TRIGGER_WIDTH := 900.0
const DOG_INTERVENTION_POSITION := Vector2(-18, -995)
const FACTORY_HIDE_POSITION := Vector2(-165, -1355)
const FACTORY_MONSTER_ENTRY_POSITION := Vector2(-150, -1235)
const FACTORY_EXIT_POSITION := Vector2(-70, -1850)
const EXHAUSTED_START_POSITION := Vector2(0, -1975)
const RESCUE_CAR_POSITION := Vector2(178, -2280)

var player: PlayerCharacter
var enemy: EnemyChase
var boyfriend_car: BoyfriendCar
var camera: CameraController
var ending_layer: CanvasLayer
var baekgu: Node2D
var baekgu_anim: AnimatedSprite2D
var baekgu_standing: AnimatedSprite2D
var baekgu_hurt: AnimatedSprite2D
var baekgu_hurt_mark: Polygon2D
var factory_exit_blocker: StaticBody2D
var factory_exit_shutter: Polygon2D
var triggers := {}
var streetlight_glow_layers: Array[Polygon2D] = []
var streetlight_lamp: Polygon2D
var streetlight_lamp_bloom: Polygon2D
var streetlight_flicker_phase := 0.0
var store_tv_glow: Polygon2D
var store_light_phase := 0.0
var tension_timer := 3.5
var tension_rng := RandomNumberGenerator.new()
var factory_timer := FACTORY_CHASE_DURATION
var last_factory_seconds := -1

const WALK_TO_STORE := 1
const SPRAY_USED := 3
const STORE_REACHED := 4
const FINAL_CHASE := 5
const DOG_INTERVENTION := 6
const FACTORY_APPROACH := 7
const FACTORY_HIDE := 8
const FACTORY_CHASE := 9
const EXHAUSTED_ESCAPE := 10

func _ready() -> void:
	tension_rng.randomize()
	_gm().register_main(self)
	_dm().load_dialogues()
	_build_world()
	_spawn_actors()
	_spawn_ui()
	_gm().set_spray_uses(1)
	_gm().transition_to(WALK_TO_STORE)
	_gm().set_checkpoint("START", player.global_position, WALK_TO_STORE)
	_dm().start_dialogue("intro_home")

func _spawn_actors() -> void:
	player = PlayerScene.instantiate()
	player.global_position = Vector2(0, 420)
	add_child(player)
	enemy = EnemyScene.instantiate()
	enemy.global_position = Vector2(0, 580)
	enemy.setup(player)
	add_child(enemy)
	var spray := SprayController.new()
	spray.setup(player, enemy)
	player.attach_spray_controller(spray)
	boyfriend_car = CarScene.instantiate()
	boyfriend_car.global_position = RESCUE_CAR_POSITION
	add_child(boyfriend_car)
	_build_baekgu()
	camera = CameraController.new()
	camera.name = "Camera2D"
	camera.enabled = true
	camera.zoom = Vector2(1.15, 1.15)
	player.add_child(camera)
	enemy.global_position = STREETLIGHT_GLIMPSE_POSITION
	enemy.stop_chase()

func _spawn_ui() -> void:
	add_child(HudScene.instantiate())
	add_child(DialogueScene.instantiate())

func _build_world() -> void:
	var canvas_modulate := CanvasModulate.new()
	canvas_modulate.color = Color(0.30, 0.34, 0.42, 1.0)
	add_child(canvas_modulate)
	_add_rect("WalkPath", Vector2(-18, -870), Vector2(330, 2960), Color(0.10, 0.11, 0.12, 1.0), false)
	_add_rect("DenseFoliageBase", Vector2(-380, -870), Vector2(430, 2960), Color(0.025, 0.075, 0.035, 1.0), false)
	_add_rect("Sidewalk", Vector2(188, -870), Vector2(92, 2960), Color(0.14, 0.14, 0.13, 1.0), false)
	_add_rect("CarRoad", Vector2(340, -870), Vector2(210, 2960), Color(0.055, 0.058, 0.065, 1.0), false)
	_add_rect("LeftFoliageWall", Vector2(-286, -340), Vector2(42, 1900), Color(0.02, 0.055, 0.025, 1.0), true)
	_add_rect("RoadEdgeMarker", Vector2(250, -340), Vector2(14, 1900), Color(0.09, 0.09, 0.085, 0.78), false)
	_add_rect("RightRoadBoundary", Vector2(488, -340), Vector2(52, 1900), Color(0.035, 0.038, 0.045, 1.0), true)
	_add_world_bounds()
	_add_dense_foliage()
	_add_safety_fence()
	_add_roadside_detail_pass()
	_add_rect("Home", Vector2(0, 510), Vector2(230, 130), Color(0.32, 0.23, 0.20, 1.0), true)
	_add_rect("HomeDoorGlow", Vector2(0, 435), Vector2(48, 16), Color(0.75, 0.58, 0.36, 0.85), false)
	_add_rect("OldHouse", Vector2(-105, -250), Vector2(110, 85), Color(0.13, 0.10, 0.09, 1.0), false)
	_add_streetlight(Vector2(58, -276))
	_add_rect("Bridge", Vector2(0, -430), Vector2(320, 52), Color(0.18, 0.17, 0.15, 1.0), false)
	_add_store_lighting(Vector2(0, -660))
	_add_store_sprite(Vector2(0, -735))
	_add_store_clues()
	_add_store_detail_pass()
	_add_payphone(Vector2(-152, -612))
	_add_store_clue_glints()
	_add_rect("ConvenienceStoreCollision", Vector2(0, -725), Vector2(235, 120), Color(0.55, 0.62, 0.70, 0.0), true)
	_add_store_door_glow(Vector2(0, -642))
	_add_factory_area()
	_add_rect("ExhaustedRoad", Vector2(0, -2115), Vector2(360, 360), Color(0.10, 0.10, 0.11, 1.0), false)
	_add_rect("RescueRoad", Vector2(0, -2265), Vector2(380, 140), Color(0.12, 0.12, 0.13, 1.0), false)
	_add_rescue_detail_pass()
	_add_world_label("집", Vector2(-12, 445))
	_add_world_label("편의점", Vector2(-42, -785))
	_add_world_label("폐공장", Vector2(-225, -1260))
	_add_interaction("home_door", Vector2(0, 430), 68.0, "문 열기")
	_add_interaction("fridge", Vector2(-80, 510), 58.0, "냉장고 확인")
	_add_interaction("mailbox", Vector2(95, 385), 58.0, "우편함 확인")
	_add_store_door(Vector2(0, -640), 78.0, "편의점 문 조사")
	_add_interaction("store_receipt", Vector2(-76, -594), 68.0, "영수증 확인")
	_add_interaction("store_footprints", Vector2(58, -585), 74.0, "발자국 확인")
	_add_interaction("store_window", Vector2(78, -706), 76.0, "창문 확인")
	_add_interaction("store_payphone", Vector2(-152, -612), 76.0, "공중전화 받기")
	_add_trigger("ambient_dog_bark", Vector2(0, 20), Vector2(EVENT_TRIGGER_WIDTH, 80), WALK_TO_STORE)
	_add_trigger("streetlight_glimpse", Vector2(0, -235), Vector2(EVENT_TRIGGER_WIDTH, 58), WALK_TO_STORE)
	_add_trigger("first_chase", Vector2(0, -340), Vector2(EVENT_TRIGGER_WIDTH, 80), WALK_TO_STORE)
	_add_trigger("store_arrival", Vector2(0, -555), Vector2(EVENT_TRIGGER_WIDTH, 80), SPRAY_USED)
	_add_trigger("dog_intervention", Vector2(0, -965), Vector2(EVENT_TRIGGER_WIDTH, 100), FINAL_CHASE)
	_add_trigger("factory_entry", Vector2(-150, -1215), Vector2(150, 115), FACTORY_APPROACH)
	_add_trigger("factory_exit", FACTORY_EXIT_POSITION, Vector2(160, 95), FACTORY_CHASE, false)
	_add_trigger("rescue_zone", Vector2(0, -2225), Vector2(EVENT_TRIGGER_WIDTH, 125), EXHAUSTED_ESCAPE)

func _add_rect(name: String, position: Vector2, size: Vector2, color: Color, collision: bool) -> Node2D:
	var visual := Polygon2D.new()
	visual.name = name
	visual.position = position
	visual.color = color
	var half := size * 0.5
	visual.polygon = PackedVector2Array([
		Vector2(-half.x, -half.y),
		Vector2(half.x, -half.y),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y),
	])
	add_child(visual)
	if collision:
		var body := StaticBody2D.new()
		body.name = name + "Collision"
		body.position = position
		var shape_node := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = size
		shape_node.shape = shape
		body.add_child(shape_node)
		add_child(body)
	return visual

func _add_polygon(name: String, position: Vector2, points: PackedVector2Array, color: Color) -> Polygon2D:
	var visual := Polygon2D.new()
	visual.name = name
	visual.position = position
	visual.color = color
	visual.polygon = points
	add_child(visual)
	return visual

func _add_line(name: String, points: PackedVector2Array, color: Color, width: float) -> Line2D:
	var line := Line2D.new()
	line.name = name
	line.points = points
	line.default_color = color
	line.width = width
	add_child(line)
	return line

func _add_ellipse(name: String, position: Vector2, radius: Vector2, color: Color, point_count := 32) -> Polygon2D:
	var points := PackedVector2Array()
	for index in range(point_count):
		var angle := TAU * float(index) / float(point_count)
		points.append(Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	return _add_polygon(name, position, points, color)

func _add_world_label(text: String, position: Vector2) -> void:
	var label := Label.new()
	label.text = text
	label.position = position
	label.add_theme_font_size_override("font_size", 20)
	add_child(label)

func _add_store_sprite(position: Vector2) -> void:
	var sprite := Sprite2D.new()
	sprite.name = "ConvenienceStoreSprite"
	sprite.texture = load(STORE_SPRITE_PATH)
	sprite.position = position
	sprite.scale = Vector2(STORE_VISUAL_SCALE, STORE_VISUAL_SCALE)
	add_child(sprite)

func _add_dense_foliage() -> void:
	for index in range(58):
		var y := 540 - index * 52
		var x := -335 - (index % 4) * 28
		_add_rect("FoliagePatch%d" % index, Vector2(x, y), Vector2(96, 42), Color(0.035, 0.13 + (index % 3) * 0.015, 0.055, 0.95), false)
		if index % 2 == 0:
			_add_rect("FoliageDark%d" % index, Vector2(x + 48, y - 18), Vector2(82, 32), Color(0.015, 0.07, 0.025, 0.95), false)

func _add_safety_fence() -> void:
	for index in range(46):
		var y := 540 - index * 70
		_add_rect("FencePost%d" % index, Vector2(235, y), Vector2(12, 48), Color(0.66, 0.68, 0.62, 1.0), false)
		_add_rect("FenceRailTop%d" % index, Vector2(235, y - 16), Vector2(46, 8), Color(0.76, 0.77, 0.70, 1.0), false)
		_add_rect("FenceRailBottom%d" % index, Vector2(235, y + 12), Vector2(46, 8), Color(0.58, 0.60, 0.54, 1.0), false)

func _add_world_bounds() -> void:
	_add_rect("HomeSouthHedge", Vector2(0, 652), Vector2(620, 58), Color(0.025, 0.085, 0.035, 1.0), true)
	_add_rect("HomeSouthHedgeShadow", Vector2(0, 618), Vector2(600, 18), Color(0.01, 0.018, 0.012, 0.48), false)
	_add_rect("SafetyFenceRoadBlock", Vector2(258, -870), Vector2(28, 2960), Color(0.052, 0.054, 0.050, 0.72), true)
	_add_rect("UpperEscapeLeftBoundary", Vector2(-238, -2130), Vector2(68, 545), Color(0.016, 0.045, 0.023, 1.0), true)
	_add_rect("UpperEscapeRightBoundary", Vector2(236, -2130), Vector2(68, 545), Color(0.026, 0.028, 0.033, 1.0), true)
	_add_rect("UpperEscapeLeftFoliageMass", Vector2(-315, -2130), Vector2(190, 560), Color(0.012, 0.050, 0.022, 0.98), false)
	_add_rect("UpperEscapeRoadShoulder", Vector2(194, -2130), Vector2(42, 545), Color(0.050, 0.052, 0.058, 0.92), false)
	_add_rect("FactoryApproachLeftBlock", Vector2(-318, -1168), Vector2(42, 184), Color(0.028, 0.055, 0.035, 1.0), true)
	_add_rect("FactoryApproachRightBlock", Vector2(34, -1168), Vector2(42, 184), Color(0.080, 0.077, 0.070, 1.0), true)
	_add_rect("RescueNorthRoadblock", Vector2(0, -2394), Vector2(560, 62), Color(0.018, 0.019, 0.024, 1.0), true)
	_add_rect("RescueNorthDarkness", Vector2(0, -2442), Vector2(680, 118), Color(0.006, 0.007, 0.012, 0.96), false)

func _add_roadside_detail_pass() -> void:
	var poles := [
		Vector2(212, 410),
		Vector2(212, 80),
		Vector2(212, -260),
		Vector2(212, -610),
		Vector2(204, -1015),
	]
	for index in range(poles.size()):
		var base: Vector2 = poles[index]
		_add_line("UtilityPole%d" % index, PackedVector2Array([base + Vector2(0, 72), base + Vector2(0, -82)]), Color(0.13, 0.11, 0.085, 1.0), 9.0)
		_add_line("UtilityPoleCrossbar%d" % index, PackedVector2Array([base + Vector2(-36, -50), base + Vector2(42, -50)]), Color(0.11, 0.09, 0.070, 1.0), 5.0)
		_add_ellipse("UtilityPoleInsulatorA%d" % index, base + Vector2(-28, -50), Vector2(5, 4), Color(0.55, 0.58, 0.52, 1.0), 10)
		_add_ellipse("UtilityPoleInsulatorB%d" % index, base + Vector2(30, -50), Vector2(5, 4), Color(0.55, 0.58, 0.52, 1.0), 10)
		if index > 0:
			var previous: Vector2 = poles[index - 1]
			_add_line("OverheadWireA%d" % index, PackedVector2Array([previous + Vector2(-28, -50), base + Vector2(-28, -50)]), Color(0.018, 0.018, 0.020, 0.80), 2.0)
			_add_line("OverheadWireB%d" % index, PackedVector2Array([previous + Vector2(30, -50), base + Vector2(30, -50)]), Color(0.018, 0.018, 0.020, 0.74), 2.0)
	for index in range(12):
		var y := 470 - index * 210
		_add_rect("RoadReflectorPost%d" % index, Vector2(292, y), Vector2(8, 34), Color(0.70, 0.70, 0.64, 1.0), false)
		_add_rect("RoadReflectorStripe%d" % index, Vector2(292, y - 9), Vector2(10, 5), Color(0.90, 0.20, 0.12, 0.95), false)
	_add_ellipse("PuddleNearBridge", Vector2(102, -392), Vector2(52, 15), Color(0.050, 0.070, 0.085, 0.62), 24)
	_add_ellipse("PuddleNearStore", Vector2(-126, -536), Vector2(42, 12), Color(0.048, 0.065, 0.078, 0.56), 22)
	_add_ellipse("TrashBagA", Vector2(-214, -705), Vector2(17, 13), Color(0.018, 0.020, 0.018, 1.0), 16)
	_add_ellipse("TrashBagB", Vector2(-188, -696), Vector2(14, 11), Color(0.024, 0.026, 0.024, 1.0), 16)
	_add_rect("DiscardedFlyer", Vector2(-120, -72), Vector2(30, 18), Color(0.72, 0.68, 0.52, 0.82), false)
	_add_rect("BentRoadSignPost", Vector2(185, -930), Vector2(6, 72), Color(0.33, 0.34, 0.32, 1.0), false)
	_add_rect("BentRoadSignPlate", Vector2(176, -970), Vector2(48, 24), Color(0.23, 0.25, 0.25, 1.0), false)

func _add_store_detail_pass() -> void:
	_add_rect("StoreSignFlickerStrip", Vector2(0, -795), Vector2(176, 12), Color(1.0, 0.72, 0.28, 0.32), false)
	_add_rect("StoreSignDeadTubeA", Vector2(-55, -795), Vector2(26, 5), Color(0.05, 0.045, 0.040, 0.88), false)
	_add_rect("StoreSignDeadTubeB", Vector2(62, -795), Vector2(22, 5), Color(0.05, 0.045, 0.040, 0.74), false)
	_add_rect("StoreWindowStickerA", Vector2(-78, -690), Vector2(18, 11), Color(0.92, 0.24, 0.18, 0.78), false)
	_add_rect("StoreWindowStickerB", Vector2(-52, -690), Vector2(18, 11), Color(0.17, 0.42, 0.84, 0.70), false)
	_add_rect("StoreDoorMat", Vector2(0, -598), Vector2(76, 20), Color(0.12, 0.08, 0.06, 0.92), false)
	_add_rect("StoreShoppingBasket", Vector2(122, -600), Vector2(38, 18), Color(0.75, 0.20, 0.12, 0.92), false)
	_add_line("StoreShoppingBasketHandle", PackedVector2Array([Vector2(105, -612), Vector2(122, -625), Vector2(139, -612)]), Color(0.82, 0.25, 0.16, 0.92), 3.0)
	_add_rect("StoreCctvHousing", Vector2(119, -765), Vector2(34, 16), Color(0.14, 0.15, 0.16, 1.0), false)
	_add_ellipse("StoreCctvLens", Vector2(132, -764), Vector2(5, 5), Color(0.03, 0.04, 0.05, 1.0), 10)
	_add_rect("StoreCartShadow", Vector2(154, -628), Vector2(42, 10), Color(0.018, 0.016, 0.014, 0.42), false)
	_add_line("StoreCartWireA", PackedVector2Array([Vector2(136, -642), Vector2(169, -642), Vector2(160, -622), Vector2(142, -622), Vector2(136, -642)]), Color(0.56, 0.58, 0.55, 0.85), 2.0)
	_add_ellipse("StoreCartWheelA", Vector2(145, -619), Vector2(3, 3), Color(0.04, 0.04, 0.04, 0.95), 8)
	_add_ellipse("StoreCartWheelB", Vector2(158, -619), Vector2(3, 3), Color(0.04, 0.04, 0.04, 0.95), 8)

func _add_factory_area() -> void:
	_add_rect("FactorySidePath", Vector2(-132, -1176), Vector2(260, 88), Color(0.083, 0.083, 0.078, 1.0), false)
	_add_rect("FactoryFloor", Vector2(-160, -1545), Vector2(540, 680), Color(0.075, 0.077, 0.082, 1.0), false)
	_add_rect("FactoryOilStainA", Vector2(-280, -1465), Vector2(105, 42), Color(0.025, 0.025, 0.030, 0.50), false)
	_add_rect("FactoryOilStainB", Vector2(-55, -1658), Vector2(140, 36), Color(0.025, 0.025, 0.030, 0.45), false)
	_add_rect("FactoryLeftWall", Vector2(-430, -1545), Vector2(34, 690), Color(0.12, 0.115, 0.105, 1.0), true)
	_add_rect("FactoryRightWall", Vector2(110, -1545), Vector2(34, 690), Color(0.12, 0.115, 0.105, 1.0), true)
	_add_rect("FactoryTopWallLeft", Vector2(-292, -1900), Vector2(242, 36), Color(0.12, 0.115, 0.105, 1.0), true)
	_add_rect("FactoryTopWallRight", Vector2(38, -1900), Vector2(140, 36), Color(0.12, 0.115, 0.105, 1.0), true)
	_add_rect("FactoryBottomWallLeft", Vector2(-332, -1205), Vector2(190, 34), Color(0.12, 0.115, 0.105, 1.0), true)
	_add_rect("FactoryBottomWallRight", Vector2(8, -1205), Vector2(196, 34), Color(0.12, 0.115, 0.105, 1.0), true)
	factory_exit_shutter = _add_rect("FactoryExitShutter", FACTORY_EXIT_POSITION + Vector2(0, -42), Vector2(118, 24), Color(0.20, 0.19, 0.16, 1.0), false) as Polygon2D
	factory_exit_blocker = _add_collision_rect("FactoryExitBlocker", FACTORY_EXIT_POSITION + Vector2(0, -42), Vector2(118, 24))
	_add_factory_obstacle("FactoryMachineA", Vector2(-310, -1395), Vector2(118, 74), Color(0.16, 0.17, 0.17, 1.0))
	_add_factory_obstacle("FactoryMachineB", Vector2(-82, -1488), Vector2(168, 62), Color(0.15, 0.16, 0.17, 1.0))
	_add_factory_obstacle("FactoryCrateLoopA", Vector2(-292, -1605), Vector2(94, 96), Color(0.17, 0.12, 0.075, 1.0))
	_add_factory_obstacle("FactoryConveyor", Vector2(-36, -1648), Vector2(180, 48), Color(0.12, 0.13, 0.14, 1.0))
	_add_factory_obstacle("FactoryShelfA", Vector2(-230, -1760), Vector2(150, 48), Color(0.145, 0.115, 0.085, 1.0))
	_add_factory_obstacle("FactoryPillarA", Vector2(-372, -1518), Vector2(42, 90), Color(0.11, 0.105, 0.10, 1.0))
	_add_factory_obstacle("FactoryPillarB", Vector2(42, -1370), Vector2(44, 94), Color(0.11, 0.105, 0.10, 1.0))
	_add_line("FactoryExitArrow", PackedVector2Array([FACTORY_EXIT_POSITION + Vector2(-42, 14), FACTORY_EXIT_POSITION + Vector2(0, -18), FACTORY_EXIT_POSITION + Vector2(42, 14)]), Color(0.55, 0.62, 0.58, 0.45), 4.0)
	_add_factory_detail_pass()

func _add_factory_detail_pass() -> void:
	for index in range(8):
		var x := -382 + index * 46
		_add_line("FactoryWarningStripe%d" % index, PackedVector2Array([Vector2(x, -1212), Vector2(x + 28, -1192)]), Color(0.72, 0.55, 0.18, 0.50), 4.0)
	_add_rect("FactoryLockerRow", Vector2(-386, -1715), Vector2(36, 122), Color(0.10, 0.13, 0.145, 1.0), false)
	_add_rect("FactoryLockerDoorA", Vector2(-386, -1748), Vector2(28, 2), Color(0.22, 0.26, 0.28, 0.85), false)
	_add_rect("FactoryLockerDoorB", Vector2(-386, -1718), Vector2(28, 2), Color(0.22, 0.26, 0.28, 0.85), false)
	_add_line("FactoryHangingChain", PackedVector2Array([Vector2(-112, -1882), Vector2(-112, -1808)]), Color(0.34, 0.33, 0.29, 0.78), 3.0)
	_add_ellipse("FactoryChainHook", Vector2(-112, -1799), Vector2(7, 9), Color(0.28, 0.27, 0.24, 0.80), 12)
	_add_rect("FactoryPalletA", Vector2(-292, -1832), Vector2(82, 18), Color(0.23, 0.15, 0.08, 0.92), false)
	_add_rect("FactoryPalletB", Vector2(-292, -1810), Vector2(82, 18), Color(0.20, 0.13, 0.07, 0.92), false)
	_add_ellipse("FactoryDrumA", Vector2(48, -1564), Vector2(18, 28), Color(0.13, 0.18, 0.20, 1.0), 18)
	_add_ellipse("FactoryDrumLidA", Vector2(48, -1590), Vector2(18, 6), Color(0.21, 0.25, 0.26, 1.0), 18)
	_add_line("FactorySteamLeak", PackedVector2Array([Vector2(-25, -1325), Vector2(-18, -1348), Vector2(-30, -1370), Vector2(-20, -1392)]), Color(0.70, 0.78, 0.78, 0.24), 5.0)
	_add_line("FactorySparkA", PackedVector2Array([Vector2(70, -1778), Vector2(84, -1792)]), Color(1.0, 0.72, 0.22, 0.82), 2.0)
	_add_line("FactorySparkB", PackedVector2Array([Vector2(82, -1775), Vector2(94, -1764)]), Color(0.90, 0.46, 0.16, 0.70), 2.0)

func _add_rescue_detail_pass() -> void:
	_add_line("RescueTireSkidA", PackedVector2Array([Vector2(82, -2318), Vector2(120, -2284), Vector2(156, -2264)]), Color(0.020, 0.020, 0.024, 0.62), 7.0)
	_add_line("RescueTireSkidB", PackedVector2Array([Vector2(110, -2332), Vector2(150, -2296), Vector2(186, -2276)]), Color(0.020, 0.020, 0.024, 0.50), 6.0)
	_add_ellipse("RescueDustHazeA", Vector2(78, -2230), Vector2(92, 22), Color(0.44, 0.41, 0.35, 0.13), 28)
	_add_ellipse("RescueDustHazeB", Vector2(180, -2220), Vector2(70, 18), Color(0.44, 0.41, 0.35, 0.10), 24)
	_add_line("RescueRoadSignPost", PackedVector2Array([Vector2(-192, -2315), Vector2(-192, -2250)]), Color(0.42, 0.43, 0.39, 0.95), 5.0)
	_add_rect("RescueRoadSignPlate", Vector2(-192, -2328), Vector2(54, 24), Color(0.18, 0.22, 0.25, 0.92), false)
	_add_ellipse("RescueHeadlightMist", Vector2(92, -2240), Vector2(160, 36), Color(0.92, 0.88, 0.58, 0.08), 32)

func _add_factory_obstacle(name: String, position: Vector2, size: Vector2, color: Color) -> void:
	_add_rect(name, position, size, color, true)
	_add_rect(name + "Highlight", position + Vector2(-size.x * 0.18, -size.y * 0.22), size * 0.34, Color(0.42, 0.43, 0.38, 0.18), false)

func _add_collision_rect(name: String, position: Vector2, size: Vector2) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.name = name
	body.position = position
	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	shape_node.shape = shape
	body.add_child(shape_node)
	add_child(body)
	return body

func _build_baekgu() -> void:
	baekgu = Node2D.new()
	baekgu.name = "Baekgu"
	baekgu.visible = false
	add_child(baekgu)
	var atlas_texture: Texture2D = load(BAEKGU_ATLAS_PATH)
	baekgu_anim = AnimatedSprite2D.new()
	baekgu_anim.name = "MotionAtlas"
	baekgu_anim.sprite_frames = _build_baekgu_sprite_frames(atlas_texture)
	baekgu_anim.scale = Vector2(BAEKGU_VISUAL_SCALE, BAEKGU_VISUAL_SCALE)
	baekgu_anim.visible = true
	baekgu.add_child(baekgu_anim)
	baekgu_standing = baekgu_anim
	baekgu_hurt = baekgu_anim
	baekgu_hurt_mark = _add_child_ellipse(baekgu, "HurtMark", Vector2(18, 18), Vector2(10, 5), Color(0.42, 0.055, 0.055, 0.72), 12)
	baekgu_hurt_mark.visible = false
	_show_baekgu_state("idle")

func _build_baekgu_sprite_frames(atlas_texture: Texture2D) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for animation_name in BAEKGU_ANIMATION_SPECS.keys():
		var spec: Dictionary = BAEKGU_ANIMATION_SPECS[animation_name]
		frames.add_animation(animation_name)
		frames.set_animation_loop(animation_name, bool(spec["loop"]))
		frames.set_animation_speed(animation_name, 1000.0 / float(spec["duration_ms"]))
		for frame_index in range(int(spec["frame_count"])):
			var frame_texture := AtlasTexture.new()
			frame_texture.atlas = atlas_texture
			frame_texture.region = Rect2(
				frame_index * BAEKGU_CELL_SIZE.x,
				int(spec["row"]) * BAEKGU_CELL_SIZE.y,
				BAEKGU_CELL_SIZE.x,
				BAEKGU_CELL_SIZE.y
			)
			frames.add_frame(animation_name, frame_texture)
	return frames

func _show_baekgu_state(state_name: String) -> void:
	var animation_name := str(BAEKGU_STATE_TO_ANIMATION.get(state_name, "idle-alert"))
	if is_instance_valid(baekgu_anim):
		baekgu_anim.visible = true
		if baekgu_anim.animation != animation_name:
			baekgu_anim.play(animation_name)
	if is_instance_valid(baekgu_hurt_mark):
		baekgu_hurt_mark.visible = state_name == "hurt"

func _add_child_rect(parent: Node2D, name: String, position: Vector2, size: Vector2, color: Color) -> Polygon2D:
	var half := size * 0.5
	return _add_child_polygon(parent, name, position, PackedVector2Array([
		Vector2(-half.x, -half.y),
		Vector2(half.x, -half.y),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y),
	]), color)

func _add_child_polygon(parent: Node2D, name: String, position: Vector2, points: PackedVector2Array, color: Color) -> Polygon2D:
	var visual := Polygon2D.new()
	visual.name = name
	visual.position = position
	visual.color = color
	visual.polygon = points
	parent.add_child(visual)
	return visual

func _add_child_ellipse(parent: Node2D, name: String, position: Vector2, radius: Vector2, color: Color, point_count := 18) -> Polygon2D:
	var points := PackedVector2Array()
	for index in range(point_count):
		var angle := TAU * float(index) / float(point_count)
		points.append(Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	return _add_child_polygon(parent, name, position, points, color)

func _add_child_line(parent: Node2D, name: String, points: PackedVector2Array, color: Color, width: float) -> Line2D:
	var line := Line2D.new()
	line.name = name
	line.points = points
	line.default_color = color
	line.width = width
	parent.add_child(line)
	return line

func _add_streetlight(position: Vector2) -> void:
	streetlight_glow_layers.clear()
	_add_ellipse("StreetlightGroundShadow", position + Vector2(-8, 116), Vector2(76, 18), Color(0.015, 0.015, 0.018, 0.36), 28)
	streetlight_glow_layers.append(_add_polygon("StreetlightGlowWide", position, PackedVector2Array([
		Vector2(-92, -46),
		Vector2(-8, -34),
		Vector2(114, 192),
		Vector2(-214, 192),
	]), Color(0.95, 0.87, 0.44, 0.06)))
	streetlight_glow_layers.append(_add_polygon("StreetlightGlowMid", position, PackedVector2Array([
		Vector2(-84, -44),
		Vector2(-18, -34),
		Vector2(62, 160),
		Vector2(-166, 164),
	]), Color(0.98, 0.90, 0.46, 0.10)))
	streetlight_glow_layers.append(_add_ellipse("StreetlightLightPool", position + Vector2(-58, 94), Vector2(138, 58), Color(0.96, 0.88, 0.45, 0.14), 36))
	_add_line("StreetlightPoleShadow", PackedVector2Array([position + Vector2(6, 94), position + Vector2(7, -45)]), Color(0.05, 0.052, 0.055, 0.72), 12.0)
	_add_line("StreetlightPole", PackedVector2Array([position + Vector2(0, 96), position + Vector2(0, -48)]), Color(0.16, 0.16, 0.15, 1.0), 8.0)
	_add_line("StreetlightPoleHighlight", PackedVector2Array([position + Vector2(-3, 88), position + Vector2(-3, -42)]), Color(0.33, 0.32, 0.27, 0.72), 2.0)
	_add_ellipse("StreetlightBase", position + Vector2(0, 100), Vector2(19, 8), Color(0.12, 0.12, 0.11, 1.0), 18)
	_add_line("StreetlightArm", PackedVector2Array([position + Vector2(0, -48), position + Vector2(-52, -64)]), Color(0.17, 0.17, 0.155, 1.0), 7.0)
	_add_line("StreetlightArmHighlight", PackedVector2Array([position + Vector2(-4, -51), position + Vector2(-48, -64)]), Color(0.38, 0.36, 0.28, 0.55), 2.0)
	_add_polygon("StreetlightLampHousing", position, PackedVector2Array([
		Vector2(-94, -70),
		Vector2(-45, -75),
		Vector2(-28, -62),
		Vector2(-40, -48),
		Vector2(-88, -48),
		Vector2(-102, -58),
	]), Color(0.105, 0.104, 0.095, 1.0))
	streetlight_lamp = _add_polygon("StreetlightLampGlass", position, PackedVector2Array([
		Vector2(-86, -57),
		Vector2(-43, -61),
		Vector2(-35, -55),
		Vector2(-45, -47),
		Vector2(-84, -48),
	]), Color(0.98, 0.91, 0.50, 0.92))
	streetlight_lamp_bloom = _add_ellipse("StreetlightLampBloom", position + Vector2(-62, -53), Vector2(52, 18), Color(0.97, 0.88, 0.42, 0.20), 24)

func _add_store_lighting(position: Vector2) -> void:
	_add_ellipse("StoreWarmHaloOuter", position + Vector2(0, -8), Vector2(224, 118), Color(0.96, 0.78, 0.36, 0.08), 40)
	_add_ellipse("StoreWarmHaloInner", position + Vector2(0, 4), Vector2(156, 76), Color(1.0, 0.86, 0.44, 0.14), 36)
	_add_polygon("StoreDoorLightSpill", position, PackedVector2Array([
		Vector2(-42, 8),
		Vector2(42, 8),
		Vector2(130, 112),
		Vector2(-130, 112),
	]), Color(1.0, 0.84, 0.44, 0.12))
	_add_ellipse("StoreLightPool", position + Vector2(0, 96), Vector2(150, 42), Color(1.0, 0.84, 0.42, 0.16), 32)
	_add_rect("StoreWindowGlowLeft", position + Vector2(-76, -24), Vector2(58, 24), Color(1.0, 0.90, 0.56, 0.22), false)
	_add_rect("StoreWindowGlowRight", position + Vector2(76, -24), Vector2(58, 24), Color(1.0, 0.90, 0.56, 0.20), false)

func _add_store_clues() -> void:
	_add_polygon("DroppedReceipt", Vector2(-76, -594), PackedVector2Array([
		Vector2(-15, -10),
		Vector2(18, -6),
		Vector2(12, 13),
		Vector2(-18, 8),
	]), Color(0.86, 0.83, 0.70, 0.94))
	_add_line("ReceiptInkA", PackedVector2Array([Vector2(-88, -595), Vector2(-66, -592)]), Color(0.15, 0.14, 0.12, 0.5), 1.5)
	_add_line("ReceiptInkB", PackedVector2Array([Vector2(-86, -589), Vector2(-70, -587)]), Color(0.15, 0.14, 0.12, 0.36), 1.0)
	for index in range(5):
		var y := -628 + index * 18
		var x := 34 + (index % 2) * 24
		_add_ellipse("StoreFootprint%d" % index, Vector2(x, y), Vector2(7, 12), Color(0.04, 0.035, 0.03, 0.44), 14)
	_add_line("FootprintTrailHint", PackedVector2Array([Vector2(46, -640), Vector2(82, -548)]), Color(0.05, 0.04, 0.035, 0.20), 2.0)
	store_tv_glow = _add_rect("StoreInteriorTvGlow", Vector2(78, -706), Vector2(52, 30), Color(0.42, 0.72, 0.95, 0.25), false) as Polygon2D
	_add_rect("StoreCounterShadow", Vector2(18, -690), Vector2(58, 15), Color(0.02, 0.018, 0.014, 0.34), false)

func _add_payphone(position: Vector2) -> void:
	_add_rect("PayphoneShadow", position + Vector2(8, 26), Vector2(58, 14), Color(0.02, 0.018, 0.02, 0.42), false)
	_add_rect("PayphoneBody", position, Vector2(42, 68), Color(0.10, 0.16, 0.23, 1.0), false)
	_add_rect("PayphoneGlass", position + Vector2(0, -10), Vector2(30, 26), Color(0.35, 0.58, 0.70, 0.34), false)
	_add_rect("PayphonePanel", position + Vector2(0, 18), Vector2(28, 18), Color(0.045, 0.055, 0.065, 1.0), false)
	_add_ellipse("PayphoneReceiver", position + Vector2(-10, 12), Vector2(5, 12), Color(0.018, 0.018, 0.020, 1.0), 12)
	_add_ellipse("PayphoneRedLamp", position + Vector2(14, -30), Vector2(5, 5), Color(0.95, 0.10, 0.08, 0.78), 14)

func _add_store_clue_glints() -> void:
	_add_clue_glint("ReceiptClueGlint", Vector2(-76, -594))
	_add_clue_glint("FootprintsClueGlint", Vector2(58, -585))
	_add_clue_glint("WindowClueGlint", Vector2(78, -706))
	_add_clue_glint("PayphoneClueGlint", Vector2(-152, -612))

func _add_clue_glint(name: String, position: Vector2) -> void:
	_add_ellipse(name + "Outer", position, Vector2(26, 26), Color(0.88, 0.96, 1.0, 0.12), 18)
	_add_ellipse(name + "Inner", position, Vector2(7, 7), Color(0.86, 0.95, 1.0, 0.50), 12)

func _add_store_door_glow(position: Vector2) -> void:
	_add_ellipse("StoreDoorGlowSoft", position + Vector2(0, 10), Vector2(58, 22), Color(0.68, 0.88, 1.0, 0.16), 24)
	_add_polygon("StoreDoorLightStripe", position, PackedVector2Array([
		Vector2(-29, -9),
		Vector2(29, -9),
		Vector2(22, 8),
		Vector2(-22, 8),
	]), Color(0.58, 0.82, 0.96, 0.35))

func _process(delta: float) -> void:
	if streetlight_glow_layers.is_empty() or not is_instance_valid(streetlight_lamp):
		return
	streetlight_flicker_phase += delta
	store_light_phase += delta
	var flicker := 0.55 + 0.45 * absf(sin(streetlight_flicker_phase * 9.0))
	if int(streetlight_flicker_phase * 5.0) % 7 == 0:
		flicker *= 0.28
	var glow_alphas := [0.035, 0.07, 0.10]
	for index in range(streetlight_glow_layers.size()):
		var glow := streetlight_glow_layers[index]
		if is_instance_valid(glow):
			glow.color = Color(0.95, 0.88, 0.42, glow_alphas[index] + flicker * glow_alphas[index])
	streetlight_lamp.color = Color(0.98, 0.92, 0.50, 0.55 + flicker * 0.45)
	if is_instance_valid(streetlight_lamp_bloom):
		streetlight_lamp_bloom.color = Color(0.97, 0.88, 0.42, 0.06 + flicker * 0.18)
	_update_store_clue_lights()
	_update_factory_chase(delta)
	_update_tension_events(delta)

func _update_store_clue_lights() -> void:
	if is_instance_valid(store_tv_glow):
		var tv_flicker := 0.16 + absf(sin(store_light_phase * 4.7)) * 0.18
		store_tv_glow.color = Color(0.42, 0.72, 0.95, tv_flicker)

func _update_tension_events(delta: float) -> void:
	var stage: int = _gm().stage
	if stage != WALK_TO_STORE and stage != SPRAY_USED and stage != STORE_REACHED and stage != FINAL_CHASE and stage != FACTORY_APPROACH and stage != FACTORY_CHASE and stage != EXHAUSTED_ESCAPE:
		return
	var dialogue := get_node_or_null("/root/DialogueManager")
	if dialogue != null and dialogue.is_active():
		return
	tension_timer -= delta
	if tension_timer > 0.0:
		return
	_run_tension_event(stage)
	tension_timer = tension_rng.randf_range(5.5, 10.0)

func _run_tension_event(stage: int) -> void:
	var manager := _gm()
	match stage:
		WALK_TO_STORE:
			var event := tension_rng.randi_range(0, 2)
			if event == 0:
				manager.show_hint("왼쪽 수풀에서 뭔가 스쳤다.")
				_audio().play_sfx("bush_rustle")
			elif event == 1:
				manager.show_hint("멀리서 한 박자 늦은 발소리가 들린다.")
				_audio().play_sfx("distant_step")
			else:
				manager.show_hint("가로등이 낮게 지직거린다.")
				_audio().play_sfx("streetlight")
		SPRAY_USED:
			manager.show_hint("아까의 발소리가 갑자기 끊겼다.")
			_audio().play_sfx("distant_step")
		STORE_REACHED:
			var store_event := tension_rng.randi_range(0, 2)
			if store_event == 0:
				manager.show_hint("편의점 문틈에서 아주 작은 딸깍 소리가 난다.")
				_audio().play_sfx("door_locked")
			elif store_event == 1:
				manager.show_hint("편의점 안쪽 TV 화면만 푸르게 흔들린다.")
				_audio().play_sfx("fluorescent")
			else:
				manager.show_hint("공중전화가 한 번 울리다 멈춘다.")
				_audio().play_sfx("phone_ring")
		FINAL_CHASE:
			manager.show_hint("숨소리가 귓가에 바짝 붙는다.")
			_audio().play_sfx("heartbeat")
		FACTORY_APPROACH:
			manager.show_hint("백구가 짖는 소리가 뒤쪽에서 갈라진다.")
			_audio().play_sfx("dog_whine")
		FACTORY_CHASE:
			var factory_event := tension_rng.randi_range(0, 1)
			if factory_event == 0:
				manager.show_hint("철제 선반이 덜컹이며 시야를 흔든다.")
				_audio().play_sfx("metal_clang")
			else:
				manager.show_hint("괴물의 손톱이 기계 외벽을 긁고 지나간다.")
				_audio().play_sfx("factory_alarm")
		EXHAUSTED_ESCAPE:
			manager.show_hint("숨이 목 끝까지 차오른다. 그래도 뛰어야 한다.")
			_audio().play_sfx("heartbeat")

func _update_factory_chase(delta: float) -> void:
	if _gm().stage != FACTORY_CHASE or _gm().factory_exit_open:
		return
	if _gm().player_locked:
		return
	factory_timer = maxf(0.0, factory_timer - delta)
	var seconds_left := int(ceilf(factory_timer))
	if seconds_left != last_factory_seconds:
		last_factory_seconds = seconds_left
		_gm().set_factory_chase_seconds_left(seconds_left)
	if factory_timer <= 0.0:
		_gm().finish_factory_timer()

func _add_interaction(id: String, position: Vector2, radius: float, prompt_text := "조사하기") -> void:
	var area := InteractionArea.new()
	area.interaction_id = id
	area.prompt = prompt_text
	area.position = position
	var shape_node := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = radius
	shape_node.shape = shape
	area.add_child(shape_node)
	add_child(area)

func _add_store_door(position: Vector2, radius: float, prompt_text := "편의점 문 조사") -> void:
	var door := ConvenienceStoreDoor.new()
	door.interaction_id = "store_door"
	door.prompt = prompt_text
	door.position = position
	var shape_node := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = radius
	shape_node.shape = shape
	door.add_child(shape_node)
	add_child(door)

func _add_trigger(id: String, position: Vector2, size: Vector2, required_stage: int, one_shot := true) -> void:
	var trigger := TriggerEvent.new()
	trigger.trigger_id = id
	trigger.required_stage = required_stage
	trigger.one_shot = one_shot
	trigger.position = position
	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	shape_node.shape = shape
	trigger.add_child(shape_node)
	add_child(trigger)
	triggers[id] = trigger

func run_streetlight_glimpse() -> void:
	if _gm().stage != WALK_TO_STORE or not is_instance_valid(enemy):
		return
	enemy.global_position = STREETLIGHT_GLIMPSE_POSITION
	enemy.show_waiting_silhouette()
	_audio().play_sfx("streetlight")
	if is_instance_valid(camera):
		camera.shake(0.18, 3.0)
	await get_tree().create_timer(0.24).timeout
	if _gm().stage == WALK_TO_STORE and is_instance_valid(enemy) and not enemy.active:
		enemy.stop_chase()

func prepare_first_chase() -> void:
	_gm().set_checkpoint("CP_1", Vector2(0, -130), WALK_TO_STORE)
	enemy.global_position = _get_first_chase_spawn_position()
	enemy.visible = true
	_audio().play_sfx("streetlight")
	if is_instance_valid(camera):
		camera.shake(0.35, 6.0)

func _get_first_chase_spawn_position() -> Vector2:
	if not is_instance_valid(player):
		return Vector2(0, -80)
	var spawn_x := clampf(player.global_position.x, -130.0, 130.0)
	return Vector2(spawn_x, player.global_position.y + FIRST_CHASE_START_GAP)

func prepare_final_chase() -> void:
	var escape_position := _get_final_chase_escape_position()
	_gm().set_player_locked(true)
	player.velocity = Vector2.ZERO
	enemy.global_position = escape_position + Vector2(0, FINAL_CHASE_START_GAP)
	enemy.final_chase_speed = 158.0
	enemy.show_final_warning()
	_audio().play_sfx("panic_step")
	if is_instance_valid(camera):
		camera.shake(0.45, 8.0)
	var retreat := create_tween()
	retreat.tween_property(player, "global_position", escape_position, 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await retreat.finished
	await get_tree().create_timer(0.12).timeout
	_gm().set_player_locked(false)

func run_dog_intervention() -> void:
	stop_enemy()
	player.velocity = Vector2.ZERO
	var player_position := player.global_position
	if player_position.y > -920.0:
		player_position = DOG_INTERVENTION_POSITION
		player.global_position = player_position
	enemy.global_position = player_position + Vector2(8, 128)
	enemy.show_final_warning()
	baekgu.visible = true
	_show_baekgu_state("run")
	baekgu.global_position = player_position + Vector2(-220, 12)
	_audio().play_sfx("dog_bark")
	if is_instance_valid(camera):
		camera.shake(0.32, 7.0)
	var rush := create_tween()
	rush.tween_property(baekgu, "global_position", player_position + Vector2(-28, 86), 0.38).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await rush.finished
	_show_baekgu_state("bark")
	_audio().play_sfx("dog_bark")
	await get_tree().create_timer(0.18).timeout
	_show_baekgu_state("guard")
	await get_tree().create_timer(0.16).timeout
	_show_baekgu_state("bite")
	baekgu.global_position = player_position + Vector2(-16, 92)
	_audio().play_sfx("metal_clang")
	if is_instance_valid(camera):
		camera.shake(0.45, 9.0)
	await get_tree().create_timer(0.42).timeout
	_show_baekgu_state("hurt")
	baekgu.global_position = player_position + Vector2(-42, 98)
	_audio().play_sfx("dog_whine")
	await get_tree().create_timer(0.38).timeout

func prepare_factory_approach() -> void:
	enemy.show_final_warning()
	enemy.global_position = player.global_position + Vector2(0, 150)
	enemy.final_chase_speed = 0.0
	_gm().show_hint("왼쪽 샛길의 폐공장으로 뛰어!")
	if triggers.has("factory_entry"):
		triggers["factory_entry"].reset()

func enter_factory_hide() -> void:
	stop_enemy()
	close_factory_exit()
	factory_timer = FACTORY_CHASE_DURATION
	last_factory_seconds = -1
	player.global_position = FACTORY_HIDE_POSITION
	player.velocity = Vector2.ZERO
	player.walk_speed = 105.0
	player.sprint_speed = 165.0
	_audio().play_sfx("door_locked")
	if is_instance_valid(camera):
		camera.shake(0.20, 4.0)

func start_factory_chase_sequence() -> void:
	close_factory_exit()
	factory_timer = FACTORY_CHASE_DURATION
	last_factory_seconds = -1
	player.walk_speed = 105.0
	player.sprint_speed = 165.0
	enemy.final_chase_speed = FACTORY_CHASE_SPEED
	enemy.global_position = FACTORY_MONSTER_ENTRY_POSITION
	enemy.show_final_warning()
	_audio().play_sfx("factory_alarm")
	if is_instance_valid(camera):
		camera.shake(0.35, 8.0)
	await get_tree().create_timer(0.55).timeout
	enemy.start_chase(true)
	_gm().show_hint("구조물을 돌아 시간을 벌자. 40초만 버티면 출구가 열린다.")

func open_factory_exit() -> void:
	if is_instance_valid(factory_exit_shutter):
		factory_exit_shutter.visible = false
	if is_instance_valid(factory_exit_blocker):
		factory_exit_blocker.queue_free()
		factory_exit_blocker = null
	if triggers.has("factory_exit"):
		triggers["factory_exit"].reset()

func close_factory_exit() -> void:
	if is_instance_valid(factory_exit_shutter):
		factory_exit_shutter.visible = true
	if not is_instance_valid(factory_exit_blocker):
		factory_exit_blocker = _add_collision_rect("FactoryExitBlocker", FACTORY_EXIT_POSITION + Vector2(0, -42), Vector2(118, 24))

func run_exhausted_escape() -> void:
	stop_enemy()
	player.global_position = EXHAUSTED_START_POSITION
	player.velocity = Vector2.ZERO
	player.walk_speed = 78.0
	player.sprint_speed = 112.0
	_audio().play_sfx("heartbeat")
	if is_instance_valid(camera):
		camera.shake(0.24, 5.0)
	await get_tree().create_timer(0.25).timeout

func start_exhausted_run() -> void:
	enemy.final_chase_speed = EXHAUSTED_CHASE_SPEED
	enemy.global_position = player.global_position + Vector2(0, 260)
	enemy.start_chase(true)
	if triggers.has("rescue_zone"):
		triggers["rescue_zone"].reset()
	_gm().show_hint("멀리서 자동차 경적이 들린다. 그쪽으로!")

func _get_final_chase_escape_position() -> Vector2:
	var side_x := FINAL_ESCAPE_LEFT_X
	if is_instance_valid(player) and player.global_position.x > 0.0:
		side_x = FINAL_ESCAPE_RIGHT_X
	return Vector2(side_x, FINAL_ESCAPE_Y)

func activate_enemy(is_final: bool) -> void:
	enemy.start_chase(is_final)

func stop_enemy() -> void:
	if is_instance_valid(enemy):
		enemy.stop_chase()

func set_store_checkpoint() -> void:
	_gm().set_checkpoint("CP_2", Vector2(0, -570), STORE_REACHED)

func restore_checkpoint(position: Vector2, restore_stage: int) -> void:
	player.global_position = position
	stop_enemy()
	if restore_stage == WALK_TO_STORE and triggers.has("first_chase"):
		triggers["first_chase"].reset()
	if restore_stage == WALK_TO_STORE and triggers.has("streetlight_glimpse"):
		triggers["streetlight_glimpse"].reset()
	if restore_stage == STORE_REACHED:
		_gm().set_spray_uses(0)
	elif restore_stage == FACTORY_CHASE:
		_gm().set_spray_uses(0)
		player.walk_speed = 105.0
		player.sprint_speed = 165.0
		close_factory_exit()
		factory_timer = FACTORY_CHASE_DURATION
		last_factory_seconds = -1
		enemy.final_chase_speed = FACTORY_CHASE_SPEED
		enemy.global_position = FACTORY_MONSTER_ENTRY_POSITION
		enemy.start_chase(true)
	else:
		_gm().set_spray_uses(1)

func run_rescue() -> void:
	stop_enemy()
	player.walk_speed = 105.0
	player.sprint_speed = 165.0
	boyfriend_car.global_position = RESCUE_CAR_POSITION
	boyfriend_car.show_rescue_scene()
	_audio().play_sfx("rescue_honk")
	if is_instance_valid(camera):
		camera.shake(0.25, 5.0)

func show_ending_screen() -> void:
	if is_instance_valid(ending_layer):
		return
	ending_layer = CanvasLayer.new()
	ending_layer.layer = 30
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.02, 0.018, 0.025, 0.92)
	backdrop.anchor_right = 1.0
	backdrop.anchor_bottom = 1.0
	ending_layer.add_child(backdrop)
	var title := Label.new()
	title.text = "END\n오늘의 간식은 무사히 도착했습니다."
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.anchor_left = 0.2
	title.anchor_top = 0.28
	title.anchor_right = 0.8
	title.anchor_bottom = 0.72
	title.add_theme_font_size_override("font_size", 36)
	ending_layer.add_child(title)
	add_child(ending_layer)

func _gm() -> Node:
	return get_node("/root/GameManager")

func _dm() -> Node:
	return get_node("/root/DialogueManager")

func _audio() -> Node:
	return get_node("/root/AudioManager")
