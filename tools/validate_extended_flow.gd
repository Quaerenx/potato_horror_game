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
	var manager := root.get_node_or_null("GameManager")
	var dialogue := root.get_node_or_null("DialogueManager")
	var audio := root.get_node_or_null("AudioManager")
	if manager == null:
		_fail("missing GameManager autoload")
		_finish()
		return
	if dialogue == null:
		_fail("missing DialogueManager autoload")
		_finish()
		return
	if audio == null:
		_fail("missing AudioManager autoload")
		_finish()
		return
	await _drain_dialogue(dialogue, "intro")
	await manager.start_final_chase()
	_check(manager.stage == manager.GameStage.FINAL_CHASE, "final chase stage did not start")
	_check(audio.bgm_profile == "chase", "final chase did not switch to chase BGM")
	_check(main.enemy.active, "enemy is not active during final chase")
	_check(main.boyfriend_car.global_position == main.RESCUE_CAR_POSITION, "rescue car is not delayed to late road")
	await manager.start_dog_intervention()
	_check(manager.stage == manager.GameStage.DOG_INTERVENTION, "dog intervention stage did not start")
	_check(audio.bgm_profile == "default", "dog intervention did not leave chase BGM")
	_check(main.baekgu.visible, "Baekgu is not visible during intervention")
	_check(main.baekgu.z_index >= 40, "Baekgu is not drawn prominently enough")
	_check(main.baekgu_anim.scale.x >= 0.18, "Baekgu visual scale is too small")
	_check(main.baekgu.get_node_or_null("BaekguRimLight") != null, "Baekgu rim light is missing")
	_check(main.baekgu_hurt.visible, "Baekgu did not switch to hurt pose")
	_check(main.baekgu_anim.animation == "hurt-recover", "Baekgu did not play hurt-recover animation")
	await _drain_dialogue(dialogue, "dog_intervention")
	_check(manager.stage == manager.GameStage.FACTORY_APPROACH, "factory approach did not follow dog dialogue")
	manager.start_factory_hide()
	_check(manager.stage == manager.GameStage.FACTORY_HIDE, "factory hide stage did not start")
	_check(main.player.global_position == main.FACTORY_HIDE_POSITION, "player was not moved inside factory")
	await _drain_dialogue(dialogue, "factory_hide")
	await _wait_for_factory_chase_ready(manager, main)
	_check(manager.stage == manager.GameStage.FACTORY_CHASE, "factory chase did not start")
	_check(audio.bgm_profile == "chase", "factory chase did not switch to chase BGM")
	_check(manager.factory_chase_seconds_left == manager.FACTORY_CHASE_DURATION, "factory timer is not initialized to 20 seconds")
	_check(not manager.factory_exit_open, "factory exit opened before timer")
	_check(is_instance_valid(main.factory_exit_blocker), "factory exit blocker missing before timer")
	_check(main.enemy.active, "enemy is not active in factory chase")
	_check(is_equal_approx(main.enemy.final_chase_speed, main.FACTORY_CHASE_SPEED), "factory enemy speed is not set")
	_check(main.FACTORY_CHASE_SPEED > main.player.walk_speed, "factory enemy speed is too low for a chase")
	_check(main.FACTORY_CHASE_SPEED < main.player.sprint_speed, "factory enemy speed is too high for medium difficulty")
	_check(_factory_obstacle_count(main) >= 7, "factory does not have enough collision obstacles for loop play")
	main.factory_timer = 0.05
	await create_timer(0.20).timeout
	await process_frame
	_check(manager.factory_exit_open, "factory exit did not open after timer")
	_check(not is_instance_valid(main.factory_exit_blocker), "factory exit blocker still present after timer")
	_check(_factory_exit_guide_visible(main), "factory exit guide is not visible after timer")
	main.player.global_position = main.FACTORY_EXIT_POSITION
	await _wait_for_stage(manager, manager.GameStage.FACTORY_BACKSIDE, "factory exit overlap did not advance to backside")
	_check(manager.stage == manager.GameStage.FACTORY_BACKSIDE, "factory backside stage did not start")
	_check(audio.bgm_profile == "default", "factory backside did not leave chase BGM")
	_check(not manager.factory_exit_open, "factory exit open flag stayed set after backside transition")
	_check(not main.enemy.active, "enemy should stop after factory backside escape")
	_check(not main.boyfriend_car.visible, "boyfriend car should stay hidden after factory escape")
	_check(is_instance_valid(main.maze_darkness_blocker), "maze darkness blocker missing before flashlight")
	_check(main.player.sprint_speed == 136.0, "player sprint speed was not set for factory backside")
	await _drain_dialogue(dialogue, "factory_backside_escape")
	await manager.pickup_flashlight()
	_check(manager.stage == manager.GameStage.FLASHLIGHT_FOUND, "flashlight pickup stage did not start")
	_check(manager.has_flashlight, "flashlight state was not recorded")
	_check(main.player.flashlight_cone.visible, "player flashlight cone is not visible")
	await _drain_dialogue(dialogue, "flashlight_found")
	_check(manager.stage == manager.GameStage.BUSH_MAZE, "bush maze stage did not start after flashlight dialogue")
	_check(audio.bgm_profile == "bush_maze", "bush maze BGM profile was not restored")
	_check(not is_instance_valid(main.maze_darkness_blocker), "maze blocker still exists after flashlight")
	_check(_maze_guide_visible(main), "maze flashlight guide is not visible")
	await manager.start_cat_key_scene()
	_check(manager.stage == manager.GameStage.CAT_KEY, "cat key stage did not start")
	_check(main.key_cat.visible, "key cat is not visible during approach")
	await _drain_dialogue(dialogue, "cat_approach")
	_check(main.cat_interaction.monitoring, "cat interaction was not enabled")
	await manager.collect_cat_key()
	_check(manager.has_cat_key, "cat key was not collected")
	await _drain_dialogue(dialogue, "cat_key_found")
	_check(manager.stage == manager.GameStage.RETURN_TO_STORE, "return-to-store stage did not start")
	_check(main.player.global_position == main.RETURN_ROAD_POSITION, "player was not moved back to return road")
	await manager.reveal_wrong_key()
	_check(manager.stage == manager.GameStage.RETURN_TO_STORE, "wrong key reveal was allowed before streetlight presence")
	await manager.trigger_return_presence()
	_check(manager.return_presence_seen, "return presence was not recorded")
	_check(is_instance_valid(main.return_presence_blocker), "return path was not blocked after streetlight presence")
	await _drain_dialogue(dialogue, "return_presence")
	_check(manager.stage == manager.GameStage.RETURN_TO_STORE, "return presence should keep store escape stage")
	await manager.reveal_wrong_key()
	_check(manager.stage == manager.GameStage.WRONG_KEY_REVEAL, "wrong key reveal stage did not start")
	_check(audio.bgm_profile == "chase", "wrong key reveal did not switch to chase BGM")
	_check(manager.wrong_key_revealed, "wrong key reveal state was not recorded")
	_check(manager.player_locked, "player should be held during wrong key reveal")
	_check(main.enemy.visible, "enemy should be visible during wrong key reveal")
	await _drain_dialogue(dialogue, "wrong_key_reveal")
	await _wait_for_stage(manager, manager.GameStage.RESCUE, "rescue stage did not start after wrong key dialogue")
	await _wait_for_dialogue(dialogue, "ending")
	_check(main.boyfriend_car.visible, "boyfriend car should be visible during rescue")
	_check(not main.enemy.visible, "enemy should be knocked out after car impact")
	await _drain_dialogue(dialogue, "ending")
	await _wait_for_stage(manager, manager.GameStage.ENDING, "ending stage did not start after rescue")
	await create_timer(1.0).timeout
	_check(manager.car_escape_complete, "car escape completion state was not recorded")
	_check(not main.player.visible, "player should be inside the car after escape")
	_check(is_instance_valid(main.ending_layer), "ending screen was not shown")
	_finish()

