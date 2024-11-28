extends Node3D

#-------------------------------------------------#

signal landed

#-------------------------------------------------#

const BLEND_TIME = 0.1
const BASICALLY_ZERO = 0.001
const JUMP_HEIGHT = 3.0
const END_SCREEN_JUMP_HEIGHT = 1.8

#-------------------------------------------------#

var current_ad_packed = null
var ad_timer = Timer.new()
var ad_label_timer = Timer.new()

@export var jumping = false
var awaiting_jump = false
var hovering = false
var stop_fucking_hovering = false
var idling = false
var dest_value = 0.0
var value = 0.0
var stopping_float = false
var falling = false
var end_screen = false

#-------------------------------------------------#

const LENGTH = {
	"LONG": 30.0,
	"MED": 20.0,
	"SHORT": 10.0,
}

const AD_DEFAULTS = {
	"transition": 0.0,
	"desc": "",
	"disabled": false,
	"users": [INF]
}

var active_chatters = [INF]

var current_ad_num = -1
var current_ad_index = 0
var ADS = {
	"PROJECT_HTTP": {
		"path": ("res://prefabs/ads/PROJECT_HTTP.tscn"),
		"length": LENGTH.LONG,
		"desc": "Game I'm working on; Fast paced character-based technical kart racer",
		"transition": (1.0 * 0.75),
	},
	"AUTOMAPHONICA": {
		"path": ("res://prefabs/ads/AUTOMAPHONICA.tscn"),
		"length": LENGTH.MED,
		"desc": "Music collective I'm in; Digital Fusion artist collective and label for energetic, groovy, and loud music.",
	},
	"EYES_WIDE": {
		"path": ("res://prefabs/ads/EYES_WIDE.tscn"),
		"length": LENGTH.MED,
		"desc": "",
	},
	"NUMA": {
		"path": ("res://prefabs/ads/NUMA.tscn"),
		"length": LENGTH.SHORT,
		"desc": "",
	},
	"DO_YOU_SEE_IT?": {
		"path": ("res://prefabs/ads/DO_YOU_SEE_IT.tscn"),
		"length": LENGTH.SHORT,
		"desc": "Do you see it?",
	},
	"KING_PIN": {
		"path": ("res://prefabs/ads/KING_PIN.tscn"),
		"length": LENGTH.SHORT,
		"desc": "Kill that guy.",
		"users": ["415276218"]
	},
	"HAPPY_GAY": {
		"path": ("res://prefabs/ads/PRIDE.tscn"),
		"length": LENGTH.SHORT,
		"desc": "Gay.",
		"users": ["406313588"]
	},
	"NIKO_CURSORS": {
		"path": ("res://prefabs/ads/NIKO_CURSORS.tscn"),
		"length": LENGTH.SHORT,
		"desc": "Check out these cool one-shot cursors: https://ko-fi.com/s/93855efed5",
		"users": ["415276218"]
	},
	"WAVE_RIDER": {
		"path": ("res://prefabs/ads/WAVE_RIDER.tscn"),
		"length": LENGTH.SHORT,
		"desc": "",
		"users": ["190089208"]
	},
	"ACRID": {
		"path": ("res://prefabs/ads/ACRID.tscn"),
		"length": LENGTH.SHORT,
		"desc": "",
		"users": ["1012435492"]
	},
	"KIPPER": {
		"path": ("res://prefabs/ads/KIPPER.tscn"),
		"length": LENGTH.SHORT,
		"desc": "",
		"users": ["1012435492"]
	},
	"GRYN_CLOSER": {
		"path": ("res://prefabs/ads/GRYN_CLOSER.tscn"),
		"length": LENGTH.SHORT,
		"desc": "@grynmoor",
		"users": ["163206578", "535380036"]
	},
	"MEAT": {
		"path": ("res://prefabs/ads/MEAT.tscn"),
		"length": LENGTH.SHORT,
		"desc": "@m_eeat",
		"users": ["193868107"]
	},
	"SEPHIROTH": {
		"path": ("res://prefabs/ads/SEPHIROTH.tscn"),
		"length": LENGTH.SHORT,
		"desc": "malewife",
		"users": ["464537889"]
	},
	"ELPHELT": {
		"path": ("res://prefabs/ads/ELPHELT.tscn"),
		"length": LENGTH.SHORT,
		"desc": "HAI HIII!! :3",
		"users": ["415276218"]
	},
	"NIKO_SAD": {
		"path": ("res://prefabs/ads/NIKO_SAD.tscn"),
		"length": LENGTH.SHORT,
		"desc": "@FusionSyrup",
		"users": ["415276218"]
	},
	"JOEL": {
		"path": ("res://prefabs/ads/JOEL.tscn"),
		"length": LENGTH.SHORT,
		"desc": "joel.",
		"users": ["148586323"]
	},
	"BUGINGI": {
		"path": ("res://prefabs/ads/BUGINGI.tscn"),
		"length": 10,
		"desc": "https://steamcommunity.com/sharedfiles/filedetails/?id=2501609403",
	},
}
var AD_ORDER = ADS.keys()

