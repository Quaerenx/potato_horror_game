extends Node

const MIX_RATE := 22050
const BGM_BUFFER_LENGTH := 1.4

var sfx_players := {}
var bgm_player: AudioStreamPlayer
var bgm_playback
var bgm_phase_low := 0.0
var bgm_phase_mid := 0.0
var bgm_phase_high := 0.0
var bgm_phase_pulse := 0.0
var bgm_intensity := 0.55
var bgm_target_intensity := 0.55
var sfx_specs := {
	"footstep": {"duration": 0.055, "frequency": 95.0, "volume": 0.11, "noise": 0.45},
	"spray": {"duration": 0.18, "frequency": 820.0, "volume": 0.16, "noise": 0.70},
	"spray_miss": {"duration": 0.11, "frequency": 520.0, "volume": 0.09, "noise": 0.55},
	"spray_empty": {"duration": 0.10, "frequency": 180.0, "volume": 0.10, "noise": 0.18},
	"door_locked": {"duration": 0.16, "frequency": 150.0, "volume": 0.18, "noise": 0.10},
	"streetlight": {"duration": 0.34, "frequency": 1180.0, "volume": 0.075, "noise": 0.20},
	"panic_step": {"duration": 0.22, "frequency": 110.0, "volume": 0.14, "noise": 0.55},
	"chase_start": {"duration": 0.42, "frequency": 64.0, "volume": 0.20, "noise": 0.25},
	"game_over": {"duration": 0.48, "frequency": 52.0, "volume": 0.22, "noise": 0.18},
	"rescue_honk": {"duration": 0.36, "frequency": 430.0, "volume": 0.18, "noise": 0.02},
	"bush_rustle": {"duration": 0.26, "frequency": 240.0, "volume": 0.08, "noise": 0.92},
	"distant_step": {"duration": 0.20, "frequency": 82.0, "volume": 0.10, "noise": 0.38},
	"fluorescent": {"duration": 0.32, "frequency": 960.0, "volume": 0.065, "noise": 0.16},
	"auto_door": {"duration": 0.20, "frequency": 620.0, "volume": 0.09, "noise": 0.06},
	"heartbeat": {"duration": 0.28, "frequency": 58.0, "volume": 0.14, "noise": 0.12},
	"phone_ring": {"duration": 0.70, "frequency": 520.0, "volume": 0.12, "noise": 0.03},
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
	player.play()
	var playback = player.get_stream_playback()
	if playback == null:
		return
	if playback.has_method("clear_buffer"):
		playback.clear_buffer()
	_write_generated_sfx(playback, spec)

func _write_generated_sfx(playback, spec: Dictionary) -> void:
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
	var low := sin(bgm_phase_low) * 0.11
	var mid := sin(bgm_phase_mid) * 0.045
	var high := sin(bgm_phase_high) * 0.018
	var pulse := 0.62 + 0.38 * sin(bgm_phase_pulse)
	var noise := randf_range(-1.0, 1.0) * 0.012
	var intensity := 0.18 + bgm_intensity * 0.82
	var sample := (low + mid + high + noise) * pulse * intensity
	bgm_phase_low = fmod(bgm_phase_low + TAU * 43.0 / MIX_RATE, TAU)
	bgm_phase_mid = fmod(bgm_phase_mid + TAU * 51.7 / MIX_RATE, TAU)
	bgm_phase_high = fmod(bgm_phase_high + TAU * 96.3 / MIX_RATE, TAU)
	bgm_phase_pulse = fmod(bgm_phase_pulse + TAU * (0.055 + bgm_intensity * 0.035) / MIX_RATE, TAU)
	return sample
