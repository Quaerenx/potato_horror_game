extends Node

signal stage_changed(stage: int)
signal objective_changed(text: String)
signal spray_changed(current: int, maximum: int)
signal player_lock_changed(locked: bool)
signal hint_changed(text: String)
signal interaction_prompt_changed(text: String)

enum GameStage {
	INTRO_HOME = 0,
	WALK_TO_STORE = 1,
	FIRST_THREAT = 2,
	SPRAY_USED = 3,
	STORE_REACHED = 4,
	FINAL_CHASE = 5,
	DOG_INTERVENTION = 6,
	FACTORY_APPROACH = 7,
	FACTORY_HIDE = 8,
	FACTORY_CHASE = 9,
	EXHAUSTED_ESCAPE = 10,
	RESCUE = 11,
	ENDING = 12,
	GAME_OVER = 13,
}

const MAX_SPRAY_USES := 1
const FACTORY_CHASE_DURATION := 40
const STORE_CLUE_IDS := [
	"store_receipt",
	"store_footprints",
	"store_window",
	"store_payphone",
]
const STORE_CLUE_LABELS := {
	"store_receipt": "영수증",
	"store_footprints": "발자국",
	"store_window": "창문/CCTV",
	"store_payphone": "공중전화",
}

var stage: int = GameStage.INTRO_HOME
var spray_uses := MAX_SPRAY_USES
var player_locked := false
var main_node: Node
var checkpoint_id := "START"
var checkpoint_position := Vector2.ZERO
var checkpoint_stage: int = GameStage.INTRO_HOME
var store_clues_found := {}
var store_investigation_started := false
var store_completion_dialogue_shown := false
var factory_chase_seconds_left := FACTORY_CHASE_DURATION
var factory_exit_open := false

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

func set_interaction_prompt(text: String) -> void:
	emit_signal("interaction_prompt_changed", text)

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
			return "도망치며 스프레이를 준비하자"
		GameStage.SPRAY_USED:
			return "불 켜진 편의점까지 가자"
		GameStage.STORE_REACHED:
			return _get_store_objective()
		GameStage.FINAL_CHASE:
			return "어둠을 피해 계속 도망쳐!"
		GameStage.DOG_INTERVENTION:
			return "백구가 시간을 벌고 있다"
		GameStage.FACTORY_APPROACH:
			return "샛길의 폐공장 안으로 도망쳐!"
		GameStage.FACTORY_HIDE:
			return "공장 안에 몸을 숨기자"
		GameStage.FACTORY_CHASE:
			return _get_factory_chase_objective()
		GameStage.EXHAUSTED_ESCAPE:
			return "숨이 차도 멈추지 말자"
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
		"store_receipt", "store_footprints", "store_window", "store_payphone":
			_handle_store_clue(interaction_id)
		_:
			_dialogue_manager().start_lines([
				{"speaker": "시스템", "text": "밤공기만 조용히 지나간다."}
			])

func _after_home_door() -> void:
	transition_to(GameStage.WALK_TO_STORE)

func _handle_store_clue(interaction_id: String) -> void:
	if stage != GameStage.STORE_REACHED:
		if stage == GameStage.FINAL_CHASE:
			show_hint("지금은 볼 시간이 없다. 뛰어!")
			return
		_dialogue_manager().start_dialogue("store_not_ready")
		return
	if interaction_id == "store_payphone":
		_audio_manager().play_sfx("phone_ring")
	var was_new := not store_clues_found.has(interaction_id)
	store_clues_found[interaction_id] = true
	if was_new:
		_dialogue_manager().start_dialogue(interaction_id, Callable(self, "_after_store_clue"))
	else:
		_dialogue_manager().start_dialogue("store_clue_repeat")

func _after_store_clue() -> void:
	_update_store_objective()
	if _is_store_investigation_complete():
		_audio_manager().play_sfx("fluorescent")
		if not store_completion_dialogue_shown:
			store_completion_dialogue_shown = true
			_dialogue_manager().start_dialogue("store_clues_complete")
		return
	show_hint("단서 %d/%d 확인. 남은 단서: %s" % [_store_clue_count(), STORE_CLUE_IDS.size(), _get_next_missing_clue_label()])

func _get_store_objective() -> String:
	if _is_store_investigation_complete():
		return "편의점 문을 조사하자"
	return "편의점 주변 단서 조사 (%d/%d) - 다음: %s" % [_store_clue_count(), STORE_CLUE_IDS.size(), _get_next_missing_clue_label()]

