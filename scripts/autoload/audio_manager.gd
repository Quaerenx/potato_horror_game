extends Node

const MIX_RATE := 22050
const BGM_BUFFER_LENGTH := 1.4

var sfx_players := {}
var bgm_player: AudioStreamPlayer
var bgm_playback
var bgm_phase_low := 0.0
var bgm_phase_sub := 0.0
var bgm_phase_detune := 0.0
var bgm_phase_mid := 0.0
var bgm_phase_high := 0.0
var bgm_phase_scrape := 0.0
var bgm_phase_pulse := 0.0
var bgm_intensity := 0.55
var bgm_target_intensity := 0.55
var bgm_profile := "default"
var sfx_specs := {
	"footstep": {"duration": 0.16, "frequency": 118.0, "volume": 0.055, "noise": 0.62, "shape": "grass_footstep"},
	"spray": {"duration": 0.18, "frequency": 820.0, "volume": 0.16, "noise": 0.70},
	"spray_miss": {"duration": 0.11, "frequency": 520.0, "volume": 0.09, "noise": 0.55},
	"spray_empty": {"duration": 0.10, "frequency": 180.0, "volume": 0.10, "noise": 0.18},
	"door_locked": {"duration": 0.16, "frequency": 150.0, "volume": 0.18, "noise": 0.10},
	"streetlight": {"duration": 0.34, "frequency": 1180.0, "volume": 0.075, "noise": 0.20},
	"panic_step": {"duration": 0.24, "frequency": 76.0, "volume": 0.15, "noise": 0.78, "shape": "horror_footstep"},
	"chase_start": {"duration": 0.42, "frequency": 64.0, "volume": 0.20, "noise": 0.25},
	"game_over": {"duration": 0.48, "frequency": 52.0, "volume": 0.22, "noise": 0.18},
	"rescue_honk": {"duration": 0.36, "frequency": 430.0, "volume": 0.18, "noise": 0.02},
	"bush_rustle": {"duration": 0.26, "frequency": 240.0, "volume": 0.08, "noise": 0.92},
	"distant_step": {"duration": 0.34, "frequency": 54.0, "volume": 0.12, "noise": 0.64, "shape": "distant_footstep"},
	"fluorescent": {"duration": 0.32, "frequency": 960.0, "volume": 0.065, "noise": 0.16},
	"auto_door": {"duration": 0.20, "frequency": 620.0, "volume": 0.09, "noise": 0.06},
	"heartbeat": {"duration": 0.28, "frequency": 58.0, "volume": 0.14, "noise": 0.12},
	"phone_ring": {"duration": 0.70, "frequency": 520.0, "volume": 0.12, "noise": 0.03},
	"dog_bark": {"duration": 0.24, "frequency": 360.0, "volume": 0.16, "noise": 0.42},
	"dog_whine": {"duration": 0.38, "frequency": 300.0, "volume": 0.11, "noise": 0.20},
	"metal_clang": {"duration": 0.36, "frequency": 210.0, "volume": 0.16, "noise": 0.58},
	"factory_alarm": {"duration": 0.46, "frequency": 720.0, "volume": 0.10, "noise": 0.22},
	"rescue_honk_far": {"duration": 0.62, "frequency": 390.0, "volume": 0.13, "noise": 0.04},
	"flashlight_pickup": {"duration": 0.34, "frequency": 940.0, "volume": 0.085, "noise": 0.08, "shape": "flashlight_pickup"},
	"key_jingle": {"duration": 0.46, "frequency": 1260.0, "volume": 0.075, "noise": 0.06, "shape": "key_jingle"},
	"cat_meow": {"duration": 0.52, "frequency": 620.0, "volume": 0.080, "noise": 0.10, "shape": "cat_meow"},
	"leaf_stinger": {"duration": 0.42, "frequency": 330.0, "volume": 0.105, "noise": 0.88, "shape": "leaf_stinger"},
	"store_door_lock_heavy": {"duration": 0.48, "frequency": 118.0, "volume": 0.18, "noise": 0.22, "shape": "door_lock_heavy"},
	"car_impact_heavy": {"duration": 0.62, "frequency": 72.0, "volume": 0.24, "noise": 0.82, "shape": "car_impact_heavy"},
}

