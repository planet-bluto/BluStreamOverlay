extends Node3D

#-------------------------------------------------#

const X_EXTENT = 2500.0
const Y_EXTENT = 2680.0
const TALKING_BUFFER = 30

const MOUTH_CLOSED_TEXTURE = preload("res://rigs/bluto2_mouth_woozy.png")
const MOUTH_OPEN_TEXTURE = preload("res://rigs/bluto2_mouth_open.png")

const FOLLOWER_PREFAB = preload("res://prefabs/follower.tscn")

const BLU_DISCORD_ID = "334039742205132800"
const TALKY_PREFAB = preload("res://prefabs/talky.tscn")

const OMNI_ICONS = {
	"SC": preload("res://textures/omni_icons/SC.png"),
	"YT": preload("res://textures/omni_icons/YT.png"),
	"BC": preload("res://textures/omni_icons/BC.png"),
}

#-------------------------------------------------#

@onready var Blu = $"bluto2_0 - blutuber"
@onready var Anim = $"bluto2_0 - blutuber/AnimationPlayer"
@onready var Skel = $"bluto2_0 - blutuber/Armature/Skeleton3D"
@onready var Mouth = $"bluto2_0 - blutuber/Armature/Skeleton3D/Mouth"
@onready var SpeakingFX = $"bluto2_0 - blutuber/Armature/Skeleton3D/BoneAttachment3D2/SpeakingFX"
@onready var VinylPlayer = $DeskContainer/NowPlaying/VinylPlayer/Armature/Skeleton3D/MeshInstance3D
@onready var VinylPlayerViewport = $DeskContainer/NowPlaying/VinylPlayer/SubViewport
@onready var VinylPlayerLabel = $DeskContainer/NowPlaying/VinylPlayer/SubViewport/Control/ScrollContainer/MarginContainer/Label
@onready var VinylPlayerScreen = $DeskContainer/NowPlaying/VinylPlayer/SubViewport/Control
@onready var Vinyl = $DeskContainer/NowPlaying/Vinyl
@onready var NowPlayingAnim = $DeskContainer/NowPlaying/AnimationPlayer


@onready var Orbits = $"bluto2_0 - blutuber/Orbits"

#-------------------------------------------------#

var blu_float_frame = 0
var blu_mouse_pos = Vector2.ZERO
var talking = false
var talking_timer = 0
var talking_cooldown = 0
var mouth_material: StandardMaterial3D
var voice_chat_connected = false

#-------------------------------------------------#

func _ready():
	Socket.voice_event.connect(_voice_event)
	Socket.voice_join_event.connect(_voice_join_event)
	Socket.voice_left_event.connect(_voice_left_event)
	Socket.disconnected.connect(_voice_left_event)
	
	Socket.omni_now_playing.connect(_omni_now_playing)
	Socket.omni_progress.connect(_omni_progress)
	Socket.omni_status.connect(_omni_status)
	
	#Socket.chat.connect(_handle_chat)
	Socket.spark_event.connect(_handle_spark_event)
	
	Anim.play("Armature_001")
	mouth_material = Mouth.mesh.surface_get_material(0)
	
	var material: StandardMaterial3D = VinylPlayer.mesh.surface_get_material(2).duplicate(true)
	material.albedo_texture = VinylPlayerViewport.get_texture()
	#material.resource_local_to_scene = true
	VinylPlayer.set_surface_override_material(2, material)

