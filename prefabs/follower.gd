extends PathFollow3D

var prev_progress = progress
var loops = 0

func _ready():
	var new_spark = $Spark.duplicate()
	$Spark.queue_free()
	add_child(new_spark)

func _process(delta):
	var frame_const = (1.0 / 60.0)
	var delta_weight = (delta / frame_const)
	
	progress += (0.15 * delta_weight)
	
	if (progress < prev_progress):
		print("LOOPED")
		loops += 1
	
	if (loops >= Globals.SPARK_LOOP_COUNT):
		queue_free()
	else:
		prev_progress = progress

func replenish():
	loops = 0