func _ready() -> void:
	for sfx_name in sfx_specs.keys():
		var player := AudioStreamPlayer.new()
		player.name = "Sfx_" + str(sfx_name)
		var stream := AudioStreamGenerator.new()
		stream.mix_rate = MIX_RATE
		stream.buffer_length = 0.9
		player.stream = stream
		add_child(player)
		sfx_players[sfx_name] = player
	_build_bgm_player()

func _process(delta: float) -> void:
	bgm_intensity = lerpf(bgm_intensity, bgm_target_intensity, minf(1.0, delta * 1.6))
	_fill_bgm_buffer()

func set_bgm_intensity(value: float) -> void:
	bgm_target_intensity = clampf(value, 0.0, 1.0)

func set_bgm_profile(profile_name: String) -> void:
	if profile_name == "bush_maze":
		bgm_profile = "bush_maze"
	elif profile_name == "chase":
		bgm_profile = "chase"
	else:
		bgm_profile = "default"

func _exit_tree() -> void:
	if is_instance_valid(bgm_player):
		bgm_player.stop()
	for player in sfx_players.values():
		if is_instance_valid(player):
			player.stop()

func play_sfx(name: String) -> void:
	if not sfx_players.has(name):
		return
	var player: AudioStreamPlayer = sfx_players[name]
	var spec: Dictionary = sfx_specs[name]
	player.stop()
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = MIX_RATE
	stream.buffer_length = 0.9
	player.stream = stream
	player.play()
	var playback = player.get_stream_playback()
	if playback == null:
		return
	_write_generated_sfx(playback, spec)

func _write_generated_sfx(playback, spec: Dictionary) -> void:
	var shape := str(spec.get("shape", "tone_noise"))
	if shape == "grass_footstep":
		_write_grass_footstep_sfx(playback, spec)
		return
	if shape == "horror_footstep":
		_write_horror_footstep_sfx(playback, spec)
		return
	if shape == "distant_footstep":
		_write_distant_footstep_sfx(playback, spec)
		return
	if shape == "flashlight_pickup":
		_write_flashlight_pickup_sfx(playback, spec)
		return
	if shape == "key_jingle":
		_write_key_jingle_sfx(playback, spec)
		return
	if shape == "cat_meow":
		_write_cat_meow_sfx(playback, spec)
		return
	if shape == "leaf_stinger":
		_write_leaf_stinger_sfx(playback, spec)
		return
	if shape == "door_lock_heavy":
		_write_door_lock_heavy_sfx(playback, spec)
		return
	if shape == "car_impact_heavy":
		_write_car_impact_heavy_sfx(playback, spec)
		return
	var duration := float(spec.get("duration", 0.12))
	var frequency := float(spec.get("frequency", 440.0))
	var volume := float(spec.get("volume", 0.12))
	var noise_amount := float(spec.get("noise", 0.0))
	var frame_count := int(duration * MIX_RATE)
	for frame in range(frame_count):
		var t := float(frame) / float(MIX_RATE)
		var progress := t / duration
		var envelope := sin(progress * PI)
		var tone := sin(TAU * frequency * t)
		var overtone := sin(TAU * frequency * 1.9 * t) * 0.35
		var noise := randf_range(-1.0, 1.0) * noise_amount
		var sample := (tone + overtone + noise) * envelope * volume
		playback.push_frame(Vector2(sample, sample))

