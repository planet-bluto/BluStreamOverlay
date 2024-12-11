extends Control

#-------------------------------------------------#

const dialog_line_prefab = preload("res://prefabs/dialog_line.tscn")
const spark_notif_prefab = preload("res://prefabs/spark_notif.tscn")

#-------------------------------------------------#

@onready var BluBot = $BluBotWindow/BluBotView/SubViewport/BluBot

#-------------------------------------------------#

var current_voice = null
var last_ind = -1
var expressions = []

#-------------------------------------------------#

var parsing = false
var queued_payloads = []

#-------------------------------------------------#

func _ready():
	var windows = [
		$BluWindow,
		$BluBotWindow,
		$SparkNotifWindow,
	]
	
	for window in windows:
		DisplayServer.window_set_current_screen(Globals.current_screen_idx, window.get_window_id())
	
	get_window().title = "Stream Manager"
	
	Socket.blubot_sentences.connect(check_sentences)
	Socket.spark_event.connect(_spark_event)
	
	var voices = DisplayServer.tts_get_voices()
	print(voices)
	current_voice = voices[0].name
	
	$VBoxContainer/PromptButton.pressed.connect(_req_event.bind("prompt"))
	$VBoxContainer/SubButton.pressed.connect(_req_event.bind("sub"))
	$VBoxContainer/GiftSubButton.pressed.connect(_req_event.bind("giftsub"))
	$VBoxContainer/RaidButton.pressed.connect(_req_event.bind("raid"))
	$VBoxContainer/BitButton.pressed.connect(_req_event.bind("bit"))
	$VBoxContainer/HypeTrainButton.pressed.connect(_req_event.bind("hypetrain"))
	$VBoxContainer/ShoutoutButton.pressed.connect(_req_event.bind("shoutout"))
	
	DisplayServer.tts_set_utterance_callback(DisplayServer.TTS_UTTERANCE_STARTED, _start_speaking)
	DisplayServer.tts_set_utterance_callback(DisplayServer.TTS_UTTERANCE_ENDED, _done_speaking)
	
	await BluBot.start_floating()
	await BluBot.stop_floating()
	BluBot.init_timer()

func _req_event(type):
	var user = $VBoxContainer/UserEdit.text
	var content = $VBoxContainer/ContentEdit.text
	var number = $VBoxContainer/SpinBox.value
	
	Socket.send_debug({"user": user, "content": content, "type": type, "number": number})

var blu_float_frame = 0
func _process(delta):
	pass

func check_sentences(payload):
	if (not parsing):
		parsing = true
		if (BluBot.falling):
			await BluBot.landed
		await BluBot.start_floating()
		Socket.send("blubot_speak_start", [])
		queue_sentences(payload)
	else:
		queued_payloads.append(payload)

func queue_sentences(payload):
	var sentences = payload.sentences
	
	last_ind = sentences.size()-1
	expressions.clear()
	
	if (payload.has("replying")):
		var bits = []
		for elem in payload.replyingBits:
			match elem.type:
				"text":
					bits.append_array(elem.text.split(""))
				"startTag":
					if (elem.tag.value == null):
						bits.append("[%s]" % elem.tag.name)
					else:
						bits.append("[%s=%s]" % [elem.tag.name, elem.tag.value])
				"endTag":
					bits.append("[/%s]" % elem.tag.name)
		
		await add_dialog_line(bits, Color(payload.replyingColor))
		await get_tree().create_timer(1.0).timeout
	
	var texts = PackedStringArray([])
	for ind in sentences.size():
		var sentence = sentences[ind]
		expressions.append(sentence.mood)
		texts.append(sentence.content)
		speak(sentence.content, ind)
	
	var da_text = ["[color=#8CD612]"] + Array("[ / >] BLU_BOT".split("")) + ["[/color]"] + Array((": %s" % [" ".join(texts)]).split(""))
	
	add_dialog_line(da_text, Color("#BEEB71"), false)

