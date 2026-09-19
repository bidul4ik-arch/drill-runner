extends Button
var skin_id := "explorer"
func _ready() -> void:
	var frame:=StyleBoxFlat.new()
	frame.bg_color=Color("17333c")
	frame.border_color=Color("c89850")
	frame.set_border_width_all(3)
	frame.set_corner_radius_all(14)
	add_theme_stylebox_override("normal",frame)
	var hover=frame.duplicate()
	hover.border_color=Color("57e5e8")
	add_theme_stylebox_override("hover",hover)
	add_theme_stylebox_override("pressed",hover)
	custom_minimum_size=Vector2(245,204)
	var view:=SubViewport.new()
	view.size=Vector2i(245,192)
	view.own_world_3d=true
	view.transparent_bg=true
	view.render_target_update_mode=SubViewport.UPDATE_ONCE
	add_child(view)
	var model: Node3D=preload("res://Art/Models/explorer.glb").instantiate()
	view.add_child(model)
	model.rotation.y=PI+.2
	Profile.apply_skin(model,skin_id)
	var camera:=Camera3D.new()
	view.add_child(camera)
	camera.position=Vector3(0,1.25,3.5)
	camera.look_at(Vector3(0,1.13,0))
	camera.fov=37
	var light:=DirectionalLight3D.new()
	light.rotation_degrees=Vector3(-35,-30,0)
	light.light_energy=1.8
	view.add_child(light)
	var fill:=DirectionalLight3D.new()
	fill.rotation_degrees=Vector3(10,130,0)
	fill.light_energy=.8
	view.add_child(fill)
	var world:=WorldEnvironment.new()
	world.environment=Environment.new()
	world.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color=Color("e6cfaa")
	world.environment.ambient_light_energy=.5
	view.add_child(world)
	var picture:=TextureRect.new()
	picture.texture=view.get_texture()
	picture.mouse_filter=Control.MOUSE_FILTER_IGNORE
	picture.position=Vector2(0,4)
	picture.size=Vector2(245,192)
	picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(picture)