func _update_store_objective() -> void:
	if stage == GameStage.STORE_REACHED:
		emit_signal("objective_changed", _get_store_objective())

func _store_clue_count() -> int:
	var count := 0
	for clue_id in STORE_CLUE_IDS:
		if store_clues_found.has(clue_id):
			count += 1
	return count

func _is_store_investigation_complete() -> bool:
	return _store_clue_count() >= STORE_CLUE_IDS.size()

func _get_next_missing_clue_label() -> String:
	for clue_id in STORE_CLUE_IDS:
		if not store_clues_found.has(clue_id):
			return str(STORE_CLUE_LABELS.get(clue_id, clue_id))
	return "문"

func handle_store_door() -> void:
	if stage == GameStage.FINAL_CHASE:
		show_hint("문은 잊어. 차 불빛 쪽으로 뛰어!")
		return
	if stage == GameStage.STORE_REACHED:
		if not _is_store_investigation_complete():
			_audio_manager().play_sfx("door_locked")
			_dialogue_manager().start_dialogue("store_not_ready", Callable(self, "_update_store_objective"))
			return
		_audio_manager().play_sfx("door_locked")
		_dialogue_manager().start_dialogue("store_locked", Callable(self, "start_final_chase"))
	else:
		_dialogue_manager().start_dialogue("store_not_ready")

func handle_trigger(trigger_id: String) -> void:
	match trigger_id:
		"first_chase":
			if stage == GameStage.WALK_TO_STORE:
				start_first_chase()
		"streetlight_glimpse":
			if stage == GameStage.WALK_TO_STORE and is_instance_valid(main_node):
				main_node.run_streetlight_glimpse()
		"store_arrival":
			if stage == GameStage.SPRAY_USED:
				mark_store_reached()
		"dog_intervention":
			if stage == GameStage.FINAL_CHASE:
				start_dog_intervention()
		"factory_entry":
			if stage == GameStage.FACTORY_APPROACH:
				start_factory_hide()
		"factory_exit":
			if stage == GameStage.FACTORY_CHASE:
				if factory_exit_open:
					start_exhausted_escape()
				else:
					show_hint("아직 나갈 수 없어. 조금만 더 버티자.")
		"rescue_zone":
			if stage == GameStage.EXHAUSTED_ESCAPE:
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
	_audio_manager().set_bgm_intensity(0.62)
	if is_instance_valid(main_node):
		main_node.stop_enemy()
	_dialogue_manager().start_dialogue("spray_success")

func mark_store_reached() -> void:
	transition_to(GameStage.STORE_REACHED)
	if not store_investigation_started:
		store_clues_found.clear()
		store_investigation_started = true
		store_completion_dialogue_shown = false
	_audio_manager().set_bgm_intensity(0.72)
	if is_instance_valid(main_node):
		main_node.set_store_checkpoint()
	_dialogue_manager().start_dialogue("store_arrival", Callable(self, "_update_store_objective"))

func start_final_chase() -> void:
	transition_to(GameStage.FINAL_CHASE)
	factory_exit_open = false
	factory_chase_seconds_left = FACTORY_CHASE_DURATION
	_audio_manager().set_bgm_intensity(1.0)
	if is_instance_valid(main_node):
		await main_node.prepare_final_chase()
		_audio_manager().play_sfx("chase_start")
		main_node.activate_enemy(true)

func start_dog_intervention() -> void:
	transition_to(GameStage.DOG_INTERVENTION)
	set_player_locked(true)
	_audio_manager().play_sfx("dog_bark")
	_audio_manager().set_bgm_intensity(0.92)
	if is_instance_valid(main_node):
		await main_node.run_dog_intervention()
	_dialogue_manager().start_dialogue("dog_intervention", Callable(self, "start_factory_approach"))

func start_factory_approach() -> void:
	transition_to(GameStage.FACTORY_APPROACH)
	set_player_locked(false)
	if is_instance_valid(main_node):
		main_node.prepare_factory_approach()

func start_factory_hide() -> void:
	transition_to(GameStage.FACTORY_HIDE)
	set_player_locked(true)
	factory_exit_open = false
	factory_chase_seconds_left = FACTORY_CHASE_DURATION
	_audio_manager().set_bgm_intensity(0.86)
	if is_instance_valid(main_node):
		main_node.enter_factory_hide()
	_dialogue_manager().start_dialogue("factory_hide", Callable(self, "start_factory_chase"))

