extends Node3D

@export var sand_amount = 0.25
var virtual_sand_amount = sand_amount

const PALETTE_ACTIVE = [
	"ffe737",
	"ffba31",
	"f68f37",
]
const PALETTE_BREAK = [
	"0a89ff",
	"024aca",
	"00177d",
]
const PALETTE_LONG_BREAK = [
	"25e2cd",
	"0a98ac",
	"005280",
]
const PALETTE_INACTIVE = [
	"353535",
	"252525",
	"151515",
]

var target_palette = PALETTE_LONG_BREAK
var active_palette = [
	Color(target_palette[0]),
	Color(target_palette[1]),
	Color(target_palette[2])
]

func _ready():
	Socket.hourglass_start.connect(_hourglass_start)
	Socket.hourglass_pause.connect(_hourglass_pause)
	Socket.hourglass_end.connect(_hourglass_end)
	
	$MeshInstance.rotation_degrees.x = 10.0
	
	#await get_tree().create_timer(5.0).timeout
	#flip(PALETTE_BREAK)

var FlipTween: Tween
var flipping = false
func flip():
	flipping = true
	#$MeshInstance.scale.y *= -1
	sand_amount *= -1
	
	if (FlipTween): FlipTween.kill()
	FlipTween = create_tween()
	
	#FlipTween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	
	FlipTween.set_parallel()
	FlipTween.set_trans(Tween.TRANS_CUBIC)
	FlipTween.set_ease(Tween.EASE_OUT)
	
	FlipTween.tween_property($MeshInstance, "rotation_degrees:z", 180, 1.0)
	
	FlipTween.play()
	
	await FlipTween.finished
	#$MeshInstance.scale.y *= -1
	flipping = false
	
	await get_tree().process_frame
	$MeshInstance.rotation_degrees.x *= -1

var time = 0.0
func _process(delta):
	#sand_amount = remap(sin(time/20.0), -1, 1, 0, 1)
	var remaining = (timer_remaining if timer_paused else (timer_duration - ((Time.get_unix_time_from_system()*1000.0) - started_timestamp)))
	virtual_sand_amount = (remaining / timer_duration)
	if (not flipping): sand_amount = virtual_sand_amount
	
	#$MeshInstance.rotation_degrees.x = sin(time/20.0) * 10.0
	if (not flipping): $MeshInstance.rotation_degrees.y += 2.0
	
	$MeshInstance.position.y = remap(sin(time/50.0), -1, 1, 0.75, 1.25)
	
	time += 1.0
	
	sand_amount = clamp(sand_amount, 0.0, 1.0)
	
	var mesh: Mesh = $MeshInstance.mesh
	
	var top_sand: StandardMaterial3D = mesh.surface_get_material(4)
	var bot_sand: StandardMaterial3D = mesh.surface_get_material(5)
	
	top_sand.albedo_texture.gradient.offsets[1] = remap(1-sand_amount, 0.0, 1.0, 0.01, 0.99)
	bot_sand.albedo_texture.gradient.offsets[1] = remap(sand_amount, 0.0, 1.0, 0.01, 0.99)
	
	top_sand.albedo_texture.gradient.colors[0] = active_palette[0]
	bot_sand.albedo_texture.gradient.colors[0] = active_palette[0]
	top_sand.albedo_texture.gradient.colors[1] = active_palette[1]
	bot_sand.albedo_texture.gradient.colors[1] = active_palette[1]
	
	var inner_mat: StandardMaterial3D = mesh.surface_get_material(0)
	var outer_mat: StandardMaterial3D = mesh.surface_get_material(1)
	
	inner_mat.albedo_color = active_palette[0]
	outer_mat.albedo_color = active_palette[2]
	
	for color_idx in active_palette.size():
		var coloor = active_palette[color_idx]
		active_palette[color_idx] = coloor.lerp(Color(target_palette[color_idx]), 0.35)
	
	if (not flipping): $MeshInstance.rotation_degrees.z = 0

const STATES_TO_PALETTES = {
	"ACTIVE": PALETTE_ACTIVE,
	"BREAK": PALETTE_BREAK,
	"LONG_BREAK": PALETTE_LONG_BREAK,
}

var started_timestamp = 1.0
var timer_duration = 1.0
var timer_paused = false
var timer_remaining = 1.0
func _hourglass_start(currentState, duration, timestamp):
	timer_ended = false
	timer_paused = false
	timer_duration = duration
	started_timestamp = timestamp
	
	target_palette = STATES_TO_PALETTES[currentState]

var timer_ended = false
func _hourglass_end(oldState, newState):
	timer_ended = true
	
	if (timer_ended): timer_duration = timer_remaining
	
	print("NEW STATE: ", newState)
	print("NEW STATE: ", STATES_TO_PALETTES[newState])
	
	flip()

func _hourglass_pause(remaining):
	timer_remaining = remaining
	
	if (timer_ended): timer_duration = timer_remaining
	
	timer_paused = true
	
	target_palette = PALETTE_INACTIVE
