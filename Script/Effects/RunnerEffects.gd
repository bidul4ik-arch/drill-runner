extends Node3D
var game: Node
var shield: MeshInstance3D
var magnet: Node3D
var pickup_flash: CPUParticles3D
var foot_dust: CPUParticles3D
var motes: CPUParticles3D
var dust: CPUParticles3D
var chips: Array[MeshInstance3D]=[]
var motion:=0.0
var collapse_strength:=0.0
var rng:=RandomNumberGenerator.new()
func material(color: Color, glow:=false) -> StandardMaterial3D:
	var m:=StandardMaterial3D.new();m.albedo_color=color
	if glow:m.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	return m
func _ready() -> void:
	game=get_parent();rng.seed=4819
	shield=MeshInstance3D.new();var sphere:=SphereMesh.new();sphere.radius=.75;sphere.height=2.6;shield.mesh=sphere;add_child(shield)
	var shader:=Shader.new();shader.code="shader_type spatial; render_mode unshaded, blend_add, depth_draw_never; void fragment(){float edge=pow(1.0-abs(dot(normalize(NORMAL),normalize(VIEW))),2.5); ALBEDO=vec3(0.1,0.8,1.0); ALPHA=edge*0.3+0.008;}"
	var shell:=ShaderMaterial.new();shell.shader=shader;shield.material_override=shell;shield.hide()
	magnet=Node3D.new();add_child(magnet)
	for i in 3:
		var ring:=MeshInstance3D.new();var mesh:=TorusMesh.new();mesh.inner_radius=.66+i*.08;mesh.outer_radius=.685+i*.08;mesh.rings=32;mesh.ring_segments=6;ring.mesh=mesh;ring.material_override=material(Color("ce6dff"),true);ring.rotation.z=.35*(i-1);magnet.add_child(ring)
	magnet.hide()
	pickup_flash=CPUParticles3D.new();add_child(pickup_flash);pickup_flash.amount=28;pickup_flash.lifetime=.65;pickup_flash.one_shot=true;pickup_flash.explosiveness=1
	pickup_flash.initial_velocity_min=2;pickup_flash.initial_velocity_max=5;pickup_flash.gravity=Vector3(0,-3,0);pickup_flash.spread=180;pickup_flash.scale_amount_min=.025;pickup_flash.scale_amount_max=.065
	var spark:=SphereMesh.new();spark.radius=1;spark.height=2;pickup_flash.mesh=spark;pickup_flash.material_override=material(Color.WHITE,true);pickup_flash.emitting=false
	dust=CPUParticles3D.new();add_child(dust);dust.amount=32;dust.lifetime=1.2;dust.emission_shape=CPUParticles3D.EMISSION_SHAPE_BOX;dust.emission_box_extents=Vector3(4,2,7);dust.position=Vector3(0,2,-5)
	dust.direction=Vector3(0,0,1);dust.spread=12;dust.gravity=Vector3(0,-.4,0);dust.initial_velocity_min=10;dust.initial_velocity_max=19;dust.scale_amount_min=.22;dust.scale_amount_max=.65
	var quad:=QuadMesh.new();quad.size=Vector2.ONE;dust.mesh=quad
	var dm:=material(Color(.83,.64,.36,.3));dm.albedo_texture=preload("res://Art/Textures/dust_puff.png");dm.vertex_color_use_as_albedo=true;dm.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;dm.billboard_mode=BaseMaterial3D.BILLBOARD_ENABLED;dm.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;dust.material_override=dm;dust.emitting=false
	var fade:=Gradient.new()
	fade.offsets=PackedFloat32Array([0,.18,1])
	fade.colors=PackedColorArray([Color(1,1,1,0),Color(1,1,1,.55),Color(1,1,1,0)])
	dust.color_ramp=fade
	var growth:=Curve.new();growth.add_point(Vector2(0,.3));growth.add_point(Vector2(1,1))
	dust.scale_amount_curve=growth
	foot_dust=CPUParticles3D.new();add_child(foot_dust)
	foot_dust.amount=20;foot_dust.lifetime=.55;foot_dust.mesh=quad;foot_dust.material_override=dm
	foot_dust.color_ramp=fade;foot_dust.scale_amount_curve=growth
	foot_dust.emission_shape=CPUParticles3D.EMISSION_SHAPE_SPHERE;foot_dust.emission_sphere_radius=.18
	foot_dust.direction=Vector3(0,.15,1);foot_dust.spread=22;foot_dust.gravity=Vector3(0,.15,0)
	foot_dust.initial_velocity_min=1;foot_dust.initial_velocity_max=3
	foot_dust.scale_amount_min=.16;foot_dust.scale_amount_max=.42;foot_dust.emitting=false
	motes=CPUParticles3D.new();add_child(motes)
	motes.amount=22;motes.lifetime=3;motes.mesh=spark;motes.material_override=material(Color("ffd6a0"),true)
	motes.color_ramp=fade;motes.emission_shape=CPUParticles3D.EMISSION_SHAPE_BOX;motes.emission_box_extents=Vector3(4,2.5,10)
	motes.position=Vector3(0,2.5,-9);motes.direction=Vector3(0,0,1);motes.gravity=Vector3.ZERO
	motes.initial_velocity_min=1;motes.initial_velocity_max=3;motes.scale_amount_min=.008;motes.scale_amount_max=.018
	var chip_mesh:=PrismMesh.new();chip_mesh.size=Vector3(.10,.16,.11)
	var stone:=material(Color("98704b"))
	for i in 28:
		var chip:=MeshInstance3D.new();chip.mesh=chip_mesh;chip.material_override=stone;add_child(chip);chips.append(chip);reset_chip(chip);chip.hide()
