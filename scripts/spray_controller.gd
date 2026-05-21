extends Node
class_name SprayController

const SPRAY_RANGE := 135.0
const COOLDOWN := 0.5

var player: Node2D
var enemy: Node
var cooldown_left := 0.0

func _process(delta: float) -> void:
	if cooldown_left > 0.0:
		cooldown_left = maxf(0.0, cooldown_left - delta)

func setup(owner_player: Node2D, chase_enemy: Node) -> void:
	player = owner_player
	enemy = chase_enemy

func try_use() -> void:
	var manager := _game_manager()
	if manager == null:
		return
	var dialogue := _dialogue_manager()
	if cooldown_left > 0.0 or (dialogue != null and dialogue.is_active()):
		return
	cooldown_left = COOLDOWN
	if manager.spray_uses <= 0:
		_show_spray_effect(false)
		manager.show_hint("스프레이가 없다...!")
		_audio_manager().play_sfx("spray_empty")
		return
	if not is_instance_valid(player) or not is_instance_valid(enemy):
		_show_spray_effect(false)
		_audio_manager().play_sfx("spray_empty")
		return
	if not enemy.active or enemy.final_mode:
		_show_spray_effect(false)
		manager.show_hint("지금은 뿌릴 대상이 없다.")
		_audio_manager().play_sfx("spray_empty")
		return
	var to_enemy: Vector2 = enemy.global_position - player.global_position
	if to_enemy.length() > SPRAY_RANGE:
		_show_spray_effect(false, to_enemy.normalized())
		manager.show_hint("아직 너무 멀다.")
		_audio_manager().play_sfx("spray_miss")
		return
	_show_spray_effect(true, to_enemy.normalized())
	_audio_manager().play_sfx("spray")
	manager.set_spray_uses(manager.spray_uses - 1)
	enemy.stunned_by_spray()

func _show_spray_effect(success: bool, override_direction := Vector2.ZERO) -> void:
	if not is_instance_valid(player):
		return
	var root := player.get_parent()
	if root == null:
		return
	var facing: Vector2 = override_direction
	if facing.length() <= 0.01:
		facing = player.last_direction
	if facing.length() <= 0.01:
		facing = Vector2.UP
	facing = facing.normalized()
	var origin := player.global_position + facing * 18.0
	var puff_count := 9 if success else 4
	for index in range(puff_count):
		var puff := Polygon2D.new()
		puff.name = "SprayPuff"
		var alpha := 0.48 - index * 0.035 if success else 0.24 - index * 0.035
		puff.color = Color(0.92, 0.93, 0.72, maxf(0.06, alpha))
		var half_size := Vector2(6 + index * 2, 3 + index)
		puff.polygon = PackedVector2Array([
			Vector2(-half_size.x, -half_size.y),
			Vector2(half_size.x, -half_size.y),
			Vector2(half_size.x, half_size.y),
			Vector2(-half_size.x, half_size.y),
		])
		var center_offset := float(puff_count - 1) * 0.5
		var spread := Vector2(-facing.y, facing.x) * ((index - center_offset) * 7.0)
		puff.global_position = origin + facing * (index * 11.0) + spread
		root.add_child(puff)
		var tween := puff.create_tween()
		tween.tween_property(puff, "modulate:a", 0.0, 0.22)
		tween.parallel().tween_property(puff, "scale", Vector2(1.8, 1.8), 0.22)
		tween.tween_callback(puff.queue_free)

func _game_manager() -> Node:
	return get_node_or_null("/root/GameManager")

func _dialogue_manager() -> Node:
	return get_node_or_null("/root/DialogueManager")

func _audio_manager() -> Node:
	return get_node("/root/AudioManager")
