class_name VoiceChat3D
extends Node

# NOTE: it's recommended to add "mic_enabled" to a MultiplayerSynchronizer

# TODO:
# - cull sounds outside of hearing range
# - compress from stereo float32 to mono int16 to reduce data by 4
# - use a opus/VoIP lib like "twovoip" (it's good enough for now but it could reduce
#   data from to 96KB/s to ~3-6KB)
# - raytraced audio (see lib from bryson mcbee example)
# - skip silent mic chunks

signal mic_changed(enabled: bool)

@export var input: AudioStreamPlayer
@export var output: AudioStreamPlayer3D
@export var listener: AudioListener3D
@export var chunk_size = 512
@export var minimum_chunk_volume = 0.005

const rpc_channel = 0
var mic_enabled = false: set = _set_mic_enabled
var current_volume: float = 0.0

var _buffer: PackedVector2Array

var _bus_name: String
var _bus_index: int

var _audio_capture: AudioEffectCapture
var _playback: AudioStreamGeneratorPlayback

func _ready() -> void:
	_bus_name = input.bus
	_bus_index = AudioServer.get_bus_index(_bus_name)
	_audio_capture = AudioServer.get_bus_effect(_bus_index, 0)
	
	if is_multiplayer_authority():
		input.stream = AudioStreamMicrophone.new()
		input.play()
		listener.make_current()
	else:
		input.stop()
		output.play()
		listener.queue_free()
		_playback = output.get_stream_playback()


func _process(delta: float) -> void:
	if is_multiplayer_authority():
		_read_mic_data()
	
	#current_volume = lerp(current_volume, 0.0, delta * 5.0)


func mute():
	mic_enabled = false


func unmute():
	mic_enabled = true


func _read_mic_data():
	if not mic_enabled:
		return
	
	var frame_count = _audio_capture.get_frames_available()
	
	if frame_count > 0:
		var voice_data: PackedVector2Array = _audio_capture.get_buffer(frame_count)
		_buffer.append_array(voice_data)
		#_audio_capture.clear_buffer()
	
	current_volume = 0.0
	while _buffer.size() >= chunk_size:
		var chunk = _buffer.slice(0, chunk_size)
		_buffer = _buffer.slice(chunk_size)
		
		current_volume = _compute_rms(chunk)
		
		#if _get_peak_amplitude(chunk) > minimum_chunk_volume:
		var compr_chunk = _compress_frames(chunk)
		_receive_voice_frames.rpc(compr_chunk)


@rpc("any_peer", "call_remote", "unreliable", rpc_channel)
func _receive_voice_frames(data: PackedByteArray):
	if data.is_empty():
		return
	
	var decomp_data = _decompress_frames(data)
	if not decomp_data.is_empty() and _playback.get_frames_available() >= decomp_data.size():
		current_volume = _compute_rms(decomp_data)
		_playback.push_buffer(decomp_data)


func _set_mic_enabled(value: bool):
	mic_enabled = value
	
	if not is_node_ready():
		await ready
	
	if value:
		mic_changed.emit(true)
		input.play()
	else:
		mic_changed.emit(false)
		input.stop()


func _compute_rms(frames: PackedVector2Array) -> float:
	if frames.is_empty():
		return 0.0
	var sum_sq := 0.0
	for f in frames:
		var mono := (f.x + f.y) * 0.5
		sum_sq += mono * mono
	return sqrt(sum_sq / frames.size())


func _get_peak_amplitude(frames: PackedVector2Array) -> float:
	var max = 0.0
	for f in frames:
		max = maxf(max, absf(f.x))
	return max


# float32 (8 bytes/frame) -> mono int16 (2 bytes/frame)
func _compress_frames(frames: PackedVector2Array) -> PackedByteArray:
	var bytes := PackedByteArray()
	bytes.resize(frames.size() * 2)
	for i in frames.size():
		var mono := clampf((frames[i].x + frames[i].y) * 0.5, -1.0, 1.0)
		bytes.encode_s16(i * 2, int(mono * 32767.0))
	return bytes


func _decompress_frames(bytes: PackedByteArray) -> PackedVector2Array:
	var count := bytes.size() / 2
	var frames := PackedVector2Array()
	frames.resize(count)
	for i in count:
		var sample := bytes.decode_s16(i * 2) / 32767.0
		frames[i] = Vector2(sample, sample)
	return frames
