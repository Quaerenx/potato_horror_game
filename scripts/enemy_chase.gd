extends CharacterBody2D
class_name EnemyChase

@export var first_chase_speed := 132.0
@export var final_chase_speed := 158.0

const CREATURE_ATLAS_PATH := "res://assets/source/creatures/nightmare-creature-motion-atlas.png"
const CREATURE_VISUAL_SCALE := 0.22
const CELL_SIZE := Vector2(448, 640)
const CATCH_BACKUP_DISTANCE := 18.0
const CHASE_START_GRACE_TIME := 0.75

var target: Node2D
var active := false
var final_mode := false
var creature_sprite: AnimatedSprite2D
var catch_area: Area2D
var silhouette_mode := false
var catch_grace_timer := 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	visible = false
	_build_visual()
	_build_collision()
	_build_catch_area()

func setup(player: Node2D) -> void:
	target = player

func start_chase(is_final: bool) -> void:
	final_mode = is_final
	active = true
	visible = true
	catch_grace_timer = CHASE_START_GRACE_TIME
	if is_instance_valid(catch_area):
		catch_area.monitoring = false
	set_silhouette_mode(false)
	_play_animation("charge-towards")

func stop_chase() -> void:
	active = false
	velocity = Vector2.ZERO
	catch_grace_timer = 0.0
	visible = false
	if is_instance_valid(catch_area):
		catch_area.monitoring = false
	if is_instance_valid(creature_sprite):
		creature_sprite.stop()

func show_waiting_silhouette() -> void:
	active = false
	final_mode = false
	visible = true
	if is_instance_valid(catch_area):
		catch_area.monitoring = false
	set_silhouette_mode(true)
	_play_animation("idle-twitch")

func show_final_warning() -> void:
	active = false
	final_mode = true
	visible = true
	if is_instance_valid(catch_area):
		catch_area.monitoring = false
	set_silhouette_mode(false)
	_play_animation("scream")

func set_silhouette_mode(enabled: bool) -> void:
	silhouette_mode = enabled
	if not is_instance_valid(creature_sprite):
		return
	if enabled:
		creature_sprite.modulate = Color(0.02, 0.018, 0.025, 0.58)
	else:
		creature_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)

func stunned_by_spray() -> void:
	if final_mode:
		return
	active = false
	velocity = Vector2.ZERO
	if is_instance_valid(catch_area):
		catch_area.monitoring = false
	set_silhouette_mode(false)
	_play_animation("collapse")
	await get_tree().create_timer(0.35).timeout
	stop_chase()
	var manager := get_node_or_null("/root/GameManager")
	if manager != null:
		manager.finish_first_chase()

func _physics_process(delta: float) -> void:
	if not active or not is_instance_valid(target):
		velocity = Vector2.ZERO
		return
	if catch_grace_timer > 0.0:
		catch_grace_timer = maxf(0.0, catch_grace_timer - delta)
		if catch_grace_timer <= 0.0 and is_instance_valid(catch_area):
			catch_area.monitoring = true
	var to_target := target.global_position - global_position
	if catch_grace_timer <= 0.0 and to_target.length() <= CATCH_BACKUP_DISTANCE:
		_catch_player()
		return
	var speed := final_chase_speed if final_mode else first_chase_speed
	velocity = to_target.normalized() * speed
	_play_animation("charge-towards")
	move_and_slide()

func _build_visual() -> void:
	creature_sprite = AnimatedSprite2D.new()
	creature_sprite.name = "CreatureSprite"
	creature_sprite.sprite_frames = _build_sprite_frames()
	creature_sprite.scale = Vector2(CREATURE_VISUAL_SCALE, CREATURE_VISUAL_SCALE)
	creature_sprite.position = Vector2(0, -20)
	add_child(creature_sprite)

func _build_sprite_frames() -> SpriteFrames:
	var sheet: Texture2D = load(CREATURE_ATLAS_PATH)
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	_add_animation(frames, sheet, "idle-twitch", 0, 6, 8.33, true)
	_add_animation(frames, sheet, "stalk", 1, 8, 9.52, true)
	_add_animation(frames, sheet, "charge-towards", 2, 8, 11.76, true)
	_add_animation(frames, sheet, "claw-swipe", 3, 6, 11.76, false)
	_add_animation(frames, sheet, "scream", 4, 6, 10.53, false)
	_add_animation(frames, sheet, "collapse", 5, 8, 9.09, false)
	return frames

func _add_animation(frames: SpriteFrames, sheet: Texture2D, name: String, row: int, columns: int, fps: float, loop: bool) -> void:
	frames.add_animation(name)
	frames.set_animation_speed(name, fps)
	frames.set_animation_loop(name, loop)
	for column in range(columns):
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(column * CELL_SIZE.x, row * CELL_SIZE.y, CELL_SIZE.x, CELL_SIZE.y)
		frames.add_frame(name, atlas)

func _play_animation(name: String) -> void:
	if not is_instance_valid(creature_sprite):
		return
	if creature_sprite.animation != name or not creature_sprite.is_playing():
		creature_sprite.play(name)

func _build_collision() -> void:
	var shape := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 11.0
	capsule.height = 34.0
	shape.shape = capsule
	add_child(shape)

func _build_catch_area() -> void:
	catch_area = Area2D.new()
	catch_area.name = "CatchArea"
	catch_area.monitoring = false
	var shape := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 23.0
	capsule.height = 54.0
	shape.position = Vector2(0, -12)
	shape.shape = capsule
	catch_area.add_child(shape)
	catch_area.body_entered.connect(_on_catch_area_body_entered)
	add_child(catch_area)

func _on_catch_area_body_entered(body: Node) -> void:
	if not active or catch_grace_timer > 0.0 or not body.is_in_group("player"):
		return
	_catch_player()

func _catch_player() -> void:
	if not active:
		return
	active = false
	velocity = Vector2.ZERO
	if is_instance_valid(catch_area):
		catch_area.monitoring = false
	_play_animation("claw-swipe")
	var manager := get_node_or_null("/root/GameManager")
	if manager != null:
		manager.game_over()