func _write_grass_footstep_sfx(playback, spec: Dictionary) -> void:
	var duration := float(spec.get("duration", 0.16))
	var frequency := float(spec.get("frequency", 118.0)) * randf_range(0.92, 1.08)
	var volume := float(spec.get("volume", 0.055)) * randf_range(0.86, 1.05)
	var noise_amount := float(spec.get("noise", 0.62))
	var frame_count := int(duration * MIX_RATE)
	for frame in range(frame_count):
		var t := float(frame) / float(MIX_RATE)
		var progress := t / duration
		var soft_press := exp(-pow(progress * 5.0, 2.0)) * 0.22
		var grass_swish := sin(progress * PI) * randf_range(-1.0, 1.0) * noise_amount * 0.55
		var dry_blade_tick := randf_range(-1.0, 1.0) * noise_amount * exp(-pow((progress - 0.42) * 5.8, 2.0)) * 0.30
		var muted_body := sin(TAU * frequency * t) * soft_press
		var sample := (muted_body + grass_swish + dry_blade_tick) * volume
		playback.push_frame(Vector2(sample, sample))

func _write_horror_footstep_sfx(playback, spec: Dictionary) -> void:
	var duration := float(spec.get("duration", 0.18))
	var frequency := float(spec.get("frequency", 68.0)) * randf_range(0.86, 1.08)
	var volume := float(spec.get("volume", 0.13)) * randf_range(0.86, 1.12)
	var noise_amount := float(spec.get("noise", 0.72))
	var frame_count := int(duration * MIX_RATE)
	for frame in range(frame_count):
		var t := float(frame) / float(MIX_RATE)
		var progress := t / duration
		var impact := exp(-progress * 18.0)
		var scrape_window := sin(clampf((progress - 0.18) / 0.72, 0.0, 1.0) * PI)
		var sub_drop := sin(TAU * (frequency - progress * 24.0) * t) * impact * 1.20
		var boot_creak := sin(TAU * (frequency * 2.7) * t + sin(TAU * 7.0 * t)) * impact * 0.20
		var gravel := randf_range(-1.0, 1.0) * noise_amount * scrape_window * 0.62
		var echo := sin(TAU * (frequency * 0.58) * t) * exp(-maxf(progress - 0.38, 0.0) * 7.5) * 0.22
		var sample := (sub_drop + boot_creak + gravel + echo) * volume
		playback.push_frame(Vector2(sample, sample))

func _write_distant_footstep_sfx(playback, spec: Dictionary) -> void:
	var duration := float(spec.get("duration", 0.34))
	var frequency := float(spec.get("frequency", 54.0)) * randf_range(0.88, 1.06)
	var volume := float(spec.get("volume", 0.12))
	var noise_amount := float(spec.get("noise", 0.64))
	var frame_count := int(duration * MIX_RATE)
	for frame in range(frame_count):
		var t := float(frame) / float(MIX_RATE)
		var progress := t / duration
		var first_hit := exp(-pow(progress * 8.5, 2.0))
		var second_hit := exp(-pow((progress - 0.38) * 9.0, 2.0)) * 0.55
		var smear := sin(progress * PI) * randf_range(-1.0, 1.0) * noise_amount * 0.35
		var thud := sin(TAU * frequency * t) * (first_hit + second_hit)
		var low_echo := sin(TAU * frequency * 0.47 * t) * exp(-progress * 2.6) * 0.35
		var sample := (thud + low_echo + smear) * volume
		playback.push_frame(Vector2(sample, sample))

func _write_flashlight_pickup_sfx(playback, spec: Dictionary) -> void:
	var duration := float(spec.get("duration", 0.34))
	var frequency := float(spec.get("frequency", 940.0))
	var volume := float(spec.get("volume", 0.085))
	var frame_count := int(duration * MIX_RATE)
	for frame in range(frame_count):
		var t := float(frame) / float(MIX_RATE)
		var progress := t / duration
		var click := exp(-pow(progress * 13.0, 2.0)) * sin(TAU * 180.0 * t)
		var tube_wake := sin(TAU * (frequency + progress * 420.0) * t) * sin(progress * PI) * 0.42
		var electric := randf_range(-1.0, 1.0) * exp(-progress * 4.0) * 0.10
		var sample := (click + tube_wake + electric) * volume
		playback.push_frame(Vector2(sample, sample))