func _wait_for_factory_chase_ready(manager: Node, main: Node) -> void:
	var frames := 0
	while frames < 180:
		if manager.stage == manager.GameStage.FACTORY_CHASE and not manager.player_locked and main.enemy.active:
			return
		frames += 1
		await process_frame
	_fail("factory chase did not become playable")

func _wait_for_stage(manager: Node, target_stage: int, message: String) -> void:
	var frames := 0
	while frames < 180:
		if manager.stage == target_stage:
			return
		frames += 1
		await process_frame
	_fail(message)

func _drain_dialogue(dialogue: Node, label: String) -> void:
	var guard := 0
	while dialogue.is_active() and guard < 60:
		dialogue.advance()
		guard += 1
		await process_frame
	if guard >= 60:
		_fail("dialogue did not finish: " + label)

func _wait_for_dialogue(dialogue: Node, label: String) -> void:
	var frames := 0
	while frames < 240:
		if dialogue.is_active():
			return
		frames += 1
		await process_frame
	_fail("dialogue did not start: " + label)

func _factory_obstacle_count(main: Node) -> int:
	var names := [
		"FactoryMachineACollision",
		"FactoryMachineBCollision",
		"FactoryCrateLoopACollision",
		"FactoryConveyorCollision",
		"FactoryShelfACollision",
		"FactoryPillarACollision",
		"FactoryPillarBCollision",
	]
	var count := 0
	for node_name in names:
		if main.get_node_or_null(str(node_name)) != null:
			count += 1
	return count

func _factory_exit_guide_visible(main: Node) -> bool:
	var guide := main.get_node_or_null("FactoryExitBeaconInner") as CanvasItem
	return guide != null and guide.visible

func _maze_guide_visible(main: Node) -> bool:
	var guide := main.get_node_or_null("BushMazeFlashlightGuide0") as CanvasItem
	return guide != null and guide.visible

func _check(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)

func _fail(message: String) -> void:
	failures.append(message)

func _finish() -> void:
	if failures.size() > 0:
		for failure in failures:
			print("EXTENDED_FLOW_FAIL: ", failure)
		quit(1)
		return
	print("EXTENDED_FLOW_OK")
	quit(0)
