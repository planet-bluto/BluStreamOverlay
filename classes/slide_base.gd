extends Control
class_name SlideBase

signal transition_start
signal transition_end
signal slide_done

enum Trans {
	IN, OUT
}

var payload: Dictionary = {}
var meta: Dictionary = {}
var current_trans = 0
var transitioning = false

func _ready():
	meta = payload.meta
	$Header/Label.text = payload.header
	#$Header/Icon.texture = 
	
	$AnimationPlayer.speed_scale = Globals.END_SCREEN_TRANSITION_RATE
	trans() # transition to 1... 0??....

func trans():
	if (transitioning): return
	
	$AnimationPlayer.play(str(current_trans)) #... wait I think this is literally the entire fucking function fuc-
	transitioning = true
	transition_start.emit()
	current_trans += 1
	
	await $AnimationPlayer.animation_finished
	transitioning = false
	transition_end.emit()
	
	var anim_size = ($AnimationPlayer.get_animation_list().size()-1)
	print("Anim Size: ", anim_size)
	print("Current: ", current_trans)
	if (current_trans >= anim_size):
		slide_done.emit()
		queue_free()
