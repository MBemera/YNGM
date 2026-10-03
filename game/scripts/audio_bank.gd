class_name AudioBank
extends RefCounted

const DART := preload("res://assets/audio/sfx/dart.wav")
const CONFETTI := preload("res://assets/audio/sfx/confetti.wav")
const HIT := preload("res://assets/audio/sfx/hit.wav")
const HURT := preload("res://assets/audio/sfx/hurt.wav")
const THROW := preload("res://assets/audio/sfx/throw.wav")
const BEAM := preload("res://assets/audio/sfx/beam.wav")
const WIN := preload("res://assets/audio/sfx/win.wav")
const LOSE := preload("res://assets/audio/sfx/lose.wav")
const ROTOR := preload("res://assets/audio/sfx/rotor.wav")
const SLOP_EXPLOSION := preload("res://assets/audio/sfx/slop_explosion.wav")
const BOUNCE := preload("res://assets/audio/sfx/bounce.wav")
const PICKUP := preload("res://assets/audio/sfx/pickup.wav")
const STAPLE := preload("res://assets/audio/sfx/staple.wav")
const RAIL := preload("res://assets/audio/sfx/rail.wav")
const BUBBLE := preload("res://assets/audio/sfx/bubble.wav")
const POP := preload("res://assets/audio/sfx/pop.wav")
const ZAP := preload("res://assets/audio/sfx/zap.wav")
const OBJECTIVE := preload("res://assets/audio/sfx/objective.wav")
const ALARM := preload("res://assets/audio/sfx/alarm.wav")
const SLAM := preload("res://assets/audio/sfx/slam.wav")

const VOICE_FOLDER := "res://assets/audio/voice/"
const VOICES: Array[String] = ["norman", "kristin", "john"]
const YELL_LINE_IDS: Array[String] = ["left_behind", "not_gonna_make_it"]
const DEFEAT_LINE_IDS: Array[String] = [
	"we_will_pass", "pivoting", "acqui_hired", "take_offline", "unsubscribing", "package_delivered",
	"youre_in_the_round", "meeting_adjourned", "everybody_gets_a_ladder",
]
const HURT_LINE_IDS: Array[String] = ["my_valuation", "not_in_term_sheet"]
const SLOP_LINE_IDS: Array[String] = ["does_not_compile", "who_wrote_this"]
const STUN_LINE_IDS: Array[String] = ["cannot_comment"]


static func get_voice_clip_path(voice_name: String, line_id: String) -> String:
	return VOICE_FOLDER + "%s_%s.wav" % [voice_name, line_id]


static var voice_cache: Dictionary = {}


static func get_voice_clip(voice_name: String, line_id: String) -> AudioStream:
	var path := get_voice_clip_path(voice_name, line_id)
	if not voice_cache.has(path):
		voice_cache[path] = load(path)
	return voice_cache[path]


static func preload_enemy_voices() -> void:
	var line_ids: Array[String] = YELL_LINE_IDS + DEFEAT_LINE_IDS + HURT_LINE_IDS + SLOP_LINE_IDS + STUN_LINE_IDS
	for voice_name: String in VOICES:
		for line_id: String in line_ids:
			get_voice_clip(voice_name, line_id)


static func get_story_clip_path(voice_name: String, line_id: String) -> String:
	return VOICE_FOLDER + "%s_story_%s.wav" % [voice_name, line_id]


static func get_story_clip(voice_name: String, line_id: String) -> AudioStream:
	return load(get_story_clip_path(voice_name, line_id))


static func play_at(parent: Node, stream: AudioStream, position: Vector3, pitch := 1.0, volume_db := 0.0) -> void:
	var audio_player := AudioStreamPlayer3D.new()
	audio_player.stream = stream
	audio_player.pitch_scale = pitch
	audio_player.volume_db = volume_db
	audio_player.unit_size = 8.0
	audio_player.max_distance = 60.0
	parent.add_child(audio_player)
	audio_player.global_position = position
	audio_player.finished.connect(audio_player.queue_free)
	audio_player.play()


static func play_ui(parent: Node, stream: AudioStream, volume_db := 0.0, pitch := 1.0) -> void:
	var audio_player := AudioStreamPlayer.new()
	audio_player.stream = stream
	audio_player.volume_db = volume_db
	audio_player.pitch_scale = pitch
	parent.add_child(audio_player)
	audio_player.finished.connect(audio_player.queue_free)
	audio_player.play()
