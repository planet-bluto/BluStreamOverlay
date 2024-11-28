extends SlideBase

func _ready():
	super()
	$Contents/Label.text = str(meta.value)