var MouthTween: Tween
func _process(delta):
	# Floating
	var blu_base_y = -0.333
	var blu_float_amount = 0.5
	var blu_float_sine = sin(float(blu_float_frame) / 50.0)
	var blu_float_perc = remap(blu_float_sine, -1.0, 1.0, 0.0, 1.0)
	Blu.position.y = lerp(blu_base_y, blu_base_y+blu_float_amount, blu_float_perc)
	blu_float_frame += 1
	
	var mouse_pos_i = DisplayServer.mouse_get_position()
	var mouse_pos = Vector2(mouse_pos_i.x, mouse_pos_i.y)
	blu_mouse_pos = lerp(blu_mouse_pos, mouse_pos, (1.0/3.0))
	#print(mouse_pos)
	
	const HEAD_BOB_AMOUNT = 0.08
	
	var x_value = ((X_EXTENT - blu_mouse_pos.x) / X_EXTENT)
	var y_value = ease((blu_mouse_pos.y / Y_EXTENT) + ((blu_float_sine) * HEAD_BOB_AMOUNT), 0.9)
	
	#Anim.play("Armature_001")
	Anim.seek(float(Anim.current_animation_length) * x_value, true)
	
	var ANG_MIN = 5
	var ANG_MAX = 50
	var x_ang = lerp(ANG_MIN, ANG_MAX, y_value)
	var curr_rot = Skel.get_bone_pose_rotation(2).get_euler()
	Skel.set_bone_pose_rotation(2, Quaternion.from_euler(Vector3(deg_to_rad(x_ang), curr_rot.y, curr_rot.z)))
	
	if (talking):
		if (talking_timer < 0):
			talking_timer = 0
		talking_timer += 1
	else:
		if (talking_timer > 0):
			talking_timer = 0
			talking_timer -= 1
	SpeakingFX.visible = talking
	
	if (abs(talking_timer) == 1):
		mouth_material.albedo_texture = (MOUTH_OPEN_TEXTURE if talking else MOUTH_CLOSED_TEXTURE)
		
		var fx_scale = 1.2
		SpeakingFX.scale = Vector3(fx_scale, fx_scale, fx_scale)
		Mouth.scale.y = 1.1 + ((1-y_value) * 0.5)
		if (not talking): Mouth.position.y = 0.1
		
		if (MouthTween): MouthTween.kill()
		MouthTween = create_tween()
		
		#MouthTween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
		
		MouthTween.set_parallel()
		MouthTween.set_trans(Tween.TRANS_BACK if talking else Tween.TRANS_CUBIC)
		MouthTween.set_ease(Tween.EASE_OUT)
		
		MouthTween.tween_property(SpeakingFX, "scale", Vector3(1.0, 1.0, 1.0), 0.25)
		MouthTween.tween_property(Mouth, "scale:y", 1.0, (0.5 if talking else 0.25))
		if (not talking): MouthTween.tween_property(Mouth, "position:y", 0.0, 0.25)
		
		MouthTween.play()
	
	_animate_talkies(delta)
	_animate_vinyl(delta)

const ORBIT_RADIUS_X = 2.5
const ORBIT_RADIUS_Y = 3.0
var orbit_ang = 0.0

var prev_count = 0.0
var count = 0.0
var current_count = 0.0

var TalkyTween: Tween
func _animate_talkies(delta):
	var frame_const = (1.0 / 60.0)
	var delta_weight = (delta / frame_const)
	#Orbits.rotation_degrees.y += 1
	orbit_ang += (0.75 * delta_weight)
	
	count = Orbits.get_child_count()
	if (prev_count != count):
		prev_count = count
		
		if (TalkyTween): TalkyTween.kill()
		TalkyTween = create_tween()
		
		#MouthTween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
		
		TalkyTween.set_parallel()
		TalkyTween.set_trans(Tween.TRANS_CUBIC)
		TalkyTween.set_ease(Tween.EASE_OUT)
		
		TalkyTween.tween_property(self, "current_count", float(count), 1)
		
		TalkyTween.play()
	
	#var ang_iter = (360.0 / float(current_count))
	const MIN_ANG = -155.0
	const MAX_ANG = 60.0
	
	var ang_iter = ((MAX_ANG - MIN_ANG) / current_count)
	#var ang_iter = (360.0 / current_count)
	
	for ind in count:
		var talky = Orbits.get_child(ind)
		#talky.target_angle = (MIN_ANG + (ang_iter * (ind+1)))
		var raw_angle = (orbit_ang + (ang_iter * (ind+1)))
		talky.target_angle = wrap(raw_angle, MIN_ANG, MAX_ANG)
		#talky.position.x = cos(deg_to_rad(MIN_ANG + (ang_iter * (ind+1)))) * ORBIT_RADIUS_X
		#talky.position.x = cos(deg_to_rad(ang_iter)) * ORBIT_RADIUS_X
		#talky.position.z = sin(deg_to_rad(MIN_ANG + (ang_iter * (ind+1)))) * ORBIT_RADIUS_Y
		#talky.position.z = sin(deg_to_rad(ang_iter)) * ORBIT_RADIUS_Y
		
		talky.visible = (((ind+1) - 0.5) < current_count)

#-------------------------------------------------#