func _write_key_jingle_sfx(playback, spec: Dictionary) -> void:
	var duration := float(spec.get("duration", 0.46))
	var frequency := float(spec.get("frequency", 1260.0))
	var volume := float(spec.get("volume", 0.075))
	var frame_count := int(duration * MIX_RATE)
	for frame in range(frame_count):
		var t := float(frame) / float(MIX_RATE)
		var progress := t / duration
		var ring_a := sin(TAU * frequency * t) * exp(-progress * 5.0)
		var ring_b := sin(TAU * (frequency * 1.47) * t + 0.8) * exp(-maxf(progress - 0.16, 0.0) * 6.0) * 0.55
		var ring_c := sin(TAU * (frequency * 0.74) * t) * exp(-maxf(progress - 0.32, 0.0) * 8.0) * 0.34
		var sample := (ring_a + ring_b + ring_c) * sin(progress * PI) * volume
		playback.push_frame(Vector2(sample, sample))

func _write_cat_meow_sfx(playback, spec: Dictionary) -> void:
	var duration := float(spec.get("duration", 0.52))
	var frequency := float(spec.get("frequency", 620.0)) * randf_range(0.92, 1.06)
	var volume := float(spec.get("volume", 0.080))
	var frame_count := int(duration * MIX_RATE)
	for frame in range(frame_count):
		var t := float(frame) / float(MIX_RATE)
		var progress := t / duration
		var bend := frequency + sin(progress * PI) * 180.0 - progress * 90.0
		var voice := sin(TAU * bend * t + sin(TAU * 7.0 * t) * 0.42)
		var throat := sin(TAU * bend * 0.48 * t) * 0.30
		var breath := randf_range(-1.0, 1.0) * 0.05
		var envelope := sin(progress * PI)
		var sample := (voice + throat + breath) * envelope * volume
		playback.push_frame(Vector2(sample, sample))

func _write_leaf_stinger_sfx(playback, spec: Dictionary) -> void:
	var duration := float(spec.get("duration", 0.42))
	var frequency := float(spec.get("frequency", 330.0))
	var volume := float(spec.get("volume", 0.105))
	var noise_amount := float(spec.get("noise", 0.88))
	var frame_count := int(duration * MIX_RATE)
	for frame in range(frame_count):
		var t := float(frame) / float(MIX_RATE)
		var progress := t / duration
		var attack := exp(-pow(progress * 10.0, 2.0))
		var scrape := randf_range(-1.0, 1.0) * noise_amount * sin(progress * PI)
		var twig := sin(TAU * (frequency + progress * 120.0) * t) * attack * 0.48
		var air_suck := randf_range(-1.0, 1.0) * exp(-maxf(progress - 0.20, 0.0) * 5.0) * 0.36
		var sample := (scrape + twig + air_suck) * volume
		playback.push_frame(Vector2(sample, sample))

func _write_door_lock_heavy_sfx(playback, spec: Dictionary) -> void:
	var duration := float(spec.get("duration", 0.48))
	var frequency := float(spec.get("frequency", 118.0))
	var volume := float(spec.get("volume", 0.18))
	var noise_amount := float(spec.get("noise", 0.22))
	var frame_count := int(duration * MIX_RATE)
	for frame in range(frame_count):
		var t := float(frame) / float(MIX_RATE)
		var progress := t / duration
		var bolt_hit := exp(-pow(progress * 11.0, 2.0))
		var latch_hit := exp(-pow((progress - 0.38) * 13.0, 2.0)) * 0.82
		var body := sin(TAU * (frequency - progress * 24.0) * t) * (bolt_hit + latch_hit)
		var metal := sin(TAU * frequency * 4.3 * t) * exp(-progress * 5.5) * 0.26
		var grit := randf_range(-1.0, 1.0) * noise_amount * sin(progress * PI) * 0.22
		var sample := (body + metal + grit) * volume
		playback.push_frame(Vector2(sample, sample))

