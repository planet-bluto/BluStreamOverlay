extends Node3D

#-------------------------------------------------#

@onready var Skeleton = $Armature/Skeleton3D

#-------------------------------------------------#

var curr_frame = 0
var  bone_cache = {}
func _process(delta):
	if (curr_frame % 4 == 0):
		for i in 5:
			var old_bone_pose = Skeleton.get_bone_pose_position(i+1)
			
			var x_mag = randf_range(0.0,2.0)
			var y_mag = randf_range(0.0,1.0)
			var ang = randi_range(0, 360)
			
			var bone_pos = Vector3(
				cos(deg_to_rad(ang)) * x_mag,
				old_bone_pose.y,
				sin(deg_to_rad(ang)) * y_mag
			)
			
			bone_cache[i+1] = bone_pos
			
	for bone_idx in bone_cache:
		var old_bone_pose = Skeleton.get_bone_pose_position(bone_idx)
		var bone_pos = old_bone_pose
		bone_pos.x = ease(lerp(old_bone_pose.x, bone_cache[bone_idx].x, 0.75), 0.75)
		bone_pos.z = ease(lerp(old_bone_pose.z, bone_cache[bone_idx].z, 0.75), 0.75)
		Skeleton.set_bone_pose_position(bone_idx, bone_pos)
	
	curr_frame += 1
