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
	FACTORY_BACKSIDE = 11,
	FLASHLIGHT_FOUND = 12,
	BUSH_MAZE = 13,
	CAT_KEY = 14,
	RETURN_TO_STORE = 15,
	WRONG_KEY_REVEAL = 16,
	RESCUE = 17,
	ENDING = 18,
	GAME_OVER = 19,
}

const MAX_SPRAY_USES := 1
const FACTORY_CHASE_DURATION := 20
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
var factory_exit_transition_started := false
var has_flashlight := false
var has_cat_key := false
var cat_key_found := false
var wrong_key_revealed := false
var car_escape_complete := false
var return_presence_seen := false

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
		GameStage.FACTORY_BACKSIDE:
			return "공장 뒤편 배전함을 조사하자"
		GameStage.FLASHLIGHT_FOUND:
			return "후레쉬를 들고 수풀 속으로 들어가자"
		GameStage.BUSH_MAZE:
			return "후레쉬 빛을 따라 수풀 미로를 빠져나가자"
		GameStage.CAT_KEY:
			return "목걸이에 열쇠를 단 고양이를 살펴보자"
		GameStage.RETURN_TO_STORE:
			if return_presence_seen:
				return "편의점 문에 열쇠를 꽂아보자"
			return "집으로 돌아가는 길을 되짚어가자"
		GameStage.WRONG_KEY_REVEAL:
			return "열쇠가 맞지 않는다. 차 불빛을 찾아라"
		GameStage.RESCUE:
			return "차에 올라타자"
		GameStage.ENDING:
			return ""
		GameStage.GAME_OVER:
			return "다시 해보자"
	return ""

func set_checkpoint(id: String, position: Vector2, restore_stage: int) -> void:
	checkpoint_id = id
	checkpoint_position = position
	checkpoint_stage = restore_stage

func _reset_post_factory_story_state() -> void:
	has_flashlight = false
	has_cat_key = false
	cat_key_found = false
	wrong_key_revealed = false
	car_escape_complete = false
	return_presence_seen = false

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
		"power_box":
			pickup_flashlight()
		"key_cat":
			collect_cat_key()
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
	if stage == GameStage.RETURN_TO_STORE and has_cat_key:
		if not return_presence_seen:
			show_hint("아직은 집으로 돌아갈 수 있을지 확인해야 한다.")
			return
		reveal_wrong_key()
		return
	if stage == GameStage.WRONG_KEY_REVEAL or stage == GameStage.RESCUE:
		show_hint("지금은 문이 아니라 차 불빛을 봐야 한다.")
		return
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
					start_factory_backside()
				else:
					show_hint("아직 나갈 수 없어. 조금만 더 버티자.")
		"cat_clearing":
			if stage == GameStage.BUSH_MAZE and not cat_key_found:
				start_cat_key_scene()
		"return_presence":
			if stage == GameStage.RETURN_TO_STORE and not return_presence_seen:
				trigger_return_presence()
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
	_audio_manager().set_bgm_profile("chase")
	_audio_manager().set_bgm_intensity(0.92)
	if is_instance_valid(main_node):
		main_node.activate_enemy(false)

func finish_first_chase() -> void:
	if stage != GameStage.FIRST_THREAT:
		return
	transition_to(GameStage.SPRAY_USED)
	_audio_manager().set_bgm_profile("default")
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
	_audio_manager().set_bgm_profile("default")
	_audio_manager().set_bgm_intensity(0.72)
	if is_instance_valid(main_node):
		main_node.set_store_checkpoint()
	_dialogue_manager().start_dialogue("store_arrival", Callable(self, "_update_store_objective"))

func start_final_chase() -> void:
	transition_to(GameStage.FINAL_CHASE)
	factory_exit_open = false
	factory_exit_transition_started = false
	_reset_post_factory_story_state()
	factory_chase_seconds_left = FACTORY_CHASE_DURATION
	_audio_manager().set_bgm_profile("chase")
	_audio_manager().set_bgm_intensity(1.0)
	if is_instance_valid(main_node):
		await main_node.prepare_final_chase()
		_audio_manager().play_sfx("chase_start")
		main_node.activate_enemy(true)

func start_dog_intervention() -> void:
	transition_to(GameStage.DOG_INTERVENTION)
	set_player_locked(true)
	_audio_manager().play_sfx("dog_bark")
	_audio_manager().set_bgm_profile("default")
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
	factory_exit_transition_started = false
	_reset_post_factory_story_state()
	factory_chase_seconds_left = FACTORY_CHASE_DURATION
	_audio_manager().set_bgm_profile("default")
	_audio_manager().set_bgm_intensity(0.86)
	if is_instance_valid(main_node):
		main_node.enter_factory_hide()
	_dialogue_manager().start_dialogue("factory_hide", Callable(self, "start_factory_chase"))