func _write_car_impact_heavy_sfx(playback, spec: Dictionary) -> void:
	var duration := float(spec.get("duration", 0.62))
	var frequency := float(spec.get("frequency", 72.0))
	var volume := float(spec.get("volume", 0.24))
	var noise_amount := float(spec.get("noise", 0.82))
	var frame_count := int(duration * MIX_RATE)
	for frame in range(frame_count):
		var t := float(frame) / float(MIX_RATE)
		var progress := t / duration
		var bumper_hit := exp(-pow(progress * 13.0, 2.0))
		var metal_crunch := exp(-pow((progress - 0.18) * 9.0, 2.0)) * 0.86
		var glass_tail := exp(-maxf(progress - 0.30, 0.0) * 5.0) * sin(progress * PI)
		var sub := sin(TAU * (frequency - progress * 20.0) * t) * (bumper_hit + metal_crunch)
		var scrape := randf_range(-1.0, 1.0) * noise_amount * (metal_crunch + glass_tail * 0.42)
		var shard := sin(TAU * (frequency * 9.4 + progress * 240.0) * t) * glass_tail * 0.16
		var sample := (sub + scrape + shard) * volume
		playback.push_frame(Vector2(sample, sample))

func _build_bgm_player() -> void:
	bgm_player = AudioStreamPlayer.new()
	bgm_player.name = "Bgm_EerieDrone"
	bgm_player.volume_db = -10.0
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = MIX_RATE
	stream.buffer_length = BGM_BUFFER_LENGTH
	bgm_player.stream = stream
	add_child(bgm_player)
	bgm_player.play()
	bgm_playback = bgm_player.get_stream_playback()
	_fill_bgm_buffer()

func _fill_bgm_buffer() -> void:
	if bgm_playback == null:
		return
	var frames_available: int = bgm_playback.get_frames_available()
	for _frame in range(frames_available):
		var sample := _next_bgm_sample()
		bgm_playback.push_frame(Vector2(sample, sample))

func _next_bgm_sample() -> float:
	if bgm_profile == "bush_maze":
		return _next_bush_maze_bgm_sample()
	if bgm_profile == "chase":
		return _next_chase_bgm_sample()
	var pulse := 0.54 + 0.46 * sin(bgm_phase_pulse)
	var intensity := 0.18 + bgm_intensity * 0.82
	var sub_rumble := sin(bgm_phase_sub) * 0.070
	var low := sin(bgm_phase_low) * 0.090
	var detuned_low := sin(bgm_phase_detune) * 0.076
	var dissonant_mid := sin(bgm_phase_mid + sin(bgm_phase_pulse) * 0.22) * 0.034
	var wire_high := sin(bgm_phase_high) * (0.010 + bgm_intensity * 0.012)
	var scrape_gate := pow(maxf(0.0, sin(bgm_phase_scrape)), 5.0)
	var scrape := randf_range(-1.0, 1.0) * scrape_gate * (0.010 + bgm_intensity * 0.026)
	var breath_noise := randf_range(-1.0, 1.0) * 0.010 * (0.45 + pulse)
	var sample := (sub_rumble + low + detuned_low + dissonant_mid + wire_high + scrape + breath_noise) * pulse * intensity
	bgm_phase_sub = fmod(bgm_phase_sub + TAU * 28.0 / MIX_RATE, TAU)
	bgm_phase_low = fmod(bgm_phase_low + TAU * 41.0 / MIX_RATE, TAU)
	bgm_phase_detune = fmod(bgm_phase_detune + TAU * 43.6 / MIX_RATE, TAU)
	bgm_phase_mid = fmod(bgm_phase_mid + TAU * 58.3 / MIX_RATE, TAU)
	bgm_phase_high = fmod(bgm_phase_high + TAU * 147.0 / MIX_RATE, TAU)
	bgm_phase_scrape = fmod(bgm_phase_scrape + TAU * (0.030 + bgm_intensity * 0.050) / MIX_RATE, TAU)
	bgm_phase_pulse = fmod(bgm_phase_pulse + TAU * (0.040 + bgm_intensity * 0.052) / MIX_RATE, TAU)
	return clampf(sample, -0.32, 0.32)

