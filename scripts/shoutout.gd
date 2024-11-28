extends Control

#-------------------------------------------------#

signal done_scrolling()

#-------------------------------------------------#

const thesolutiontoallmyproblems = preload("res://materials/shoutout.tres")
const element_prefab = preload("res://prefabs/shoutout_element.tscn")

#-------------------------------------------------#

const BASE_SCALE = 1.046

const BORDER_TEXTURES = {
	"straight": preload("res://textures/shoutout/border_straight.png"),
	"cloud": preload("res://textures/shoutout/border_cloud.png"),
	"saw": preload("res://textures/shoutout/border_saw.png"),
	"waves": preload("res://textures/shoutout/border_waves.png"),
	"spikes": preload("res://textures/shoutout/border_spikes.png"),
	"jaggy": preload("res://textures/shoutout/border_jaggy.png"),
}

#-------------------------------------------------#

@export var name_text = ">PLANET_BLUTO"
@export var name_color = Color("#024aca")
@export_enum("straight", "cloud", "saw", "waves", "spikes", "jaggy") var top_border_type = "cloud"
var prev_top_border_type = top_border_type
@export_enum("straight", "cloud", "saw", "waves", "spikes", "jaggy") var bottom_border_type = "cloud"
var prev_bottom_border_type = bottom_border_type
@export var top_border_color = Color("#252525")
@export var bottom_border_color = Color("#252525")
@export var top_border_scale = 1.0
@export var bottom_border_scale = 1.0
@export var top_border_speed = 0.25
@export var bottom_border_speed = 0.25
@export var background_color = Color("#151515")
@export var element_outline_color = Color("#050505")

var current_element_name = ""
var friend_cache = {}
var scrolling = false
var emitted_done_scrolling = false

#-------------------------------------------------#

func _ready():
	#get_tree().paused = true
	get_window().title = "[SRC] Shoutout"
	DisplayServer.window_set_current_screen(0, get_window().get_window_id())
	Socket.shoutout.connect(_new_shoutout)
	print(BORDER_TEXTURES)
	
	if (Globals.cmd_arguments.has("shoutout")):
		var friend = JSON.parse_string(Marshalls.base64_to_utf8(Globals.cmd_arguments["shoutout"]).uri_decode())
		#print(friend)
		_new_shoutout(friend)

func _new_shoutout(friend):
	#get_tree().paused = false
	scrolling = false
	emitted_done_scrolling = false
	$Pauser/ScrollContainer.scroll_horizontal = 0
	current_element_name = ""
	
	friend_cache = friend
	name_text = friend.formatted_name
	name_color = friend.style.name_color
	
	top_border_type = friend.style.border_type.to_lower()
	bottom_border_type = friend.style.border_type.to_lower()
	
	bottom_border_color = Color(friend.style.bottom_border_color)
	top_border_color = Color(friend.style.top_border_color)
	
	background_color = Color(friend.style.background_color)
	element_outline_color = Color(friend.style.element_outline_color)
	
	var artist_icon_res = await Fetch.request_image("https://planet-bluto.nekoweb.org/shoutout/%s/artist.%s" % [friend.id, ("gif" if friend.style.animated_icon else "png")])
	var image_text = artist_icon_res.texture
	$Pauser/Artist.texture = image_text
	$Pauser/Artist.material.set_shader_parameter("color", Color(friend.style.icon_outline_color))
	$Pauser/Artist.material.set_shader_parameter("width", (10.0 if (not friend.style.no_icon_outline) else 0.0))
	$Pauser/Artist2.texture = image_text
	$Pauser/Artist2.material.set_shader_parameter("color", Color(friend.style.icon_outline_color))
	$Pauser/Artist2.material.set_shader_parameter("width", (10.0 if (not friend.style.no_icon_outline) else 0.0))
	
	for child in get_tree().get_nodes_in_group("shoutout_element"):
		child.queue_free()
	
	var this_arts: Array = friend.art
	this_arts.reverse()
	
	for art_entry in this_arts:
		var element_inst = element_prefab.instantiate()
		element_inst.entry = art_entry
		
		$Pauser/ScrollContainer/HBoxContainer.add_child(element_inst)
		$Pauser/ScrollContainer/HBoxContainer.move_child(element_inst, 1)
		
		if (art_entry.media):
			var art_media_res = await Fetch.request_image(art_entry.media)
			element_inst.media_texture = art_media_res.texture
		
		if (art_entry.fields.has("Music")):
			element_inst.music_stream = load("res://shoutout_art/%s" % art_entry.filename)
		if (art_entry.fields.has("Video")):
			element_inst.video_stream = load("res://shoutout_art/%s" % art_entry.filename)
	
	Socket.send("shoutout_start", [friend_cache])
	start_scrolling()
	
	await done_scrolling
	await get_tree().create_timer(2.0, true, true).timeout
	
	for element in get_tree().get_nodes_in_group("shoutout_element"):
		element.trans_out(true)
	
	Socket.send("shoutout_end", [friend_cache])
	
	await get_tree().create_timer(2.0, true, true).timeout
	
	if (Globals.cmd_arguments.has("shoutout")): get_tree().quit()
	#get_tree().paused = true

