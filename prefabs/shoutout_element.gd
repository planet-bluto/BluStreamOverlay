extends Control

signal music_done()

const MUTED_VOL = -25.0
const ACTUALLY_MUTED_VOL = -80.0
const FULL_VOL = -10.0

@export var media_texture: Texture
@export var music_stream: AudioStream
@export var video_stream: VideoStream
@export var entry: Dictionary

var ThePlayer

var is_music_done = false

func _process(delta):
	if ($Media.texture != media_texture):
		$Media.texture = media_texture
	
	if ($Music.stream != music_stream):
		$Music.stream = music_stream
	
	if ($Video.stream != video_stream):
		$Video.stream = video_stream
		$Video.volume_db = ACTUALLY_MUTED_VOL
		$Video.play()
		
	if (entry.has("fields") and entry.fields.has("Video")):
		ThePlayer = $Video
	else:
		ThePlayer = $Music
	
	var end_time = (10.75 if $Music.stream == null else $Music.stream.get_length() - 0.75)
	if (entry.has("file_end") and entry.file_end != null and entry.file_end > 0):
		end_time = float(entry.file_end) + 0.75
	
	if (not is_music_done and ($Music.get_playback_position() >= end_time)):
		is_music_done = true
		music_done.emit()

var VolumeTween: Tween
func trans_in():
	ThePlayer.volume_db = MUTED_VOL
	
	var start_time = 0.0
	if (entry.has("file_start") and entry.file_start != null and entry.file_start > 0):
		start_time = float(entry.file_start)
	
	if (entry.has("fields") and entry.fields.has("Music")):
		ThePlayer.play(start_time)
	
	if (VolumeTween): VolumeTween.kill()
	VolumeTween = create_tween()
	
	#VolumeTween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	
	VolumeTween.set_parallel()
	VolumeTween.set_trans(Tween.TRANS_CUBIC)
	VolumeTween.set_ease(Tween.EASE_OUT)
	
	VolumeTween.tween_property(ThePlayer, "volume_db", FULL_VOL, 1.0)
	
	VolumeTween.play()
	
	await VolumeTween.finished

func trans_out(FULL = false):
	#$Music.volume_db = FULL_VOL
	#$Music.play()
	
	if (VolumeTween): VolumeTween.kill()
	VolumeTween = create_tween()
	
	#VolumeTween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	
	VolumeTween.set_parallel()
	VolumeTween.set_trans(Tween.TRANS_CUBIC)
	VolumeTween.set_ease(Tween.EASE_OUT)
	
	VolumeTween.tween_property(ThePlayer, "volume_db", (MUTED_VOL if (not FULL) else ACTUALLY_MUTED_VOL), (1.0 if (not FULL) else 10.0))
	
	VolumeTween.play()
	
	await VolumeTween.finished
	
	ThePlayer.volume_db = ACTUALLY_MUTED_VOL