func _next_bush_maze_bgm_sample() -> float:
	var pulse := 0.42 + 0.58 * pow(maxf(0.0, sin(bgm_phase_pulse)), 2.0)
	var intensity := 0.22 + bgm_intensity * 0.78
	var sub_rumble := sin(bgm_phase_sub) * 0.060
	var detuned_low := sin(bgm_phase_detune + sin(bgm_phase_pulse) * 0.18) * 0.070
	var branch_tone := sin(bgm_phase_mid) * 0.020
	var insect_wire := sin(bgm_phase_high) * (0.010 + bgm_intensity * 0.010)
	var leaf_gate := pow(maxf(0.0, sin(bgm_phase_scrape)), 9.0)
	var leaf_scrape := randf_range(-1.0, 1.0) * leaf_gate * (0.028 + bgm_intensity * 0.036)
	var breath := randf_range(-1.0, 1.0) * 0.013 * (0.50 + pulse)
	var sample := (sub_rumble + detuned_low + branch_tone + insect_wire + leaf_scrape + breath) * intensity
	bgm_phase_sub = fmod(bgm_phase_sub + TAU * 24.0 / MIX_RATE, TAU)
	bgm_phase_low = fmod(bgm_phase_low + TAU * 36.0 / MIX_RATE, TAU)
	bgm_phase_detune = fmod(bgm_phase_detune + TAU * 38.7 / MIX_RATE, TAU)
	bgm_phase_mid = fmod(bgm_phase_mid + TAU * 69.0 / MIX_RATE, TAU)
	bgm_phase_high = fmod(bgm_phase_high + TAU * 173.0 / MIX_RATE, TAU)
	bgm_phase_scrape = fmod(bgm_phase_scrape + TAU * (0.045 + bgm_intensity * 0.090) / MIX_RATE, TAU)
	bgm_phase_pulse = fmod(bgm_phase_pulse + TAU * (0.032 + bgm_intensity * 0.040) / MIX_RATE, TAU)
	return clampf(sample, -0.34, 0.34)

func _next_chase_bgm_sample() -> float:
	var intensity := 0.26 + bgm_intensity * 0.74
	var pulse_gate := pow(maxf(0.0, sin(bgm_phase_pulse)), 7.0)
	var offbeat_gate := pow(maxf(0.0, sin(bgm_phase_scrape + PI * 0.42)), 10.0)
	var kick := sin(bgm_phase_sub) * pulse_gate * 0.18
	var running_low := sin(bgm_phase_low + sin(bgm_phase_pulse) * 0.35) * 0.070
	var detuned_pressure := sin(bgm_phase_detune) * (0.050 + pulse_gate * 0.035)
	var alarm_wail := sin(bgm_phase_mid + sin(bgm_phase_scrape) * 0.70) * (0.030 + bgm_intensity * 0.020)
	var metal_ticks := randf_range(-1.0, 1.0) * (pulse_gate + offbeat_gate * 0.58) * 0.052
	var high_scrape := randf_range(-1.0, 1.0) * offbeat_gate * (0.020 + bgm_intensity * 0.030)
	var breath_noise := randf_range(-1.0, 1.0) * 0.012 * (0.70 + pulse_gate)
	var sample := (kick + running_low + detuned_pressure + alarm_wail + metal_ticks + high_scrape + breath_noise) * intensity
	bgm_phase_sub = fmod(bgm_phase_sub + TAU * 36.0 / MIX_RATE, TAU)
	bgm_phase_low = fmod(bgm_phase_low + TAU * 49.0 / MIX_RATE, TAU)
	bgm_phase_detune = fmod(bgm_phase_detune + TAU * 53.6 / MIX_RATE, TAU)
	bgm_phase_mid = fmod(bgm_phase_mid + TAU * (98.0 + pulse_gate * 18.0) / MIX_RATE, TAU)
	bgm_phase_high = fmod(bgm_phase_high + TAU * 221.0 / MIX_RATE, TAU)
	bgm_phase_scrape = fmod(bgm_phase_scrape + TAU * (3.10 + bgm_intensity * 0.70) / MIX_RATE, TAU)
	bgm_phase_pulse = fmod(bgm_phase_pulse + TAU * (3.65 + bgm_intensity * 0.55) / MIX_RATE, TAU)
	return clampf(sample, -0.42, 0.42)