func makeIndicator(speaker):
	if (speaker.id != BLU_DISCORD_ID): #get the fuck out blu
		var talky = TALKY_PREFAB.instantiate()
		talky.add_to_group("TALKY_%s" % speaker.id)
		talky.speaker = speaker
		Orbits.add_child(talky)

func _voice_event(type, speaker):
	if (speaker.id == BLU_DISCORD_ID): # Blu Talking Indicator
		if (type == "speak"):
			talking = speaker.speaking
	else:
		match type: # Everyone elses :)
			"speak":
				for talky in get_tree().get_nodes_in_group("TALKY_%s" % speaker.id):
					talky.talking = speaker.speaking
			"join":
				makeIndicator(speaker)
			"leave":
				for talky in get_tree().get_nodes_in_group("TALKY_%s" % speaker.id):
					talky.queue_free()
			"mute":
				pass
			"deafen":
				pass

func _voice_join_event(speakers):
	voice_chat_connected = true
	_voice_left_event()
	for speaker in speakers:
		makeIndicator(speaker)

func _voice_left_event():
	talking = false
	voice_chat_connected = false
	for talky in Orbits.get_children():
		talky.queue_free()

#-------------------------------------------------#

var PlayingSong = {}

func _omni_now_playing(event):
	print("Omni Now Playing:", event)
	
	NowPlayingAnim.play_backwards("TRANSITION")
	await NowPlayingAnim.animation_finished
	
	PlayingSong = event.track
	VinylPlayerLabel.text = "%s [img]res://textures/omni_icons/%s.png[/img] %s" % [PlayingSong.title, PlayingSong.service.code, PlayingSong.author.name]
	
	var result = await Fetch.request_image(PlayingSong.image)
	var image: Image = result.image
	image = image.get_region(image.get_used_rect())
	var image_width = image.get_width()
	var image_height = image.get_height()
	if (image_width != image_height):
		var image_rect: Rect2i
		var side = min(image_width, image_height)
		if (side == image_height):
			var _x = round((image_width/2) - (image_height/2))
			var _y = 0
			var _w = image_height
			var _h = image_height
			image_rect = Rect2i(_x, _y, _w, _h)
		else:
			var _x = 0
			var _y = round((image_height/2) - (image_width/2))
			var _w = image_width
			var _h = image_width
			image_rect = Rect2i(_x, _y, _w, _h)
		image = image.get_region(image_rect)
	
	var grey_background = Image.new()
	grey_background.copy_from(image)
	grey_background.fill(Color("#050505"))
	grey_background.blend_rect(image, image.get_used_rect(), Vector2i.ZERO)
	image = grey_background
	
	var image_texture = ImageTexture.create_from_image(image)
	var vinyl_mesh: Mesh = Vinyl.mesh
	var thumbnail_mat = vinyl_mesh.surface_get_material(3)
	thumbnail_mat.albedo_texture = image_texture
	
	NowPlayingAnim.play("TRANSITION")

func _omni_progress(event):
	#print("Omni Progress:", event)
	pass

func _omni_status(event):
	#print("Omni Status:", event)
	pass

func _animate_vinyl(delta):
	var frame_const = (1.0 / 60.0)
	var delta_weight = (delta / frame_const)
	Vinyl.rotation_degrees.y -= (0.6 * delta_weight)

func _handle_chat(author, text: String, platform, author_style, flags, icons):
	if (text.begins_with("spawn_spark")):
		_spawn_spark()

func _handle_spark_event(type, spark, timestamp, extras):
	#print("type", type)
	#print("spark", spark)
	#print("timestamp", timestamp)
	#print("extras", extras)
	
	if (type == "null"): return
	
	var active_followers = get_tree().get_nodes_in_group("SPARKS_%s" % spark.user.id)
	if (active_followers.size() == 0):
		_spawn_spark(spark.prominent_charge, spark.user.displayName, spark.user.id)
	else:
		for spark_follower in active_followers:
			spark_follower.get_child(0).TYPE = spark.prominent_charge
			spark_follower.replenish()

func _spawn_spark(type = "BOLTA", username = "", user_id = ""):
	type = type.to_upper()
	var follower_inst = FOLLOWER_PREFAB.instantiate()
	follower_inst.add_to_group("SPARKS_%s" % user_id)
	
	follower_inst.get_child(0).TYPE = type
	follower_inst.get_child(0).USER = username
	
	var this_path = $SparkPaths.get_children().pick_random()
	this_path.add_child(follower_inst)
