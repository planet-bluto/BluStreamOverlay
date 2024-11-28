extends Node3D

#-------------------------------------------------#

const SQUARE_MESH = preload("res://talking_indicators/SQUARE_MESH.tres")
const CIRCLE_MESH = preload("res://talking_indicators/CIRCLE_MESH.tres")

const OPEN_MATERIAL = preload("res://materials/OPEN_TALKING.tres")
const CLOSED_MATERIAL = preload("res://materials/CLOSED_TALKING.tres")

const ORBIT_RADIUS_X = 2.5
const ORBIT_RADIUS_Y = 3.0

#-------------------------------------------------#

signal start_talking()
signal stop_talking()

#-------------------------------------------------#

var speaker = {}
var custom = null
var talking = false
var talking_timer = 0
var current_angle = -160.0
var target_angle = current_angle

#-------------------------------------------------#

func _setup_mesh(MESH_TYPE):
	$Open.mesh = MESH_TYPE.duplicate(true)
	$Closed.mesh = MESH_TYPE.duplicate(true)
	
	var open_mat = OPEN_MATERIAL.duplicate(true)
	$Open.mesh.surface_set_material(0, open_mat)
	var closed_mat = CLOSED_MATERIAL.duplicate(true)
	$Closed.mesh.surface_set_material(0, closed_mat)
	
	return [open_mat, closed_mat]

func _ready():
	start_talking.connect(_start_talking)
	stop_talking.connect(_stop_talking)
	
	if (Talkies.CUSTOMS.has(speaker.id)):
		var mats = _setup_mesh(SQUARE_MESH)
		
		custom = Talkies.CUSTOMS[speaker.id]
		
		mats[0].albedo_texture = Talkies.TEXTURES[custom].open
		mats[1].albedo_texture = Talkies.TEXTURES[custom].closed
		
		if (Talkies.TRANSFORMS.has(custom)):
			var transforms = Talkies.TRANSFORMS[custom]
			scale = Globals.LinkedVector3(transforms.scale)
	else:
		var result = await Fetch.request_image(speaker.avatar)
		var image = result.image
		#image = GDimp.palettify(image, "blubot")
		var image_texture = ImageTexture.create_from_image(image)
		
		var mats = _setup_mesh(CIRCLE_MESH)
		
		mats[0].albedo_texture = image_texture
		mats[1].albedo_texture = image_texture
	
	if (Talkies.RIFFS.has(speaker.id)):
		var riff = Talkies.RIFFS[speaker.id]
		var sound = Talkies.SOUNDS[riff]
		$AudioStreamPlayer.stream = sound
		print("PLAYING THIS FOR SOME REASON, LOL")
		$AudioStreamPlayer.play()

var prev_angle = current_angle
func _process(delta):
	if (talking):
		if (talking_timer < 0):
			talking_timer = 0
		talking_timer += 1
	else:
		if (talking_timer > 0):
			talking_timer = 0
			talking_timer -= 1
	
	$Open.visible = talking
	$Closed.visible = (not talking)
	
	position.x = cos(deg_to_rad(current_angle)) * ORBIT_RADIUS_X
	position.z = sin(deg_to_rad(current_angle)) * ORBIT_RADIUS_Y
	
	var angle_diff = abs(prev_angle - target_angle)
	
	if (angle_diff < 1):
		current_angle = lerp(current_angle, target_angle, 0.8)
	else:
		current_angle = target_angle
	
	prev_angle = target_angle

func _start_talking():
	pass

func _stop_talking():
	pass