func start_factory_chase() -> void:
	transition_to(GameStage.FACTORY_CHASE)
	factory_exit_open = false
	set_factory_chase_seconds_left(FACTORY_CHASE_DURATION)
	set_checkpoint("CP_FACTORY", Vector2(-165, -1355), GameStage.FACTORY_CHASE)
	set_player_locked(true)
	_audio_manager().set_bgm_intensity(1.0)
	if is_instance_valid(main_node):
		await main_node.start_factory_chase_sequence()
	set_player_locked(false)

func set_factory_chase_seconds_left(seconds_left: int) -> void:
	factory_chase_seconds_left = clampi(seconds_left, 0, FACTORY_CHASE_DURATION)
	if stage == GameStage.FACTORY_CHASE:
		emit_signal("objective_changed", get_objective_for_stage(stage))

func finish_factory_timer() -> void:
	if stage != GameStage.FACTORY_CHASE or factory_exit_open:
		return
	factory_exit_open = true
	set_factory_chase_seconds_left(0)
	show_hint("출구 셔터가 열렸다. 지금 나가!")
	_audio_manager().play_sfx("metal_clang")
	if is_instance_valid(main_node):
		main_node.open_factory_exit()

func _get_factory_chase_objective() -> String:
	if factory_exit_open:
		return "공장 출구로 탈출하자"
	return "공장 안에서 40초 버티기 (%02d초)" % factory_chase_seconds_left

func start_exhausted_escape() -> void:
	transition_to(GameStage.EXHAUSTED_ESCAPE)
	set_player_locked(true)
	_audio_manager().set_bgm_intensity(0.92)
	if is_instance_valid(main_node):
		await main_node.run_exhausted_escape()
	_dialogue_manager().start_dialogue("exhausted_escape", Callable(self, "_activate_exhausted_run"))

func _activate_exhausted_run() -> void:
	set_player_locked(false)
	_audio_manager().play_sfx("rescue_honk_far")
	if is_instance_valid(main_node):
		main_node.start_exhausted_run()

func start_rescue() -> void:
	transition_to(GameStage.RESCUE)
	_audio_manager().set_bgm_intensity(0.35)
	if is_instance_valid(main_node):
		main_node.run_rescue()
	_dialogue_manager().start_dialogue("ending", Callable(self, "finish_ending"))

func finish_ending() -> void:
	transition_to(GameStage.ENDING)
	_audio_manager().set_bgm_intensity(0.0)
	set_player_locked(true)
	if is_instance_valid(main_node):
		main_node.show_ending_screen()

func game_over() -> void:
	if stage == GameStage.GAME_OVER or stage == GameStage.RESCUE or stage == GameStage.ENDING:
		return
	_audio_manager().play_sfx("game_over")
	_audio_manager().set_bgm_intensity(0.45)
	transition_to(GameStage.GAME_OVER)
	if is_instance_valid(main_node):
		main_node.stop_enemy()
	_dialogue_manager().start_dialogue("game_over", Callable(self, "restore_checkpoint"))

func restore_checkpoint() -> void:
	transition_to(checkpoint_stage)
	_set_bgm_for_stage(checkpoint_stage)
	set_player_locked(false)
	if is_instance_valid(main_node):
		main_node.restore_checkpoint(checkpoint_position, checkpoint_stage)
	if stage == GameStage.STORE_REACHED:
		_update_store_objective()
	elif stage == GameStage.FACTORY_CHASE:
		factory_exit_open = false
		set_factory_chase_seconds_left(FACTORY_CHASE_DURATION)

func _set_bgm_for_stage(value: int) -> void:
	match value:
		GameStage.WALK_TO_STORE:
			_audio_manager().set_bgm_intensity(0.55)
		GameStage.STORE_REACHED:
			_audio_manager().set_bgm_intensity(0.72)
		GameStage.FINAL_CHASE:
			_audio_manager().set_bgm_intensity(1.0)
		GameStage.DOG_INTERVENTION, GameStage.FACTORY_APPROACH, GameStage.FACTORY_HIDE:
			_audio_manager().set_bgm_intensity(0.86)
		GameStage.FACTORY_CHASE:
			_audio_manager().set_bgm_intensity(1.0)
		GameStage.EXHAUSTED_ESCAPE:
			_audio_manager().set_bgm_intensity(0.92)
		GameStage.RESCUE:
			_audio_manager().set_bgm_intensity(0.35)
		GameStage.ENDING:
			_audio_manager().set_bgm_intensity(0.0)
		_:
			_audio_manager().set_bgm_intensity(0.55)

func _dialogue_manager() -> Node:
	return get_node("/root/DialogueManager")

func _audio_manager() -> Node:
	return get_node("/root/AudioManager")