func start_factory_chase() -> void:
	transition_to(GameStage.FACTORY_CHASE)
	factory_exit_open = false
	factory_exit_transition_started = false
	set_factory_chase_seconds_left(FACTORY_CHASE_DURATION)
	set_checkpoint("CP_FACTORY", Vector2(-165, -1355), GameStage.FACTORY_CHASE)
	set_player_locked(true)
	_audio_manager().set_bgm_profile("chase")
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
	factory_exit_transition_started = false
	set_factory_chase_seconds_left(0)
	show_hint("출구 셔터가 열렸다. 위쪽 파란 비상등을 따라 나가!")
	_audio_manager().play_sfx("metal_clang")
	if is_instance_valid(main_node):
		main_node.open_factory_exit()

func _get_factory_chase_objective() -> String:
	if factory_exit_open:
		return "위쪽 파란 비상등 출구로 탈출하자"
	return "공장 안에서 20초 버티기 (%02d초)" % factory_chase_seconds_left

func start_exhausted_escape() -> void:
	start_factory_backside()

func start_factory_backside() -> void:
	if stage != GameStage.FACTORY_CHASE or factory_exit_transition_started:
		return
	factory_exit_transition_started = true
	factory_exit_open = false
	transition_to(GameStage.FACTORY_BACKSIDE)
	set_checkpoint("CP_FACTORY_BACKSIDE", Vector2(-90, -1985), GameStage.FACTORY_BACKSIDE)
	set_player_locked(true)
	_audio_manager().set_bgm_profile("default")
	_audio_manager().set_bgm_intensity(0.88)
	if is_instance_valid(main_node):
		await main_node.run_factory_backside_escape()
	_dialogue_manager().start_dialogue("factory_backside_escape", Callable(self, "_unlock_factory_backside"))

func _unlock_factory_backside() -> void:
	set_player_locked(false)
	show_hint("배전함을 조사해 후레쉬를 찾자.")

func pickup_flashlight() -> void:
	if stage != GameStage.FACTORY_BACKSIDE:
		if has_flashlight:
			show_hint("후레쉬는 이미 손에 있다.")
		else:
			_dialogue_manager().start_dialogue("power_box_not_ready")
		return
	has_flashlight = true
	transition_to(GameStage.FLASHLIGHT_FOUND)
	set_player_locked(true)
	_audio_manager().play_sfx("flashlight_pickup")
	_audio_manager().set_bgm_profile("bush_maze")
	if is_instance_valid(main_node):
		await main_node.run_flashlight_pickup()
	_dialogue_manager().start_dialogue("flashlight_found", Callable(self, "start_bush_maze"))

func start_bush_maze() -> void:
	transition_to(GameStage.BUSH_MAZE)
	set_player_locked(false)
	_audio_manager().set_bgm_profile("bush_maze")
	if is_instance_valid(main_node):
		main_node.open_bush_maze()
	show_hint("후레쉬 빛에 걸리는 밝은 풀잎을 따라가자.")

func start_cat_key_scene() -> void:
	if stage != GameStage.BUSH_MAZE or cat_key_found:
		return
	transition_to(GameStage.CAT_KEY)
	set_player_locked(true)
	_audio_manager().play_sfx("cat_meow")
	if is_instance_valid(main_node):
		await main_node.run_cat_approach()
	_dialogue_manager().start_dialogue("cat_approach", Callable(self, "_unlock_cat_interaction"))

func _unlock_cat_interaction() -> void:
	set_player_locked(false)
	if is_instance_valid(main_node):
		main_node.enable_cat_interaction()
	show_hint("고양이가 목걸이를 내민다. 가까이 가서 쓰다듬자.")

func collect_cat_key() -> void:
	if stage != GameStage.CAT_KEY:
		show_hint("지금 만질 수 있는 것은 아닌 것 같다.")
		return
	if has_cat_key:
		show_hint("고양이 목걸이의 열쇠는 이미 챙겼다.")
		return
	cat_key_found = true
	has_cat_key = true
	set_player_locked(true)
	_audio_manager().play_sfx("key_jingle")
	if is_instance_valid(main_node):
		await main_node.run_cat_key_collect()
	_dialogue_manager().start_dialogue("cat_key_found", Callable(self, "_start_return_to_store"))

func _start_return_to_store() -> void:
	transition_to(GameStage.RETURN_TO_STORE)
	set_player_locked(false)
	_audio_manager().set_bgm_intensity(0.78)
	if is_instance_valid(main_node):
		main_node.prepare_return_to_store()
	show_hint("왔던 길을 따라 집 쪽으로 돌아가자. 열쇠는 손에서 차갑게 흔들린다.")

