extends Control

#-------------------------------------------------#

@onready var Scroller = $ScrollContainer
@onready var LabelContainer = $ScrollContainer/MarginContainer
@onready var LABEL = $ScrollContainer/MarginContainer/Label

#-------------------------------------------------#

var scroll_cooldown = false
var scroll_speed = 1
var scroll_dir = 1

#-------------------------------------------------#

func _reinit():
	_reset()
	scroll_dir = 1
	Scroller.scroll_horizontal = 0
	#scroll_target = (LabelContainer.size.x - Scroller.size.x)

func _reset():
	scroll_cooldown = true
	await get_tree().create_timer(3.0).timeout
	scroll_cooldown = false

func _process(delta):
	var frame_const = (1.0 / 60.0)
	var delta_weight = (delta / frame_const)
	var scroll_length = (LabelContainer.size.x - Scroller.size.x)
	
	if (not scroll_cooldown):
		Scroller.scroll_horizontal += ((scroll_speed * delta_weight) * scroll_dir)
		#
		#var h_scroll_bar: HScrollBar = Scroller.get_h_scroll_bar()
		if (scroll_dir == -1 and (Scroller.scroll_horizontal == 0)) or (scroll_dir == 1 and (abs(float(Scroller.scroll_horizontal) - float(scroll_length)) == 0)):
			_reset()
			scroll_dir *= -1