func _process(delta):
	$Pauser/Label.text = ("\n [color=%s]%s[/color] [color=%s]%s[/color]" % [name_color, name_text, bottom_border_color.to_html(true), current_element_name])
	$Pauser/Label.add_theme_color_override("font_outline_color", Color(background_color))
	#$Pauser/Label.label_settings.font_color = name_color
	#$Pauser/Label.label_settings.outline_color = background_color
	
	for element_outline: TextureRect in get_tree().get_nodes_in_group("element_outline"):
		element_outline.modulate = element_outline_color
	
	$Pauser/"Top/Top Border".set_texture(BORDER_TEXTURES[top_border_type])
	$Pauser/"Bottom/Bottom Border".set_texture(BORDER_TEXTURES[bottom_border_type])
	
	$Pauser/"Top/Top Border".scale.x = BASE_SCALE * top_border_scale
	$Pauser/"Bottom/Bottom Border".scale.x = BASE_SCALE * bottom_border_scale
	
	$Pauser/"Top/Top Border".material.set_shader_parameter("scroll_speed", (top_border_speed / top_border_scale))
	$Pauser/"Bottom/Bottom Border".material.set_shader_parameter("scroll_speed", (bottom_border_speed / bottom_border_scale))
	
	$Pauser/"Top/Top Border".material.set_shader_parameter("border_color", top_border_color)
	$Pauser/"Top/Top Border Fix".color = top_border_color
	
	$Pauser/"Bottom/Bottom Border".material.set_shader_parameter("border_color", bottom_border_color)
	$Pauser/"Bottom/Bottom Border Fix".color = bottom_border_color
	
	$Pauser/Background.color = background_color
	$Pauser/Fade.modulate = background_color
	
	if (scrolling):
		$Pauser/ScrollContainer.scroll_horizontal += 5.0
		if ((not emitted_done_scrolling) and $Pauser/ScrollContainer.scroll_horizontal >= (($Pauser/ScrollContainer/HBoxContainer.size.x - $Pauser/ScrollContainer.size.x) - 2000.0)):
			emitted_done_scrolling = true
			done_scrolling.emit()

func _texture_change():
	pass

var ScrollTween: Tween
func start_scrolling():
	await get_tree().create_timer(3.0).timeout
	
	var children = $Pauser/ScrollContainer/HBoxContainer.get_children()
	for ind in $Pauser/ScrollContainer/HBoxContainer.get_child_count():
		var element = children[ind]
		var prev_element = children[ind-1]
		if (prev_element.is_in_group("shoutout_element")):
			if ((prev_element.entry.fields.has("Video") and not prev_element.entry.fields.has("AudioVideo")) or ((element.is_in_group("shoutout_element") and (element.entry.fields.has("Music") or element.entry.fields.has("AudioVideo"))))):
				prev_element.trans_out()
		if (not element.is_in_group("shoutout_element")): continue
		var next_element = children[ind+1]
		
		element.trans_in()
		current_element_name = ("- " + element.entry.name)
		
		var scroll_to = ((element.position.x-2028.0) + 1100.0)
		
		if (ScrollTween): ScrollTween.kill()
		ScrollTween = create_tween()
		
		#ScrollTween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
		
		ScrollTween.set_parallel()
		ScrollTween.set_trans(Tween.TRANS_CUBIC)
		ScrollTween.set_ease(Tween.EASE_OUT)
		
		ScrollTween.tween_property($Pauser/ScrollContainer, "scroll_horizontal", scroll_to, 0.75)
		
		ScrollTween.play()
		
		await ScrollTween.finished
		if (element.entry.fields.has("Music")):
			if (next_element.is_in_group("shoutout_element") and (not next_element.entry.fields.has("Music")) and (not next_element.entry.fields.has("AudioVideo"))):
				print("(Music) Waiting for 5 seconds...")
				await get_tree().create_timer(5.0, true, true).timeout
				print("(Music) Next...")
			else:
				print("Waiting for A MILLION YEARS...")
				await get_tree().create_timer(5.0, true, true).timeout
				#await element.music_done
		else:
			print("Waiting for 5 seconds like I'm going to set it right now...")
			await get_tree().create_timer(5.0, true, true).timeout
			print("Next...")
	
	print("Aaaaaand wrapping up...")
	
	scrolling = true
