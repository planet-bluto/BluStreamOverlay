@tool
extends Node3D

const SparkTypeInfo = {
	"BOLTA": {
		"colors": [Color("#024aca"), Color("#0a89ff"), Color("#5ba8ff")],
		"face": preload("res://textures/sparks/bolta_face.png")
	},
	"MUSE": {
		"colors": [Color("#ffbb31"), Color("#ffe737"), Color("#eeffa9")],
		"face": preload("res://textures/sparks/muse_face.png")
	},
	"CODEC": {
		"colors": [Color("#8cd612"), Color("#beeb71"), Color("#eeffa9")],
		"face": preload("res://textures/sparks/codec_face.png")
	},
	"MALO": {
		"colors": [Color("#e03c28"), Color("#da655e"), Color("#e18289")],
		"face": preload("res://textures/sparks/malo_face.png")
	},
	"VISU": {
		"colors": [Color("#6264dc"), Color("#9ba0ef"), Color("#9ba0ef")],
		"face": preload("res://textures/sparks/visu_face.png")
	},
}

@export_enum("BOLTA", "MUSE", "CODEC", "MALO", "VISU") var TYPE: String = "BOLTA"
@export var USER: String = ""

@export var AMP = 2.5
@export var FREQ = 5
@export var SCALE = 0.11
@export var SHRINK = 0.4

var bone_poses = {}
func _ready():
	var inner_mat: StandardMaterial3D = $Container/Armature/InnerBolt.mesh.surface_get_material(0)
	var mid_mat: StandardMaterial3D = $Container/Armature/MidBolt.mesh.surface_get_material(0)
	var outer_mat: StandardMaterial3D = $Container/Armature/OuterBolt.mesh.surface_get_material(0)
	var face_mat: StandardMaterial3D = $Container/Face.mesh.surface_get_material(0)
	
	var new_inner_mat = inner_mat.duplicate(true)
	var new_mid_mat = mid_mat.duplicate(true)
	var new_outer_mat = outer_mat.duplicate(true)
	var new_face_mat = face_mat.duplicate(true)
	
	$Container/Armature/InnerBolt.mesh.surface_set_material(0, new_inner_mat)
	$Container/Armature/MidBolt.mesh.surface_set_material(0, new_mid_mat)
	$Container/Armature/OuterBolt.mesh.surface_set_material(0, new_outer_mat)
	$Container/Face.mesh.surface_set_material(0, new_face_mat)
	
	for i in 4:
		var bone_idx = $Container/Armature.find_bone("Bone.00" + str(i+1))
		var base_pos = $Container/Armature.get_bone_pose_position(bone_idx)
		bone_poses[bone_idx] = base_pos

func _process(delta):
	$Label.text = USER
	
	_apply_type()
	_animate(delta)
	_floating()

func _floating():
	$Container.position.y = sin(time / 50.0)

func _apply_type():
	var this_type = "MUSE"
	if (TYPE is String): TYPE = TYPE.to_upper()
	if (TYPE != null): this_type = TYPE
	var type_info = SparkTypeInfo[this_type]
	
	var inner_mat: StandardMaterial3D = $Container/Armature/InnerBolt.mesh.surface_get_material(0)
	inner_mat.albedo_color = type_info.colors[1]
	
	var mid_mat: StandardMaterial3D = $Container/Armature/MidBolt.mesh.surface_get_material(0)
	mid_mat.albedo_color = type_info.colors[0]
	
	var outer_mat: StandardMaterial3D = $Container/Armature/OuterBolt.mesh.surface_get_material(0)
	outer_mat.albedo_color = type_info.colors[1]
	
	var face_mat: StandardMaterial3D = $Container/Face.mesh.surface_get_material(0)
	face_mat.albedo_texture = type_info.face
	
	$Container/Sparklies.mesh.size = Vector2(2.0 * scale.x, 2.0 * scale.y)
	$Container/Sparklies.mesh.material.albedo_color = type_info.colors[2]
	$Container/Sparklies.mesh.material.emission = type_info.colors[2]

var time = 0.0
var frame = 0
func _animate(delta):
	var delta_scale = (delta / (1.0 / 60.0))
	
	var val = sin(((time * SCALE) + ((PI / 5) * 0)) * FREQ)
	
	for i in 4:
		var bone_idx = $Container/Armature.find_bone("Bone." + str(i+1).lpad(3, "0"))
		var base_pos = bone_poses[bone_idx]
		base_pos.x = (sin(((time * SCALE) + ((PI / 5) * i)) * FREQ) * clamp(AMP - (SHRINK * i), 0, INF))
		
		base_pos.z = randf_range(-(AMP/2), (AMP/2))
		
		if (val < -0.3 or val > 0.3): $Container/Armature.set_bone_pose_position(bone_idx, base_pos)
	
	var rot_bone_idx = $Container/Armature.find_bone("Bone." + str(5).lpad(3, "0"))
	var rot_bone_rot = Quaternion.IDENTITY
	rot_bone_rot.z = (sin(((time * SCALE) + ((PI / 5) * 5)) * FREQ) * clamp(AMP - (SHRINK * 5), 0, INF)) * 0.8
	if (val < -0.3 or val > 0.3): $Container/Armature.set_bone_pose_rotation(rot_bone_idx, rot_bone_rot)
	
	time += (1.0 * delta_scale)
	frame += 1
