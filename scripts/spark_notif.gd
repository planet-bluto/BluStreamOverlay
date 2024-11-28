extends RichTextLabel

#-------------------------------------------------#

func _ready():
	$Anim.play("TRANSITION")
	
	await $Anim.animation_finished
	
	queue_free()

func _process(delta):
	pass
