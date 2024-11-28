extends Control

#-------------------------------------------------#

const MAX_ELEM_COUNT = 30
const NO_REPEAT_COUNT = 40

const FLAVOR_TEXT = [
	"DOWNLOADING EMOTES...",
	"WAKING UP SPARKS...",
	"PISSING OFF BLUBOT...",
	"MAKING ICE CREAM...",
	"CRASHING ENTIRE STREAM...",
	"TESTING INTERGALACTIC CONNECTION...",
	"ROUNDING UP SPARKS...",
	"LOOKING AT SANDWICH...",
	"TRACKING ACTIVITY FOR BLUBOT AWARDS...",
	"GASLIGHTING THE VIEWERS...",
	"BREACHING STARFIELDS...",
	"FEEDING SPARKS...",
	"COUNTING STARS...",
	"DEBUGGING BACKEND...",
	"LOCATING EARTH GALACTIC ENDPOINT...",
	"YOINKING THE SPLOINKY...",
	"INFORMING THE MASSES...",
	"INVADING YOUR PLANET...",
	"PAINTING EVERYTHING BLUE...",
	"CRAFTING RANDOM BULLSHIT...",
	"ORBITING MILKEY WAY...",
	"LAUNCHING BLUBOT INTO ORBIT...",
	"BLASTING COMMUNICATION SIGNALS...",
	"DEVELOPING MY GAME...",
	"GAMING MY DEVELOPMENT...",
	"HORSING AROUND...",
	"SCREAMING VERY LOUDLY...",
	"CONFIGURING LIVE STREAM...",
	"TUNING SONAR PINGS...",
	"UNBOXING NULL DWARFS...",
	"SCREAMING AT EVERYONE...",
	"ADJUSTING BLUE LIGHTS...",
	"CODING A SOLUTION TO ALL MY PROBLEMS...",
	"FOLLOW @ProjectHTTP FOLLOW @ProjectHTTP FOLLOW @ProjectHTTP FOLLOW @ProjectHTTP FOLLOW @ProjectHTTP",
	"FOLLOWING @PLANETBLUTONIUM ON TWITTER...",
	"FOLLOWING PLANET_BLUTO ON SOUNDCLOUD...",
	"FOLLOWING PLANETBLUTO ON YOUTUBE...",
	"FOLLOWING BLUTONIUM ON NEWGROUNDS...",
	"FOLLOWING PLANET-BLUTO ON ITCH.IO...",
	"CHECKING OUT HTTPS://PLANET-BLUTO.NET/...",
	"FINDING WHO ASKED...",
	"JOINING THE PLANET BLUTO !DISCORD...",
	"WONDERING WHAT BLUBOT'S !BUMPER IS...",
]

#-------------------------------------------------#

const dialog_line_prefab = preload("res://prefabs/dialog_line.tscn")

#-------------------------------------------------#

var chat_queue = []
var size_cache = {}

func _ready():
	get_window().title = "[SRC] Starting Soon"
	
	Socket.chat.connect(_chat)
	#start()

var recents = []
func start():
	while visible:
		#prev_size = $ScrollContainer/VBoxContainer.size.y
		var elem_count = $ScrollContainer/VBoxContainer.get_child_count()
		if (elem_count > MAX_ELEM_COUNT):
			var to_remove = $ScrollContainer/VBoxContainer.get_child(elem_count-2)
			prev_size -= size_cache[to_remove]
			to_remove.queue_free()
		
		if (chat_queue.size() > 0):
			await add_dialog_line.callv(chat_queue.pop_front())
		else:
			if (recents.size() > NO_REPEAT_COUNT): recents.pop_front()
			var this_flavor = FLAVOR_TEXT.pick_random()
			while (recents.has(this_flavor)): this_flavor = FLAVOR_TEXT.pick_random()
			recents.append(this_flavor)
			await add_dialog_line(this_flavor, Color("#8CD612"), false)
		await get_tree().create_timer(0.25).timeout

var frame = 0
var prev_visible = visible
func _process(delta):
	$HeaderLabel.text = ">STARTING_SOON" + ".".repeat(wrap(round(frame/50.0), 0, 4))
	frame += 1
	
	if (visible != prev_visible):
		prev_visible = visible
		if (visible): start()

@onready var prev_size = $ScrollContainer/VBoxContainer.size.y
var DialogBoxScrollTween: Tween
func add_dialog_line(line, color: Color = Color.WHITE, sfx = true):
	if (typeof(line) == TYPE_STRING): line = Array(line.split(""))
	
	var prev_lines = get_tree().get_nodes_in_group("dialog_line")
	for prev_line in prev_lines:
		prev_line.modulate = Color("#ffffff7c")
	
	var dialog_line: RichTextLabel = dialog_line_prefab.instantiate()
	#dialog_line.label_settings = dialog_line.label_settings.duplicate(true)
	dialog_line.add_theme_color_override("default_color", color)
	dialog_line.text = ""
	$ScrollContainer/VBoxContainer/HSeparator.add_sibling(dialog_line)
	
	var scroll_to = null
	var prev_scroll_to = scroll_to
	
	var curr_size = $ScrollContainer/VBoxContainer.size.y
	var diff = abs(curr_size - prev_size)
	prev_size = curr_size
	scroll_to = float(diff)
	$ScrollContainer.scroll_vertical = scroll_to
	size_cache[dialog_line] = diff
	
	var cursor = 0
	while (cursor < line.size()):
		var char = line[cursor]
		cursor += 1
		dialog_line.text += char
		if (sfx): dialog_line.get_node("AudioStreamPlayer").play()
		
		await get_tree().create_timer((2.0 / 60.0)).timeout
		if (sfx):
			if ([".", "!", "?"].has(char)):
				await get_tree().create_timer(0.35).timeout
			if ([",", "-"].has(char)):
				await get_tree().create_timer(0.1).timeout
		
		if (prev_scroll_to != scroll_to):
			prev_scroll_to = scroll_to
			if (scroll_to > 0):
				if (DialogBoxScrollTween): DialogBoxScrollTween.kill()
				DialogBoxScrollTween = create_tween()
				
				DialogBoxScrollTween.set_parallel()
				DialogBoxScrollTween.set_trans(Tween.TRANS_CUBIC)
				DialogBoxScrollTween.set_ease(Tween.EASE_OUT)
				
				DialogBoxScrollTween.tween_property($ScrollContainer, "scroll_vertical", 0.0, (0.5 * (float(dialog_line.size.y) / 40.0)))
				
				DialogBoxScrollTween.play()

func _chat(author, text, platform, author_style, flags, icons):
	if (visible):
		chat_queue.append([
			"%s: %s" % [author, text],
			Color("#ffe737"),
			false
		])