func reset_chip(chip: Node3D) -> void:
	chip.position=Vector3(rng.randf_range(-4.5,4.5),rng.randf_range(3.4,7),rng.randf_range(-24,-6))
	chip.scale=Vector3.ONE*rng.randf_range(.5,1.7)
func burst(at: Vector3, color: Color) -> void:
	pickup_flash.position=at;pickup_flash.color=color;pickup_flash.restart();pickup_flash.emitting=true
func tick(delta: float) -> void:
	var active: bool=game.state in ["run","boss"]
	dust.speed_scale=1.0 if active else 0.0;pickup_flash.speed_scale=dust.speed_scale
	foot_dust.speed_scale=dust.speed_scale;motes.speed_scale=dust.speed_scale
	if not active:return
	foot_dust.position=game.drill.position+Vector3(0,.09,.15)
	foot_dust.emitting=game.drill.position.y<.15
	foot_dust.initial_velocity_max=game.run_speed()*.22
	motes.initial_velocity_max=game.run_speed()*.5
	motion+=delta
	shield.visible=game.shield_left>0;shield.position=game.drill.position+Vector3(0,1.0,0)
	magnet.visible=game.magnet_left>0;magnet.position=game.drill.position+Vector3(0,1,0);magnet.rotation.y=motion*2;magnet.rotation.x=sin(motion*2)*.22
	collapse_strength=clampf((game.run_speed()-12)/8,0,1) if game.state=="run" else .15
	dust.emitting=collapse_strength>.3
	for i in chips.size():
		var chip:=chips[i];chip.visible=float(i)/chips.size()<collapse_strength*.7 and collapse_strength>.4
		if chip.visible:
			chip.position+=Vector3(0,-3.4,game.run_speed()*.85)*delta;chip.rotate_x(delta*3);chip.rotate_z(delta*1.7)
			if chip.position.z>4 or chip.position.y<-.2:reset_chip(chip)
	for chunk in game.belt.chunks:
		var decor: Node3D=chunk.get_child(0)
		decor.rotation.z=sin(motion*17+chunk.position.z)*.0008*collapse_strength
