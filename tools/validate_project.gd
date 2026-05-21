extends SceneTree

func _init() -> void:
	var failures: Array[String] = []
	_check_file("res://project.godot", failures)
	_check_file("res://scenes/Main.tscn", failures)
	_check_file("res://scenes/Player.tscn", failures)
	_check_file("res://scenes/Enemy.tscn", failures)
	_check_file("res://scenes/BoyfriendCar.tscn", failures)
	_check_file("res://scripts/autoload/game_manager.gd", failures)
	_check_file("res://scripts/autoload/dialogue_manager.gd", failures)
	_check_file("res://scripts/main.gd", failures)
	_check_file("res://scripts/player.gd", failures)
	_check_file("res://scripts/enemy_chase.gd", failures)
	_check_file("res://scripts/spray_controller.gd", failures)
	_check_file("res://scripts/trigger_event.gd", failures)
	_check_file("res://scripts/convenience_store_door.gd", failures)
	_check_file("res://scripts/boyfriend_car.gd", failures)
	_check_file("res://data/dialogues.json", failures)
	_check_file("res://data/game_config.json", failures)
	_check_file("res://asset_manifest.lock.json", failures)
	_check_file("res://assets/source/characters/hero_spritesheet.webp", failures)
	_check_file("res://assets/source/characters/boyfriend_spritesheet.webp", failures)
	_check_file("res://assets/source/vehicles/potato-style-car-front-3q.png", failures)
	_check_file("res://assets/source/creatures/nightmare-creature-single-256h.png", failures)
	_check_file("res://assets/source/creatures/nightmare-creature-motion-atlas.png", failures)
	_check_file("res://assets/source/manifests/nightmare_creature_motion_manifest.json", failures)
	_check_file("res://assets/source/buildings/convenience-store-potato-style.png", failures)
	_check_resource_load("res://scenes/Main.tscn", failures)
	_check_resource_load("res://scenes/Player.tscn", failures)
	_check_resource_load("res://scenes/Enemy.tscn", failures)
	_check_resource_load("res://scenes/BoyfriendCar.tscn", failures)
	_check_resource_load("res://assets/source/vehicles/potato-style-car-front-3q.png", failures)
	_check_resource_load("res://assets/source/creatures/nightmare-creature-single-256h.png", failures)
	_check_resource_load("res://assets/source/creatures/nightmare-creature-motion-atlas.png", failures)
	_check_resource_load("res://assets/source/buildings/convenience-store-potato-style.png", failures)
	_check_resource_load("res://scripts/player.gd", failures)
	_check_resource_load("res://scripts/enemy_chase.gd", failures)
	_check_resource_load("res://scripts/autoload/audio_manager.gd", failures)
	_check_json("res://data/dialogues.json", failures)
	_check_json("res://data/game_config.json", failures)
	_check_text_contains("res://scripts/player.gd", "CELL_SIZE := Vector2(192, 208)", failures)
	_check_text_contains("res://scripts/player.gd", "CHARACTER_VISUAL_SCALE", failures)
	_check_text_contains("res://scripts/player.gd", "InputMap.add_action", failures)
	_check_text_contains("res://scripts/player.gd", "Input.get_action_strength", failures)
	_check_text_contains("res://scripts/boyfriend_car.gd", "CAR_VISUAL_SCALE", failures)
	_check_text_contains("res://scripts/boyfriend_car.gd", "potato-style-car-front-3q.png", failures)
	_check_text_contains("res://scripts/enemy_chase.gd", "nightmare-creature-motion-atlas.png", failures)
	_check_text_contains("res://scripts/enemy_chase.gd", "CELL_SIZE := Vector2(448, 640)", failures)
	_check_text_contains("res://scripts/enemy_chase.gd", "charge-towards", failures)
	_check_text_contains("res://scripts/enemy_chase.gd", "collision_layer = 0", failures)
	_check_text_contains("res://scripts/enemy_chase.gd", "CatchArea", failures)
	_check_text_contains("res://scripts/main.gd", "convenience-store-potato-style.png", failures)
	_check_text_contains("res://scripts/main.gd", "FINAL_CHASE_START_GAP := 320.0", failures)
	_check_text_contains("res://scripts/main.gd", "_get_final_chase_escape_position", failures)
	_check_text_contains("res://scripts/main.gd", "StreetlightLampHousing", failures)
	_check_text_contains("res://scripts/main.gd", "StreetlightLightPool", failures)
	_check_text_contains("res://scripts/main.gd", "_add_store_lighting", failures)
	_check_text_contains("res://scripts/spray_controller.gd", "manager.set_spray_uses(manager.spray_uses - 1)", failures)
	_check_text_contains("res://scripts/autoload/audio_manager.gd", "AudioStreamGenerator", failures)
	_check_text_contains("res://scripts/autoload/audio_manager.gd", "rescue_honk", failures)

	if failures.size() > 0:
		for failure in failures:
			print("VALIDATION_FAIL: ", failure)
		quit(1)
	print("VALIDATION_OK")
	quit(0)

func _check_file(path: String, failures: Array[String]) -> void:
	if not FileAccess.file_exists(path):
		failures.append("missing file: " + path)

func _check_resource_load(path: String, failures: Array[String]) -> void:
	var resource = load(path)
	if resource == null:
		failures.append("cannot load resource: " + path)

func _check_json(path: String, failures: Array[String]) -> void:
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		failures.append("cannot open json: " + path)
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed == null:
		failures.append("cannot parse json: " + path)

func _check_text_contains(path: String, needle: String, failures: Array[String]) -> void:
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	if not file.get_as_text().contains(needle):
		failures.append("missing expected text in " + path + ": " + needle)
