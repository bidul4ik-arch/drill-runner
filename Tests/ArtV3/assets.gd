extends Node
var failures:=0
func check(value: bool, message: String) -> void:
	if not value:failures+=1;push_error(message)
func _ready() -> void:call_deferred("run")
func run() -> void:
	for asset in ["explorer","mining_robot","crystal_guardian","giant_drill"]:
		var model: Node3D=load("res://Art/Models/"+asset+".glb").instantiate()
		add_child(model)
		await get_tree().process_frame
		var anim: AnimationPlayer=model.find_child("AnimationPlayer",true,false)
		check(anim!=null,asset+" animation player")
		var expected: Array=["idle","run","sprint","jump","fall","slide","hit","land","lane_left","lane_right","boost","victory"] if asset=="explorer" else ["idle","attack","hurt","defeat"]
		for clip in expected:
			check(anim.has_animation(clip),asset+" clip "+clip)
			if anim.has_animation(clip):check(anim.get_animation(clip).get_track_count()>0,asset+" tracks "+clip)
		if asset=="explorer":
			var skeleton: Skeleton3D=model.find_child("Skeleton3D",true,false)
			check(skeleton!=null and skeleton.get_bone_count()==15,"Articulated fifteen-bone character rig")
			Profile.apply_skin(model,"explorer")
			for mesh in model.find_children("*","MeshInstance3D",true,false):
				for i in mesh.mesh.get_surface_count():
					var mat: Material=mesh.mesh.surface_get_material(i)
					if mat.resource_name=="gold":
						var override: StandardMaterial3D=mesh.get_surface_override_material(i)
						check(override!=null and override.albedo_color.is_equal_approx(Color("bc812e")),"Wardrobe dye retains target color")
		else:
			anim.play("attack");anim.seek(0,true)
			var before: Array[Transform3D]=[]
			var meshes=model.find_children("*","MeshInstance3D",true,false)
			for mesh in meshes:before.append(mesh.transform)
			anim.seek(.5,true)
			var moved:=false
			for i in meshes.size():
				if not meshes[i].transform.is_equal_approx(before[i]):moved=true
			check(moved,asset+" attack visibly animates assemblies")
		model.queue_free();await get_tree().process_frame
	print("ART ASSETS: ",failures," failures")
	get_tree().quit(failures)