func speak(message, ind = -1):
	DisplayServer.tts_speak(
		message,
		current_voice,
		100, # Volume
		0.1, # Pitch
		1.2, # Rate
		ind
	)

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
	$BluBotWindow/Control/ScrollContainer/VBoxContainer.add_child(dialog_line)
	
	var scroll_to = null
	var prev_scroll_to = scroll_to
	
	var cursor = 0
	while (cursor < line.size()):
		var char = line[cursor]
		cursor += 1
		dialog_line.text += char
		if (sfx): dialog_line.get_node("AudioStreamPlayer").play()
		
		await get_tree().process_frame
		await get_tree().process_frame
		if (sfx):
			if ([".", "!", "?"].has(char)):
				await get_tree().create_timer(0.35).timeout
			if ([",", "-"].has(char)):
				await get_tree().create_timer(0.1).timeout
		
		scroll_to = ($BluBotWindow/Control/ScrollContainer/VBoxContainer.size.y - $BluBotWindow/Control/ScrollContainer.size.y)
		
		if (prev_scroll_to != scroll_to):
			prev_scroll_to = scroll_to
			if (scroll_to > 0):
				if (DialogBoxScrollTween): DialogBoxScrollTween.kill()
				DialogBoxScrollTween = create_tween()
				
				DialogBoxScrollTween.set_parallel()
				DialogBoxScrollTween.set_trans(Tween.TRANS_CUBIC)
				DialogBoxScrollTween.set_ease(Tween.EASE_OUT)
				
				DialogBoxScrollTween.tween_property($BluBotWindow/Control/ScrollContainer, "scroll_vertical", scroll_to, (0.25 * (float(dialog_line.size.y) / 40.0)))
				
				DialogBoxScrollTween.play()
		
		#await get_tree().create_timer(0.01).timeout

func _start_speaking(id):
	var expression = expressions[id]
	BluBot.change_expression(expression)

func _done_speaking(id):
	if (id == last_ind):
		if (queued_payloads.size() > 0):
			var payload = queued_payloads.pop_front()
			queue_sentences(payload)
		else:
			BluBot.stop_floating()
			Socket.send("blubot_speak_end", [])
			await get_tree().process_frame
			parsing = false

#-------------------------------------------------#

func _spark_notif(text, color):
	var spark_notif_cont = Control.new()
	var spark_notif_inst = spark_notif_prefab.instantiate()
	
	spark_notif_inst.modulate = color
	spark_notif_inst.text = text
	
	spark_notif_cont.position.x = randi_range(-300, 300)
	
	spark_notif_cont.add_child(spark_notif_inst)
	$SparkNotifWindow/SparkNotifs.add_child(spark_notif_cont)

var importants = {}

func _spark_event(type, spark, timestamp, extras):
	match type:
		"null":
			var formatting_as_freak = [
				spark.user.displayName
			]
			
			var text = ("\n[center][img=90]res://textures/null_dwarf.png[/img]%s:  - Nulled Spark..[img=90]res://textures/null_dwarf.png[/img][/center]" % formatting_as_freak)
			
			_spark_notif(text, Color("#353535"))
		"birth":
			var formatting_as_freak = [
				spark.user.displayName
			]
			
			var text = ("\n[center][img=90]res://textures/charge_icon.png[/img]%s:  + New Spark![img=90]res://textures/charge_icon.png[/img][/center]" % formatting_as_freak)
			
			_spark_notif(text, Color("#98DCFF"))
			importants[timestamp] = "birth"
		"charge":
			if (importants.has(timestamp)): return
			
			var formatting_as_freak = [
				spark.user.displayName,
				extras[0].amount,
				extras[0].type
			]
			
			var text = ("\n[center][img=90]res://textures/charge_icon.png[/img]%s:  +%s %s charge[img=90]res://textures/charge_icon.png[/img][/center]" % formatting_as_freak)
			
			_spark_notif(text, Color(extras[0].color))
		"evolve":
			var formatting_as_freak = [
				spark.user.displayName,
				spark.prominent_charge
			]
			
			var text = ("\n[center][img=90]res://textures/charge_icon.png[/img]%s:  +Evolved => New %s Spark![img=90]res://textures/charge_icon.png[/img][/center]" % formatting_as_freak)
			
			_spark_notif(text, Color(spark.color))
			importants[timestamp] = "evolve"
