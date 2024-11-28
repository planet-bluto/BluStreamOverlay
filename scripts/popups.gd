extends Control

const popup_prefab = preload("res://prefabs/popup.tscn")

const PopupTypes = {
	"video": preload("res://prefabs/popup_video.tscn"),
	"image": preload("res://prefabs/popup_image.tscn")
}

const SPARK_COLORS = {
	"BOLTA": [Color("0a89ff"), Color("024aca")],
	"MALO": [Color("e03c28"), Color("871646")],
	"CODEC": [Color("8cd612"), Color("6ab417")],
	"MUSE": [Color("ffe737"), Color("ffbb31")],
	"VISU": [Color("9ba0ef"), Color("6264dc")],
}

func _ready():
	Socket.popup.connect(_spawn_popup)
	Socket.get_popups.connect(_get_popups)
	
	var img = TextureRect.new()
	img.texture = preload("res://textures/ads/DORORO.png")
	
	get_window().mode = Window.MODE_FULLSCREEN
	get_window().title = '[SRC] Popups'
	DisplayServer.window_set_current_screen(0, get_window().get_window_id())
	
	popup(">EVIL_DORORO", img, {"title_color": Color("#e03c28"), "icon": preload("res://textures/ads/DORORO.png")})
	popup(">GOOD_DORORO", img.duplicate(), {"title_color": Color("#6ab417"), "icon": preload("res://textures/ads/DORORO.png")})
	
	#var little_guy_count = 5
	#for little_guy in (little_guy_count - 1):
		#var new_little_guy = $LittleGuy.duplicate()
		#var texture_rect: TextureRect = new_little_guy.get_node("TextureRect")
		#texture_rect.material = texture_rect.material.duplicate(true)
		#
		#var spark_color = SPARK_COLORS.values()[randi_range(0, SPARK_COLORS.size()-1)]
		#texture_rect.material.set_shader_parameter("swatch_base", spark_color[0])
		#texture_rect.material.set_shader_parameter("swatch_shade", spark_color[1])
		#
		#add_child(new_little_guy)

#func popup(title: String, title_color: Color, icon: Texture, contents: Control, popup_size: Vector2 = Vector2(240, 135)):

enum PopupPositions {
	CENTER,
	RANDOM
}

const MAKE_POPUP_DEFAULTS = {
	"title_color": Color("#024aca"),
	"icon": preload("res://textures/window_icons/sandwich.png"),
	"size": Vector2(1024, (9.0 / 16.0) * 1024),
	"position": PopupPositions.CENTER
}

func popup(title: String, contents: Control, options: Dictionary = {}):
	options = options.duplicate(true)
	options.merge(MAKE_POPUP_DEFAULTS)
	
	var popup_inst: Control = popup_prefab.instantiate()
	
	#popup_inst.mode = Window.MODE_WINDOWED
	#popup_inst.request_attention()
	
	#popup_inst.title = title
	popup_inst.get_node("Control/Title").text = title
	popup_inst.get_node("Control/Title").label_settings.font_color = options.title_color
	
	
	popup_inst.get_node("Control/Icon").texture = options.icon
	
	var current_contents = popup_inst.get_node("Control/Contents")
	
	for child in current_contents.get_children(): child.queue_free()
	
	contents.set_anchors_preset(PRESET_FULL_RECT)
	
	current_contents.add_child(contents)
	
	popup_inst.target_size = options.size.round()
	
	match (options.position):
		PopupPositions.RANDOM:
			popup_inst.target_pos.x = randi_range(0, 1920 - popup_inst.target_size.x )
			popup_inst.target_pos.y = randi_range(0, 1080 - popup_inst.target_size.y )
		PopupPositions.CENTER:
			popup_inst.target_pos.x = (1920.0 / 2.0) - (popup_inst.target_size.x / 2.0)
			popup_inst.target_pos.y = (1080.0 / 2.0) - (popup_inst.target_size.y / 2.0)
	
	print(popup_inst)
	add_child(popup_inst)

func aspector(resolution, max_dimension):
	if (resolution.y >= resolution.x):
		var ratio = (resolution.y / float(max_dimension))
		return Vector2((resolution.x / ratio), float(max_dimension))
	else:
		var ratio = (resolution.x / float(max_dimension))
		return Vector2(float(max_dimension), (resolution.y / ratio))

func _process(_delta):
	if (Input.is_action_just_pressed("spawn_popup")):
		_spawn_popup()
	if (Input.is_action_just_pressed("paste_popup")):
		var clipboard_img: Image = DisplayServer.clipboard_get_image()
		
		if (clipboard_img != null):
			var img = TextureRect.new()
			img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		
			var img_text = ImageTexture.create_from_image(clipboard_img)
			img.texture = img_text
		
			popup("Clipboard", img, {
				"position": PopupPositions.CENTER,
				"size": aspector(clipboard_img.get_size(), 640)
			})
	if (Input.is_action_just_pressed("close_all_popups")):
		var POPUPS = get_tree().get_nodes_in_group("POPUP")
		
		for popup in POPUPS:
			popup._close_button()

