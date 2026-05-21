extends CharacterBody2D
class_name PlayerCharacter

const CHARACTER_VISUAL_SCALE := 0.33
const CELL_SIZE := Vector2(192, 208)
const SHEET_PATH := "res://assets/source/characters/hero_spritesheet.webp"
const FOOTSTEP_INTERVAL := 0.34

@export var walk_speed := 105.0
@export var sprint_speed := 165.0

var sprite: AnimatedSprite2D
var interaction_detector: Area2D
var spray_controller: SprayController
var current_interactable: Node
var last_direction := Vector2.UP
var footstep_timer := 0.0

func _ready() -> void:
	add_to_group("player")
	_ensure_input_actions()
	_build_collision()
	_build_sprite()
	_build_interaction_detector()

func attach_spray_controller(controller: SprayController) -> void:
	spray_controller = controller
	add_child(controller)

func _physics_process(_delta: float) -> void:
	var direction := Vector2.ZERO
	var manager := _game_manager()
	var dialogue := _dialogue_manager()
	var locked := false
	var in_dialogue := false
	if manager != null:
		locked = manager.player_locked
	if dialogue != null:
		in_dialogue = dialogue.is_active()
	if not locked and not in_dialogue:
		direction = _read_direction()
	if direction.length() > 0.0:
		direction = direction.normalized()
		last_direction = direction
	var speed := sprint_speed if _is_sprint_pressed() else walk_speed
	velocity = direction * speed
	move_and_slide()
	_update_animation(direction)
	_update_footsteps(direction, _delta)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return
	if event.is_action_pressed("interact"):
		var dialogue := _dialogue_manager()
		if dialogue != null and dialogue.is_active():
			dialogue.advance()
		elif is_instance_valid(current_interactable) and current_interactable.has_method("interact"):
			current_interactable.interact(self)
	elif event.is_action_pressed("spray"):
		if is_instance_valid(spray_controller):
			spray_controller.try_use()

func _read_direction() -> Vector2:
	var direction := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)
	return direction

func _is_sprint_pressed() -> bool:
	return Input.is_action_pressed("sprint")

func _ensure_input_actions() -> void:
	_add_key_action("move_left", [KEY_A, KEY_LEFT])
	_add_key_action("move_right", [KEY_D, KEY_RIGHT])
	_add_key_action("move_up", [KEY_W, KEY_UP])
	_add_key_action("move_down", [KEY_S, KEY_DOWN])
	_add_key_action("sprint", [KEY_SHIFT])
	_add_key_action("interact", [KEY_E])
	_add_key_action("spray", [KEY_F, KEY_SPACE])

func _add_key_action(action_name: String, keys: Array[int]) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for keycode in keys:
		var already_bound := false
		for event in InputMap.action_get_events(action_name):
			if event is InputEventKey and event.keycode == keycode:
				already_bound = true
				break
		if already_bound:
			continue
		var key_event := InputEventKey.new()
		key_event.keycode = keycode
		InputMap.action_add_event(action_name, key_event)

func _build_collision() -> void:
	var shape := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 10.0
	capsule.height = 26.0
	shape.shape = capsule
	add_child(shape)

func _build_interaction_detector() -> void:
	interaction_detector = Area2D.new()
	interaction_detector.name = "InteractionDetector"
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 42.0
	shape.shape = circle
	interaction_detector.add_child(shape)
	interaction_detector.area_entered.connect(_on_interaction_area_entered)
	interaction_detector.area_exited.connect(_on_interaction_area_exited)
	add_child(interaction_detector)

func _build_sprite() -> void:
	sprite = AnimatedSprite2D.new()
	sprite.name = "AnimatedSprite2D"
	sprite.sprite_frames = _build_sprite_frames(SHEET_PATH)
	sprite.scale = Vector2(CHARACTER_VISUAL_SCALE, CHARACTER_VISUAL_SCALE)
	sprite.play("idle")
	add_child(sprite)

func _build_sprite_frames(path: String) -> SpriteFrames:
	var sheet: Texture2D = load(path)
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	_add_animation(frames, sheet, "idle", 0, 6, 5.0, true)
	_add_animation(frames, sheet, "running_right", 1, 8, 10.0, true)
	_add_animation(frames, sheet, "running_left", 2, 8, 10.0, true)
	_add_animation(frames, sheet, "running", 7, 6, 10.0, true)
	_add_animation(frames, sheet, "failed", 5, 8, 8.0, true)
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

func _update_animation(direction: Vector2) -> void:
	if direction.length() <= 0.01:
		if sprite.animation != "idle":
			sprite.play("idle")
		return
	if absf(direction.x) > absf(direction.y):
		if direction.x > 0.0:
			sprite.play("running_right")
		else:
			sprite.play("running_left")
	else:
		sprite.play("running")

func _update_footsteps(direction: Vector2, delta: float) -> void:
	if direction.length() <= 0.01:
		footstep_timer = 0.0
		return
	footstep_timer -= delta
	if footstep_timer > 0.0:
		return
	var interval := FOOTSTEP_INTERVAL
	if _is_sprint_pressed():
		interval *= 0.72
	footstep_timer = interval
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.play_sfx("footstep")

func _on_interaction_area_entered(area: Area2D) -> void:
	if area.is_in_group("interactable"):
		current_interactable = area

func _on_interaction_area_exited(area: Area2D) -> void:
	if current_interactable == area:
		current_interactable = null

func _game_manager() -> Node:
	return get_node_or_null("/root/GameManager")

func _dialogue_manager() -> Node:
	return get_node_or_null("/root/DialogueManager")
