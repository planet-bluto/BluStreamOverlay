extends Control
class_name EndScreenClass

signal ended

var payload: Array = []
var current_criteria: Dictionary = {}
var transitioning = false

const SLIDE_PREFABS = {
	"stat": preload("res://prefabs/end_screen_slide_stat.tscn"),
	#"rank": preload("res://prefabs/end_screen_slide_rank.tscn")
}

func _ready():
	Globals.next_slide_please.connect(next_slide_please)

func start(this_payload):
	for child in get_children(): # Kill the children.
		if (child != $BACKGROUND):
			child.queue_free()
	
	print("Oh yeah... we're starting... ", this_payload)
	payload = this_payload # hell yeaqh
	
	# BluBot will jump up in to focus first and then will be waiting for next slide signal
	#next_slide_please()

func next_slide_please():
	if (transitioning): return
	
	var slides = get_tree().get_nodes_in_group("Slide")
	
	if (slides.size() > 0):
		var slide = slides[0]
		slide.trans()
	else:
		if (payload.size() > 0):
			current_criteria = payload.pop_front()
			var slide_prefab: PackedScene = SLIDE_PREFABS[current_criteria.type]
			
			var slide = slide_prefab.instantiate()
			slide.payload = current_criteria
			
			slide.transition_start.connect(func(): transitioning = true)
			slide.transition_end.connect(func(): transitioning = false)
		
			add_child(slide)
		else: 
			print("erm...")
			pass
			# ending/scrolling credits slide??...
