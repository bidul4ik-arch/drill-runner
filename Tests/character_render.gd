extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size = Vector2i(900,900)
	var stage := Node3D.new()
	root.add_child(stage)
	var hero: Node3D = load("res://Art/Models/explorer.glb").instantiate()
	stage.add_child(hero)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("d3c7b7")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.WHITE
	env.ambient_light_energy = .6
	var world := WorldEnvironment.new()
	world.environment = env
	stage.add_child(world)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-30,155,0)
	key.light_energy = .9
	stage.add_child(key)
	var camera := Camera3D.new()
	stage.add_child(camera)
	camera.position = Vector3(2.3,1.65,-4)
	camera.look_at(Vector3(0,1.08,0))
	camera.fov = 34
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://Tests/character-front.png")
	camera.position = Vector3(-2,1.65,4)
	camera.look_at(Vector3(0,1.08,0))
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://Tests/character-back.png")
	stage.queue_free()
	await process_frame
	quit()
