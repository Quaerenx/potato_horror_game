extends Node2D
class_name BoyfriendCar

const CAR_VISUAL_SCALE := 0.45
const CHARACTER_VISUAL_SCALE := 0.33
const CELL_SIZE := Vector2(192, 208)
const CAR_PATH := "res://assets/source/vehicles/potato-style-car-front-3q.png"
const BOYFRIEND_SHEET_PATH := "res://assets/source/characters/boyfriend_spritesheet.webp"

var car_sprite: Sprite2D
var headlights: Polygon2D
var boyfriend_sprite: AnimatedSprite2D

func _ready() -> void:
	visible = false
	_build_car()
	_build_headlights()
	_build_boyfriend()
	var honk := AudioStreamPlayer2D.new()
	honk.name = "HonkAudio"
	add_child(honk)

func show_rescue_scene() -> void:
	visible = true
	car_sprite.modulate = Color.WHITE
	headlights.visible = true
	boyfriend_sprite.visible = true
	boyfriend_sprite.play("waving")

func _build_car() -> void:
	car_sprite = Sprite2D.new()
	car_sprite.name = "CarSprite"
	car_sprite.texture = load(CAR_PATH)
	car_sprite.scale = Vector2(CAR_VISUAL_SCALE, CAR_VISUAL_SCALE)
	add_child(car_sprite)

func _build_headlights() -> void:
	headlights = Polygon2D.new()
	headlights.name = "Headlights"
	headlights.color = Color(1.0, 0.92, 0.55, 0.34)
	headlights.polygon = PackedVector2Array([
		Vector2(-250, -30),
		Vector2(-30, -10),
		Vector2(-30, 30),
		Vector2(-250, 90),
	])
	headlights.visible = false
	add_child(headlights)

func _build_boyfriend() -> void:
	boyfriend_sprite = AnimatedSprite2D.new()
	boyfriend_sprite.name = "BoyfriendCharacter"
	boyfriend_sprite.sprite_frames = _build_sprite_frames()
	boyfriend_sprite.scale = Vector2(CHARACTER_VISUAL_SCALE, CHARACTER_VISUAL_SCALE)
	boyfriend_sprite.position = Vector2(80, -8)
	boyfriend_sprite.visible = false
	add_child(boyfriend_sprite)

func _build_sprite_frames() -> SpriteFrames:
	var sheet: Texture2D = load(BOYFRIEND_SHEET_PATH)
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	_add_animation(frames, sheet, "idle", 0, 6, 5.0, true)
	_add_animation(frames, sheet, "waving", 3, 4, 6.0, true)
	_add_animation(frames, sheet, "waiting", 6, 6, 5.0, true)
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