#-------------------------------------------------#

@onready var Screen = $Armature/Skeleton3D/Head/SubViewportContainer/SubViewport/Control
@onready var EndScreen: EndScreenClass = Screen.get_node("EndScreen")

#-------------------------------------------------#

func _ready():
	#print("hai :3")
	Socket.current_ad_request.connect(_current_ad_request)
	Socket.ad_request.connect(_ad_request)
	Socket.active_chat.connect(_active_chat)
	Socket.end_screen_start.connect(_end_screen_start)
	
	EndScreen.ended.connect(_end_screen_end)
	
	for label in ADS.keys():
		for key in AD_DEFAULTS.keys():
			if (not ADS[label].has(key)):
				ADS[label][key] = AD_DEFAULTS[key]
	
	ad_timer.one_shot = true
	ad_timer.autostart = false
	add_child(ad_timer)
	
	ad_timer.timeout.connect(_ad_timer_timeout)
	
	ad_label_timer.one_shot = true
	ad_label_timer.autostart = false
	add_child(ad_label_timer)
	
	ad_label_timer.timeout.connect(_ad_label_show)
	
	#-------------------------------------------------#
	
	#$AnimationPlayer.play_backwards("FloatStart_2", BLEND_TIME)
	
	await get_tree().process_frame
	
	var material: StandardMaterial3D = $Armature/Skeleton3D/Head.mesh.surface_get_material(4).duplicate(true)
	material.albedo_texture = $Armature/Skeleton3D/Head/SubViewportContainer/SubViewport.get_texture()
	$Armature/Skeleton3D/Head.set_surface_override_material(4, material)

func _ease_expo_in(x):
	return (0.0 if x == 0.0 else pow(2, 10 * x - 10))

var hover_frame = 0
func _physics_process(delta):
	if (jumping):
		if (awaiting_jump):
			awaiting_jump = false
			$RiseSFX.play()
		position.x = -(dest_value - value)
		position.y = (dest_value - value)
		
		if (value < BASICALLY_ZERO):
			value = 0
			jumping = false
			if (not stop_fucking_hovering): hovering = true
			#print("hovering now...")
			hover_frame = 0
		else:
			var frame_const = (1.0 / 60.0)
			var delta_weight = (delta / frame_const)
			value = lerp(value, 0.0, (0.15 * delta_weight))
	else:
		dest_value = (JUMP_HEIGHT if not end_screen else END_SCREEN_JUMP_HEIGHT)
		value = (JUMP_HEIGHT if not end_screen else END_SCREEN_JUMP_HEIGHT)
	
	if (hovering):
		position.y = ((JUMP_HEIGHT if not end_screen else END_SCREEN_JUMP_HEIGHT) + ((cos(hover_frame / 35.0) - 1) * 0.35))
		hover_frame += 1
	else:
		hover_frame = 0
	
	if (falling and not idling):
		var frame_const = (1.0 / 60.0)
		var delta_weight = (delta / frame_const)
		
		phantom_pos += (0.175 * delta_weight)
		phantom_pos = clamp(phantom_pos, 0.0, 10.0)
	
		var this_x = _ease_expo_in(phantom_pos / 10.0)
		position.x = lerp(position.x, 0.0, this_x)
		position.y = lerp(position.y, 0.0, this_x)
		if (phantom_pos >= 10.0 and stopping_float):
			$BumpSFX.play()
			stopping_float = false
			if ($AnimationPlayer.current_animation == ("FloatStart_2" if not end_screen else "FloatStart_EndScreen")):
				await $AnimationPlayer.animation_finished
			idling = true
			$AnimationPlayer.speed_scale = (1.5 / 3.0)
			$AnimationPlayer.play("Idle", BLEND_TIME)
			falling = false
			position = Vector3.ZERO
			landed.emit()
			ad_timer.paused = false
	
	Screen.get_node("Timer").value = (ad_timer.time_left / ad_timer.wait_time) * 100

