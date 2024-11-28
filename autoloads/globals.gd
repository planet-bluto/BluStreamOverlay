extends Node

signal next_slide_please

const WS_SERVER = "ws://localhost:5484"
const END_SCREEN_TRANSITION_RATE = 1

var cmd_arguments = {}
@export var SPARK_LOOP_COUNT = 5
var current_screen_idx = 0

func _ready():
	for argument in OS.get_cmdline_args():
		if argument.find("=") > -1:
			var bits = Array(argument.split("="))
			var key = bits.pop_front()
			var value = "=".join(PackedStringArray(bits))
			cmd_arguments[key.lstrip("--")] = value
		else:
			# Options without an argument will be present in the dictionary,
			# with the value set to an empty string.
			cmd_arguments[argument.lstrip("--")] = ""
	
	var output_devices = AudioServer.get_output_device_list()
	
	for output_device: String in output_devices:
		if (output_device.contains("Everything")):
			AudioServer.output_device = output_device


func _process(delta):
	if (not cmd_arguments.has("bluf")): return
	#if (get_window().mode != Window.MODE_FULLSCREEN): get_window().mode = Window.MODE_FULLSCREEN
	#for idx in DisplayServer.get_screen_count():
		#var resolution = DisplayServer.screen_get_size(idx)
		#if (resolution == Vector2i(1920, 1080)):
			#current_screen_idx = idx
			#break
	#
	#DisplayServer.window_set_current_screen(current_screen_idx, get_window().get_window_id())
	if (Input.is_action_just_pressed("next_slide_please")):
		next_slide_please.emit()

func LinkedVector3(num):
	return Vector3(num, num, num)
