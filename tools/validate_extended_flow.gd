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
	if manager == null:
		_fail("missing GameManager autoload")
		_finish()
		return
	if dialogue == null:
		_fail("missing DialogueManager autoload")
		_finish()
		return
	await _drain_dialogue(dialogue, "intro")
	await manager.start_final_chase()
	_check(manager.stage == manager.GameStage.FINAL_CHASE, "final chase stage did not start")
	_check(main.enemy.active, "enemy is not active during final chase")
	_check(main.boyfriend_car.global_position == main.RESCUE_CAR_POSITION, "rescue car is not delayed to late road")
	await manager.start_dog_intervention()
	_check(manager.stage == manager.GameStage.DOG_INTERVENTION, "dog intervention stage did not start")
	_check(main.baekgu.visible, "Baekgu is not visible during intervention")
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
	_check(manager.factory_chase_seconds_left == manager.FACTORY_CHASE_DURATION, "factory timer is not initialized to 40 seconds")
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
	await manager.start_exhausted_escape()
	_check(manager.stage == manager.GameStage.EXHAUSTED_ESCAPE, "exhausted escape stage did not start")
	_check(main.player.sprint_speed == 112.0, "player sprint speed was not reduced after factory escape")
	await _drain_dialogue(dialogue, "exhausted_escape")
	_check(manager.stage == manager.GameStage.EXHAUSTED_ESCAPE, "exhausted run did not remain in escape stage")
	_check(main.enemy.active, "enemy did not resume pursuit after exhausted dialogue")
	_check(is_equal_approx(main.enemy.final_chase_speed, main.EXHAUSTED_CHASE_SPEED), "exhausted enemy speed is not set")
	manager.start_rescue()
	_check(manager.stage == manager.GameStage.RESCUE, "rescue stage did not start")
	_check(main.boyfriend_car.visible, "boyfriend car is not visible during rescue")
	_check(main.player.sprint_speed == 165.0, "player sprint speed was not restored at rescue")
	await _drain_dialogue(dialogue, "ending")
	_check(manager.stage == manager.GameStage.ENDING, "ending did not complete after rescue dialogue")
	_finish()

func _wait_for_factory_chase_ready(manager: Node, main: Node) -> void:
	var frames := 0
	while frames < 180:
		if manager.stage == manager.GameStage.FACTORY_CHASE and not manager.player_locked and main.enemy.active:
			return
		frames += 1
		await process_frame
	_fail("factory chase did not become playable")

func _drain_dialogue(dialogue: Node, label: String) -> void:
	var guard := 0
	while dialogue.is_active() and guard < 60:
		dialogue.advance()
		guard += 1
		await process_frame
	if guard >= 60:
		_fail("dialogue did not finish: " + label)

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