func init_timer():
	_load_ads()

var proc_ind = 0
func start_floating():
	proc_ind += 1
	var this_ind = proc_ind
	
	position = Vector3.ZERO
	awaiting_jump = true
	idling = false
	hovering = false
	stop_fucking_hovering = false
	falling = false
	
	$AnimationPlayer.speed_scale = (2.0 / 3.0)
	$AnimationPlayer.play(("FloatStart_2" if not end_screen else "FloatStart_EndScreen"), BLEND_TIME)
	ad_timer.paused = true
	#get_tree().create_timer(0.5333 * $AnimationPlayer.speed_scale).timeout.connect(jump)
	await $AnimationPlayer.animation_finished
	#print("%s == %s" % [this_ind, proc_ind])
	if (this_ind == proc_ind):
		pass
		#print("okay?...")

func jump():
	dest_value = (JUMP_HEIGHT if not end_screen else END_SCREEN_JUMP_HEIGHT)
	value = (JUMP_HEIGHT if not end_screen else END_SCREEN_JUMP_HEIGHT)
	jumping = true

var FallingTween: Tween
var phantom_pos = 0.0
func stop_floating():
	proc_ind += 1
	var this_ind = proc_ind
	if (not falling):
		stop_fucking_hovering = true
		falling = true
		$AnimationPlayer.speed_scale = (2.0 / 3.0)
		get_tree().create_timer(((1.0 / 60.0) * 20.0) * $AnimationPlayer.speed_scale).timeout.connect(func(): $FallSFX.play())
		$AnimationPlayer.play_backwards(("FloatStart_2" if not end_screen else "FloatStart_EndScreen"), BLEND_TIME)
		
		phantom_pos = 0.0
		
		#if (FallingTween): FallingTween.kill()
		#FallingTween = create_tween()
		#
		#FallingTween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
		#
		#FallingTween.set_parallel()
		#FallingTween.set_trans(Tween.TRANS_EXPO)
		#FallingTween.set_ease(Tween.EASE_IN)
		#
		#FallingTween.tween_property(self, "position:x", 0.0, 0.75)
		#FallingTween.tween_property(self, "position:y", 0.0, 0.75)
		#
		#FallingTween.play()
		#
		#FallingTween.finished.connect(func(): $BumpSFX.play())
		#FallingTween.finished.connect(func(): position = Vector3.ZERO)
		
		hovering = false
		awaiting_jump = false
		
		stopping_float = true
		#await $AnimationPlayer.animation_finished
		##print("%s == %s" % [this_ind, proc_ind])
		#if (this_ind == proc_ind):
			#idling = true
			#$AnimationPlayer.speed_scale = (1.5 / 3.0)
			#$AnimationPlayer.play("Idle", BLEND_TIME)
			#falling = false
			#position = Vector3.ZERO
			#landed.emit()
			#ad_timer.paused = false
			#stopping_float = false

func change_expression(expression):
	var face_name = "neutral"
	
	match expression:
		"SHOCK":
			face_name = "shock"
		"MONEY":
			face_name = "money"
		"MAD":
			face_name = "angry"
		"STINGY":
			face_name = "angry"
		"HAPPY":
			face_name = "happy"
		"THANK":
			face_name = "happy"
		"CONFUSED":
			face_name = "dizzy"
		"QUESTIONING":
			face_name = "question"
		"THREAT":
			face_name = "squint"
		"EYEROLL":
			face_name = "eyeroll"
	
	Screen.get_node("Face").texture = load("res://textures/blubot-%s.png" % face_name)

