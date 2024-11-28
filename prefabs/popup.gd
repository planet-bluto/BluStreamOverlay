extends Control

var target_pos = Vector2(position)
var float_position = Vector2(position)
var target_size = Vector2(size)
var float_size = Vector2(size)

var minimized = false

func _ready():
	$Control/MoveButton.button_down.connect(_move_init)
	$Control/MoveButton.button_up.connect(_move_end)
	
	$Control/ScaleButton.button_down.connect(_scale_init)
	$Control/ScaleButton.button_up.connect(_scale_end)
	
	$Control/Buttons/CloseButton.pressed.connect(_close_button)
	$Control/Buttons/MinimizeButton.pressed.connect(_min_button)
	
	focus_entered.connect(_got_focus)
	for child in find_children("*", "", true, false):
		if (child is Control):
			child.focus_entered.connect(_got_focus)

var mouse_init_pos: Vector2i

var move_init_pos: Vector2i
var moving = false
func _move_init():
	move_init_pos = position
	mouse_init_pos = DisplayServer.mouse_get_position()
	moving = true

func _move_end():
	moving = false

var scale_init_pos: Vector2i
var scaling = false
func _scale_init():
	scale_init_pos = size
	mouse_init_pos = DisplayServer.mouse_get_position()
	scaling = true

func _scale_end():
	print("STOP IT")
	scaling = false

func _process(delta):
	var current_mouse_pos = DisplayServer.mouse_get_position()
	
	if (moving):
		var move_amount = (mouse_init_pos - current_mouse_pos)
		target_pos = Vector2(move_init_pos - move_amount)
	
	float_position = float_position.lerp(target_pos, 0.5)
	position = Vector2i(float_position.round())
	
	if (scaling):
		var scale_amount = (mouse_init_pos - current_mouse_pos)
		target_size = Vector2(scale_init_pos - scale_amount)
		print(target_size)
	
	float_size = float_size.lerp(target_size, 0.5)
	size = Vector2i(float_size.round())

func _close_button():
	print("close pls...")
	queue_free()

var _pre_min_size: Vector2i
var _pre_min_pos: Vector2i
func _min_button():
	_pre_min_size = size
	_pre_min_pos = position
	
	position = Vector2i.ZERO
	size = Vector2i.ZERO
	minimized = true

func _got_focus():
	print("pingas")
	#z_index = 1000
	var parent = get_parent()
	parent.move_child(self, parent.get_child_count()-1)
	#if (minimized):
		#minimized = false
		#
		#size = _pre_min_size
		#position = _pre_min_pos
