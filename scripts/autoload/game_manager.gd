extends Node

signal stage_changed(stage: int)
signal objective_changed(text: String)
signal spray_changed(current: int, maximum: int)
signal player_lock_changed(locked: bool)
signal hint_changed(text: String)

enum GameStage {
	INTRO_HOME = 0,
	WALK_TO_STORE = 1,
	FIRST_THREAT = 2,
	SPRAY_USED = 3,
	STORE_REACHED = 4,
	FINAL_CHASE = 5,
	RESCUE = 6,
	ENDING = 7,
	GAME_OVER = 8,
}

const MAX_SPRAY_USES := 1

var stage: int = GameStage.INTRO_HOME
var spray_uses := MAX_SPRAY_USES
var player_locked := false
var main_node: Node
var checkpoint_id := "START"
var checkpoint_position := Vector2.ZERO
var checkpoint_stage: int = GameStage.INTRO_HOME

func register_main(node: Node) -> void:
	main_node = node

func set_player_locked(locked: bool) -> void:
	player_locked = locked
	emit_signal("player_lock_changed", locked)

func set_spray_uses(value: int) -> void:
	spray_uses = clampi(value, 0, MAX_SPRAY_USES)
	emit_signal("spray_changed", spray_uses, MAX_SPRAY_USES)

func show_hint(text: String) -> void:
	emit_signal("hint_changed", text)

func transition_to(next_stage: int) -> void:
	stage = next_stage
	emit_signal("stage_changed", stage)
	emit_signal("objective_changed", get_objective_for_stage(stage))

func get_objective_for_stage(value: int) -> String:
	match value:
		GameStage.INTRO_HOME:
			return "밖으로 나가자"
		GameStage.WALK_TO_STORE:
			return "편의점에 가자"
		GameStage.FIRST_THREAT:
			return "도망치자!"
		GameStage.SPRAY_USED:
			return "편의점까지 가자"
		GameStage.STORE_REACHED:
			return "편의점 문을 조사하자"
		GameStage.FINAL_CHASE:
			return "도망쳐!"
		GameStage.RESCUE:
			return "차 쪽으로 가자"
		GameStage.ENDING:
			return ""
		GameStage.GAME_OVER:
			return "다시 해보자"
	return ""

func set_checkpoint(id: String, position: Vector2, restore_stage: int) -> void:
	checkpoint_id = id
	checkpoint_position = position
	checkpoint_stage = restore_stage

func handle_interaction(interaction_id: String) -> void:
	match interaction_id:
		"home_door":
			if stage == GameStage.INTRO_HOME:
				_dialogue_manager().start_dialogue("leave_home", Callable(self, "_after_home_door"))
			else:
				_dialogue_manager().start_dialogue("home_locked")
		"fridge":
			_dialogue_manager().start_dialogue("fridge")
		"mailbox":
			_dialogue_manager().start_dialogue("mailbox")
		_:
			_dialogue_manager().start_lines([
				{"speaker": "시스템", "text": "밤공기만 조용히 지나간다."}
			])

func _after_home_door() -> void:
	transition_to(GameStage.WALK_TO_STORE)

func handle_store_door() -> void:
	if stage == GameStage.STORE_REACHED:
		_audio_manager().play_sfx("door_locked")
		_dialogue_manager().start_dialogue("store_locked", Callable(self, "start_final_chase"))
	else:
		_dialogue_manager().start_dialogue("store_not_ready")

func handle_trigger(trigger_id: String) -> void:
	match trigger_id:
		"first_chase":
			if stage == GameStage.WALK_TO_STORE:
				start_first_chase()
		"store_arrival":
			if stage == GameStage.SPRAY_USED:
				mark_store_reached()
		"rescue_zone":
			if stage == GameStage.FINAL_CHASE:
				start_rescue()
		"ambient_dog_bark":
			if stage == GameStage.WALK_TO_STORE:
				_dialogue_manager().start_dialogue("ambient_dog_bark")

func start_first_chase() -> void:
	transition_to(GameStage.FIRST_THREAT)
	if is_instance_valid(main_node):
		main_node.prepare_first_chase()
	_dialogue_manager().start_dialogue("first_chase_hint", Callable(self, "_activate_first_chase"))

func _activate_first_chase() -> void:
	_audio_manager().play_sfx("chase_start")
	if is_instance_valid(main_node):
		main_node.activate_enemy(false)

func finish_first_chase() -> void:
	if stage != GameStage.FIRST_THREAT:
		return
	transition_to(GameStage.SPRAY_USED)
	if is_instance_valid(main_node):
		main_node.stop_enemy()
	_dialogue_manager().start_dialogue("spray_success")

func mark_store_reached() -> void:
	transition_to(GameStage.STORE_REACHED)
	if is_instance_valid(main_node):
		main_node.set_store_checkpoint()
	_dialogue_manager().start_dialogue("store_arrival")

func start_final_chase() -> void:
	transition_to(GameStage.FINAL_CHASE)
	if is_instance_valid(main_node):
		await main_node.prepare_final_chase()
		_audio_manager().play_sfx("chase_start")
		main_node.activate_enemy(true)

func start_rescue() -> void:
	transition_to(GameStage.RESCUE)
	if is_instance_valid(main_node):
		main_node.run_rescue()
	_dialogue_manager().start_dialogue("ending", Callable(self, "finish_ending"))

func finish_ending() -> void:
	transition_to(GameStage.ENDING)
	set_player_locked(true)
	if is_instance_valid(main_node):
		main_node.show_ending_screen()

func game_over() -> void:
	if stage == GameStage.GAME_OVER or stage == GameStage.RESCUE or stage == GameStage.ENDING:
		return
	_audio_manager().play_sfx("game_over")
	transition_to(GameStage.GAME_OVER)
	if is_instance_valid(main_node):
		main_node.stop_enemy()
	_dialogue_manager().start_dialogue("game_over", Callable(self, "restore_checkpoint"))

func restore_checkpoint() -> void:
	transition_to(checkpoint_stage)
	set_player_locked(false)
	if is_instance_valid(main_node):
		main_node.restore_checkpoint(checkpoint_position, checkpoint_stage)

func _dialogue_manager() -> Node:
	return get_node("/root/DialogueManager")

func _audio_manager() -> Node:
	return get_node("/root/AudioManager")