func _load_ads():
	for ad_key in ADS.keys():
		var ad = ADS[ad_key]
		var path = ad.path
		var not_real = true
		
		var err = ResourceLoader.load_threaded_request(path)
		if (err == OK):
			var loaded = false
			var failed = false
			while (not loaded):
				var progress = []
				var status = ResourceLoader.load_threaded_get_status(path, progress)
				
				match status:
					(ResourceLoader.THREAD_LOAD_LOADED):
						print("> LOADED %s" % ad_key)
						loaded = true
						not_real = false
					(ResourceLoader.THREAD_LOAD_FAILED or ResourceLoader.THREAD_LOAD_INVALID_RESOURCE):
						failed = true
						loaded = true
					(ResourceLoader.THREAD_LOAD_IN_PROGRESS):
						await get_tree().process_frame
			
			ADS[ad_key]["packed"] = ResourceLoader.load_threaded_get(path)
		
		if (not_real):
			ADS.erase(ad_key)
			AD_ORDER.erase(ad_key)
	
	AD_ORDER = AD_ORDER.filter(_filter_ad)
	
	AD_ORDER.shuffle()
	_ad_timer_timeout()

func _filter_ad(ad_key):
	var ad = ADS[ad_key]
	var ad_include = false
	
	if (ad.users.has(INF)): ad_include = true
	else:
		for user in ad.users:
			if (active_chatters.has(user)):
				ad_include = true
	
	if (ad.disabled): ad_include = false
	
	return ad_include

func _ad_timer_timeout():
	current_ad_num += 1
	current_ad_index = wrap(current_ad_num, 0, AD_ORDER.size())
	var current_ad_label = AD_ORDER[current_ad_index]
	var current_ad = ADS[current_ad_label]
	current_ad_packed = current_ad.packed
	
	_load_current_ad()
	ad_timer.wait_time = current_ad.length
	ad_timer.start(current_ad.length)
	
	_ad_label_hide()
	ad_label_timer.wait_time = (current_ad.length / 2.0)
	ad_label_timer.start(current_ad.length / 2.0)
	
	await Screen.get_node("AnimationPlayer").animation_finished
	
	Screen.get_node("WholeLabel/Label").text = ">" + current_ad_label

func _load_current_ad():
	
	var current_ad_label = AD_ORDER[current_ad_index]
	var current_ad = ADS[current_ad_label]
	var ad_node = current_ad_packed.instantiate()
	
	
	var old_ad = Screen.get_node_or_null("AD")
	if (old_ad != null):
		old_ad.name = "old_AD"
		old_ad.add_to_group("OLD_AD")
	ad_node.name = "AD"
	old_ad.add_sibling(ad_node)
	
	#print(current_ad.transition)
	await get_tree().create_timer(current_ad.transition).timeout
	
	for this_old_ad in get_tree().get_nodes_in_group("OLD_AD"):
		this_old_ad.queue_free()

func _ad_label_hide():
	Screen.get_node("AnimationPlayer").play("HIDE")

func _ad_label_show():
	Screen.get_node("AnimationPlayer").play("SHOW")

func _current_ad_request( REQUEST_IND ):
	var ad_id = AD_ORDER[current_ad_index]
	var ad = ADS[ad_id]
	
	Socket.send_ad_response(REQUEST_IND, {
		"id": ad_id,
		"desc": ad.desc
	})

func _ad_request( REQUEST_IND, AD_ID ):
	if (ADS.keys().has(AD_ID)):
		var ad = ADS[AD_ID]
		
		Socket.send_ad_response(REQUEST_IND, {
			"id": AD_ID,
			"desc": ad.desc
		})
	else:
		Socket.send_ad_response(REQUEST_IND, {
			"error": true,
			"desc": "Invalid Ad ID!",
		})

func _active_chat(chatters):
	for chatter in chatters:
		if (not active_chatters.has(chatter)):
			active_chatters.append(chatter)
			
			var chatter_ads = ADS.values().filter(func(ad): return (ad.has("users") and ad.users.has(chatter)))
			
			for ad in chatter_ads:
				var ad_idx = ADS.values().find(ad)
				var ad_key = ADS.keys()[ad_idx]
				print("> INSERTING %s" % ad_key)
				if (not AD_ORDER.has(ad_key)):
					AD_ORDER.insert(randi_range(current_ad_index+1, AD_ORDER.size()-1), ad_key)


# --------------------------------------------------------------- #

func _end_screen_start(payload):
	if (end_screen): return
	end_screen = true
	# holy shit...
	start_floating()
	EndScreen.start(payload)

func _end_screen_end():
	end_screen = false
