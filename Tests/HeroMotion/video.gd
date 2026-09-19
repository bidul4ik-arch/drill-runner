extends Node3D
var actors: Array[Node3D]=[]
var camera: Camera3D
func _ready() -> void: call_deferred("run")
func shot(name: String) -> void:
	for i in 8: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://Tests/HeroMotion/"+name+".png")
func add_model(asset: String, pos: Vector3, rot: float=0) -> Node3D:
	var obj: Node3D=load("res://Art/Models/"+asset+".glb").instantiate()
	add_child(obj);obj.position=pos;obj.rotation.y=rot
	actors.append(obj)
	var anim: AnimationPlayer=obj.find_child("AnimationPlayer",true,false)
	if anim and anim.has_animation("idle"): anim.play("idle");anim.seek(0,true);anim.pause()
	return obj
func run() -> void:
	get_window().size=Vector2i(1440,960)
	get_window().content_scale_size=Vector2i(1440,960)
	var env:=Environment.new()
	env.background_mode=Environment.BG_COLOR
	env.background_color=Color("b2aa99")
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color=Color("d4e6ed")
	env.ambient_light_energy=.32
	env.ssao_enabled=true
	env.ssao_radius=.6
	env.ssao_intensity=1.8
	env.ssao_detail=2.0
	env.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	env.glow_enabled=true
	env.glow_intensity=.5
	var world:=WorldEnvironment.new();world.environment=env;add_child(world)
	var floor:=MeshInstance3D.new();var plane:=PlaneMesh.new();plane.size=Vector2(200,200);floor.mesh=plane
	var mat:=StandardMaterial3D.new();mat.albedo_color=Color("b2aa99");mat.roughness=.85;floor.material_override=mat;floor.position.y=-.06;add_child(floor)
	var key:=DirectionalLight3D.new();key.rotation_degrees=Vector3(-38,-30,0);key.light_color=Color("ffe5c8");key.light_energy=1.0;key.shadow_enabled=true;add_child(key)
	key.light_angular_distance=.7
	var fill:=DirectionalLight3D.new();fill.rotation_degrees=Vector3(-20,135,0);fill.light_color=Color("9adeee");fill.light_energy=.55;add_child(fill)
	camera=Camera3D.new();camera.current=true;add_child(camera)
	camera.position=Vector3(0,1.55,6.8);camera.look_at(Vector3(0,1.13,0));camera.fov=33
	var clips: Array=["run","slide","boost"]
	for i in 3:
		var model:=add_model("explorer",Vector3((i-1)*1.45,0,0),-.4)
		Profile.apply_skin(model,"explorer")
	var canvas:=CanvasLayer.new();add_child(canvas)
	for i in 3:
		var label:=Label.new();label.text=["БЕГ","СКОЛЬЖЕНИЕ","БУР"][i];label.position=Vector2(175+i*475,850);label.add_theme_font_size_override("font_size",28);label.add_theme_color_override("font_color",Color("253b40"));canvas.add_child(label)
	camera.position=Vector3(0,2.4,7.8);camera.look_at(Vector3(0,.95,0));camera.fov=33
	DirAccess.make_dir_recursive_absolute("res://Tests/HeroMotion/Frames")
	for frame in 90:
		for i in 3:
			var anim: AnimationPlayer=actors[i].find_child("AnimationPlayer",true,false)
			anim.play(clips[i]);anim.seek(fmod(frame/30.0,anim.current_animation_length),true);anim.pause()
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://Tests/HeroMotion/Frames/%03d.png" % frame)
	get_tree().quit()