func trigger_return_presence() -> void:
	if stage != GameStage.RETURN_TO_STORE or return_presence_seen:
		return
	return_presence_seen = true
	emit_signal("objective_changed", get_objective_for_stage(stage))
	set_player_locked(true)
	_audio_manager().play_sfx("leaf_stinger")
	if is_instance_valid(main_node):
		await main_node.run_return_presence()
	_dialogue_manager().start_dialogue("return_presence", Callable(self, "_unlock_store_escape"))

func _unlock_store_escape() -> void:
	set_player_locked(false)
	show_hint("가로등 쪽은 안 된다. 편의점 문에 열쇠를 꽂아봐!")

func reveal_wrong_key() -> void:
	if stage != GameStage.RETURN_TO_STORE or not has_cat_key or not return_presence_seen or wrong_key_revealed:
		return
	wrong_key_revealed = true
	transition_to(GameStage.WRONG_KEY_REVEAL)
	set_player_locked(true)
	_audio_manager().set_bgm_profile("chase")
	_audio_manager().set_bgm_intensity(1.0)
	_audio_manager().play_sfx("door_locked")
	if is_instance_valid(main_node):
		await main_node.run_wrong_key_reveal()
	_dialogue_manager().start_dialogue("wrong_key_reveal", Callable(self, "start_rescue"))

func start_rescue() -> void:
	transition_to(GameStage.RESCUE)
	set_player_locked(true)
	_audio_manager().set_bgm_profile("default")
	_audio_manager().set_bgm_intensity(0.88)
	if is_instance_valid(main_node):
		await main_node.run_rescue()
	_dialogue_manager().start_dialogue("ending", Callable(self, "finish_ending"))

func finish_ending() -> void:
	transition_to(GameStage.ENDING)
	set_player_locked(true)
	car_escape_complete = true
	if is_instance_valid(main_node):
		await main_node.run_escape_driveaway()
	_audio_manager().set_bgm_intensity(0.0)
	if is_instance_valid(main_node):
		main_node.show_ending_screen()

func game_over() -> void:
	if stage == GameStage.GAME_OVER or stage == GameStage.WRONG_KEY_REVEAL or stage == GameStage.RESCUE or stage == GameStage.ENDING:
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
		factory_exit_transition_started = false
		set_factory_chase_seconds_left(FACTORY_CHASE_DURATION)
	elif stage == GameStage.FACTORY_BACKSIDE:
		has_flashlight = false
		has_cat_key = false
		cat_key_found = false
		return_presence_seen = false
		wrong_key_revealed = false
		car_escape_complete = false

func _set_bgm_for_stage(value: int) -> void:
	match value:
		GameStage.WALK_TO_STORE:
			_audio_manager().set_bgm_profile("default")
			_audio_manager().set_bgm_intensity(0.55)
		GameStage.STORE_REACHED:
			_audio_manager().set_bgm_profile("default")
			_audio_manager().set_bgm_intensity(0.72)
		GameStage.FINAL_CHASE:
			_audio_manager().set_bgm_profile("chase")
			_audio_manager().set_bgm_intensity(1.0)
		GameStage.DOG_INTERVENTION, GameStage.FACTORY_APPROACH, GameStage.FACTORY_HIDE:
			_audio_manager().set_bgm_profile("default")
			_audio_manager().set_bgm_intensity(0.86)
		GameStage.FACTORY_CHASE:
			_audio_manager().set_bgm_profile("chase")
			_audio_manager().set_bgm_intensity(1.0)
		GameStage.EXHAUSTED_ESCAPE:
			_audio_manager().set_bgm_profile("chase")
			_audio_manager().set_bgm_intensity(0.92)
		GameStage.FACTORY_BACKSIDE:
			_audio_manager().set_bgm_profile("default")
			_audio_manager().set_bgm_intensity(0.88)
		GameStage.FLASHLIGHT_FOUND, GameStage.BUSH_MAZE, GameStage.CAT_KEY:
			_audio_manager().set_bgm_profile("bush_maze")
			_audio_manager().set_bgm_intensity(0.90)
		GameStage.RETURN_TO_STORE:
			_audio_manager().set_bgm_profile("bush_maze")
			_audio_manager().set_bgm_intensity(0.78)
		GameStage.WRONG_KEY_REVEAL:
			_audio_manager().set_bgm_profile("chase")
			_audio_manager().set_bgm_intensity(1.0)
		GameStage.RESCUE:
			_audio_manager().set_bgm_profile("default")
			_audio_manager().set_bgm_intensity(0.88)
		GameStage.ENDING:
			_audio_manager().set_bgm_profile("default")
			_audio_manager().set_bgm_intensity(0.0)
		_:
			_audio_manager().set_bgm_profile("default")
			_audio_manager().set_bgm_intensity(0.55)

func _dialogue_manager() -> Node:
	return get_node("/root/DialogueManager")

func _audio_manager() -> Node:
	return get_node("/root/AudioManager")
