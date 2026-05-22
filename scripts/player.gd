extends CharacterBody2D
class_name PlayerCharacter

const CHARACTER_VISUAL_SCALE := 0.33
const CELL_SIZE := Vector2(192, 208)
const SHEET_PATH := "res://assets/source/characters/hero_spritesheet.webp"
const FLASHLIGHT_BEAM_TEXTURE_PATH := "res://assets/source/environment/flashlight-beam-texture.png"
const FLASHLIGHT_DUST_TEXTURE_PATH := "res://assets/source/environment/flashlight-dust-overlay.png"
const FOOTSTEP_INTERVAL := 0.34
const INTERACTION_DETECTOR_RADIUS := 82.0

@export var walk_speed := 105.0
@export var sprint_speed := 165.0

var sprite: AnimatedSprite2D
var flashlight_cone: Sprite2D
var flashlight_pool: Sprite2D
var flashlight_dust: Sprite2D
var interaction_detector: Area2D
var spray_controller: SprayController
var current_interactable: Area2D
var nearby_interactables: Array[Area2D] = []
var last_prompt_text := ""
var last_direction := Vector2.UP
var footstep_timer := 0.0

func _ready() -> void:
	add_to_group("player")
	_ensure_input_actions()
	_build_collision()
	_build_flashlight()
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
	_update_flashlight()
	_update_footsteps(direction, _delta)
	_refresh_current_interactable(not locked and not in_dialogue)

func set_flashlight_enabled(enabled: bool) -> void:
	if is_instance_valid(flashlight_cone):
		flashlight_cone.visible = enabled
	if is_instance_valid(flashlight_pool):
		flashlight_pool.visible = enabled
	if is_instance_valid(flashlight_dust):
		flashlight_dust.visible = enabled

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return
	if event.is_action_pressed("interact"):
		var dialogue := _dialogue_manager()
		if dialogue != null and dialogue.is_active():
			dialogue.advance()
		elif is_instance_valid(current_interactable) and current_interactable.has_method("interact"):
			current_interactable.interact(self)
		else:
			var manager := _game_manager()
			if manager != null:
				manager.show_hint("조사할 수 있는 대상에 조금 더 가까이 가자.")
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
	circle.radius = INTERACTION_DETECTOR_RADIUS
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
	sprite.z_index = 3
	sprite.play("idle")
	add_child(sprite)

func _build_flashlight() -> void:
	flashlight_pool = _make_flashlight_sprite(
		"FlashlightNearPool",
		FLASHLIGHT_DUST_TEXTURE_PATH,
		Vector2(0, -76),
		Vector2(0.16, 0.11),
		Color(1.0, 0.94, 0.62, 0.24),
		1
	)
	flashlight_cone = _make_flashlight_sprite(
		"FlashlightCone",
		FLASHLIGHT_BEAM_TEXTURE_PATH,
		Vector2(0, -173),
		Vector2(0.225, 0.225),
		Color(1.0, 0.96, 0.68, 0.84),
		1
	)
	flashlight_dust = _make_flashlight_sprite(
		"FlashlightDust",
		FLASHLIGHT_DUST_TEXTURE_PATH,
		Vector2(0, -176),
		Vector2(0.26, 0.34),
		Color(0.88, 0.82, 0.66, 0.42),
		2
	)

func _make_flashlight_sprite(name: String, path: String, local_position: Vector2, visual_scale: Vector2, tint: Color, z_layer: int) -> Sprite2D:
	var light := Sprite2D.new()
	light.name = name
	light.texture = load(path)
	light.position = local_position
	light.scale = visual_scale
	light.modulate = tint
	light.z_index = z_layer
	light.visible = false
	light.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	light.material = _make_flashlight_material()
	add_child(light)
	return light

func _make_flashlight_material() -> CanvasItemMaterial:
	var material := CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	return material

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

func _update_flashlight() -> void:
	if not is_instance_valid(flashlight_cone) or not flashlight_cone.visible:
		return
	var rotation_angle := last_direction.angle() + PI * 0.5
	flashlight_cone.rotation = rotation_angle
	if is_instance_valid(flashlight_pool):
		flashlight_pool.rotation = rotation_angle
	if is_instance_valid(flashlight_dust):
		flashlight_dust.rotation = rotation_angle

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
		if not nearby_interactables.has(area):
			nearby_interactables.append(area)
		_refresh_current_interactable()

func _on_interaction_area_exited(area: Area2D) -> void:
	nearby_interactables.erase(area)
	_refresh_current_interactable()

func _refresh_current_interactable(show_prompt := true) -> void:
	var best_area: Area2D
	var best_distance := 999999999.0
	for area in nearby_interactables.duplicate():
		if not is_instance_valid(area) or not area.is_inside_tree() or not area.is_in_group("interactable"):
			nearby_interactables.erase(area)
			continue
		var distance := global_position.distance_squared_to(area.global_position)
		if distance < best_distance:
			best_distance = distance
			best_area = area
	current_interactable = best_area
	_update_interaction_prompt(show_prompt)

func _update_interaction_prompt(show_prompt: bool) -> void:
	var prompt_text := ""
	if show_prompt and is_instance_valid(current_interactable):
		prompt_text = "E: " + _get_interactable_prompt(current_interactable)
	if prompt_text == last_prompt_text:
		return
	last_prompt_text = prompt_text
	var manager := _game_manager()
	if manager != null and manager.has_method("set_interaction_prompt"):
		manager.set_interaction_prompt(prompt_text)

func _get_interactable_prompt(area: Area2D) -> String:
	var prompt_value = area.get("prompt")
	if typeof(prompt_value) == TYPE_STRING and not str(prompt_value).is_empty():
		return str(prompt_value)
	return "조사하기"

func _game_manager() -> Node:
	return get_node_or_null("/root/GameManager")

func _dialogue_manager() -> Node:
	return get_node_or_null("/root/DialogueManager")