const POPUP_DEFAULTS = {
	"color": Color("#024aca"),
	"icon": preload("res://textures/window_icons/sandwich.png"),
}

const Popups = {
	"accident": {
		"title": "accident...",
		"type": "video",
		"stream": preload("res://popups/accident.ogv"),
	},
	"aw_man": {
		"title": "AW MAN",
		"type": "video",
		"stream": preload("res://popups/aw man.ogv"),
	},
	"the_first_night": {
		"title": "The First Night...",
		"type": "video",
		"stream": preload("res://popups/fnafs.ogv"),
	},
	"rabbit_footage": {
		"title": "Rabbit Footage",
		"type": "video",
		"stream": preload("res://popups/rabbit footage.ogv"),
	},
	"scallywag": {
		"title": "The Scallywag",
		"type": "video",
		"stream": preload("res://popups/scallywag.ogv"),
	},
	"the_game": {
		"title": "The Game",
		"type": "video",
		"stream": preload("res://popups/the game.ogv"),
	},
	"tort": {
		"title": "Tort",
		"type": "video",
		"stream": preload("res://popups/tort.ogv"),
	},
	"spong": {
		"title": "spong.",
		"type": "video",
		"stream": preload("res://popups/video0-9-2-1.ogv"),
	},
	"wow_bro": {
		"title": "Wow Bro",
		"type": "video",
		"stream": preload("res://popups/videoplayback_14.ogv"),
	},
	"watching": {
		"title": "Watching...",
		"type": "video",
		"stream": preload("res://popups/watching.ogv"),
	},
	"the_fish": {
		"title": "The Fish",
		"type": "video",
		"stream": preload("res://popups/wrong species.ogv"),
	},
	"stop_fighting": {
		"title": "STOP FIGHTING!!!",
		"type": "image",
		"image": preload("res://popups/WAAIT.png"),
		"stream": preload("res://popups/cat_scream.mp3"),
	},
	"super_idol": {
		"title": "supa idol",
		"type": "video",
		"stream": preload("res://popups/s1nSwV_0IEs94gJA.ogv"),
	},
	"hard": {
		"title": "HARD.",
		"type": "video",
		"stream": preload("res://popups/hard.ogv"),
	},
	"unfortunate_news": {
		"title": "SOME UNFORTUNATE NEWS 😭",
		"type": "video",
		"stream": preload("res://popups/i.ogv"),
	},
	"atlas_earth": {
		"title": "ATLAS EARTH",
		"type": "video",
		"stream": preload("res://popups/metaverse.ogv"),
	},
	"forces_and_motion": {
		"title": "Forces & Motion",
		"type": "video",
		"stream": preload("res://popups/Forces & Motion.ogv"),
	},
	"oh_my_god": {
		"title": "OH MY GOD 🗿",
		"type": "video",
		"stream": preload("res://popups/oh my god.ogv"),
	},
	"food_paradox": {
		"title": "FOOD PARADOX",
		"type": "video",
		"stream": preload("res://popups/food paradox.ogv"),
	},
	"idk_what_to_call_this_one": {
		"title": "idk what this is, it's cool tho",
		"type": "video",
		"stream": preload("res://popups/thas my shit.ogv"),
	},
	"bad_apple": {
		"title": "Bad Apple",
		"type": "video",
		"stream": preload("res://popups/bad_apple.ogv"),
	},
}

func _get_popups(req_id):
	var to_return = Popups.duplicate(true)
	
	for key in to_return.keys():
		to_return[key].id = key
	
	Socket.send_popup_response(req_id, to_return)

const MAX_POPUP_SIZE = 640

func _spawn_popup(req_id = null, popup_id = null):
	#print(popup_id)
	if (popup_id == null):
		popup_id = Popups.keys().pick_random()
	
	if (not Popups.has(popup_id)): return
	
	var popup_info: Dictionary = Popups[popup_id].duplicate(true)
	popup_info.merge(POPUP_DEFAULTS)
	
	var inst = PopupTypes[popup_info.type].instantiate()
	
	var popup_size = Vector2(240, 135)
	var inst_size
	
	match (popup_info.type):
		"video":
			var this_inst: VideoStreamPlayer = inst
			this_inst.stream = popup_info.stream
			
			inst_size = this_inst.get_video_texture().get_size()
		"image":
			var this_inst: TextureRect = inst
			this_inst.texture = popup_info.image
			inst_size = Vector2(popup_info.image.get_size())
			
			if (popup_info.has("stream")):
				var this_sound_player: AudioStreamPlayer = AudioStreamPlayer.new()
				this_sound_player.stream = popup_info.stream
				this_sound_player.autoplay = true
				this_sound_player.bus = "popups"
				this_inst.add_child(this_sound_player)
		
	print(inst_size)
	popup_size = aspector(inst_size, MAX_POPUP_SIZE)
		
		
	popup(popup_info.title, inst, {
		"title_color": popup_info.color,
		"icon": popup_info.icon,
		"size": popup_size,
		"position": PopupPositions.RANDOM
	})
	
	if (req_id != null): Socket.send_popup_response(req_id, popup_id)
