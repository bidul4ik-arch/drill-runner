extends Node3D
signal defeated
var game: Node
var config: Dictionary
var tap_cooldown := 0.0
var combo_step := 0
var combo_time := 0.0
var recoil := 0.0
var hp := 4
var max_hp := 4
var phase := 0
var stage := "intro"
var timer := 0.0
var attack_index := 0
var attacks_done := 0
var window_index := 0
var weak_lane := 0
var pattern: Array = []
var row_z := -18.0
var row: Node3D
var warnings: Array[MeshInstance3D] = []
var hazards: Array[Node3D] = []
var boss_key := ""
var model: Node3D
var anim: AnimationPlayer
var weak_marker: MeshInstance3D
var phase_seen := [false,false]
var attack_count := 0
var hit_count := 0
var warning_text := ""
func configure(owner_game: Node, key: String) -> void:
	boss_key=key
	game=owner_game
	config=Profile.bosses[key]
	hp=int(config.hp)
	max_hp=hp
	timer=float(config.intro)
	model=load("res://Art/Models/"+key+".glb").instantiate()
	add_child(model)
	model.position=Vector3(0,0,-24)
	# Blender -Y exports to Godot +Z: the boss faces the player.
	model.rotation.y=.22 if key=="giant_drill" else .10 if key=="mining_robot" else 0.0
	anim=model.find_child("AnimationPlayer",true,false)
	if anim and anim.has_animation("idle"):
		anim.get_animation("idle").loop_mode=Animation.LOOP_LINEAR
	play("idle")
	row=Node3D.new()
	add_child(row)
	for lane in 3:
		var mark:=MeshInstance3D.new()
		var mesh:=BoxMesh.new()
		mesh.size=Vector3(2.2,.035,16)
		mark.mesh=mesh
		var mat:=StandardMaterial3D.new()
		mat.albedo_color=Color(1,.25,.05,.42)
		mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		mark.material_override=mat
		mark.position=Vector3((lane-1)*2.5,.10,-7)
		add_child(mark)
		warnings.append(mark)
		mark.hide()
		for kind in 3:
			var paths: Array=["res://Scenes/Props/crate.tscn","res://Scenes/Props/pipe.tscn","res://Scenes/Props/cart.tscn"]
			if key=="crystal_guardian": paths=["res://Art/Models/crystal_wave.glb","res://Art/Models/crystal_beam.glb","res://Art/Models/crystal_wall.glb"]
			elif key=="giant_drill": paths=["res://Scenes/Props/crate.tscn","res://Scenes/Props/pipe.tscn","res://Scenes/Props/falling_rocks.tscn"]
			var h: Node3D=load(paths[kind]).instantiate()
			if key=="giant_drill" and kind==2:
				var drill: Node3D=load("res://Art/Models/drill_attack.glb").instantiate()
				h.add_child(drill)
				h.set_meta("drill",drill)
			row.add_child(h)
			h.position.x=(lane-1)*2.5
			h.hide()
			hazards.append(h)
	weak_marker=MeshInstance3D.new()
	var sphere:=SphereMesh.new()
	sphere.radius=.55
	sphere.height=1.1
	weak_marker.mesh=sphere
	var mat:=StandardMaterial3D.new()
	mat.albedo_color=Color("ffe25a")
	mat.emission_enabled=true
	mat.emission=Color("ffbd30")
	weak_marker.material_override=mat
	add_child(weak_marker)
	weak_marker.hide()
func play(name: String) -> void:
	if not anim: return
	for clip in anim.get_animation_list():
		if clip==name or clip.begins_with(name):
			anim.play(clip,.1)
			return
func tick(delta: float) -> void:
	timer-=delta
	tap_cooldown=maxf(0,tap_cooldown-delta)
	combo_time=maxf(0,combo_time-delta)
	if combo_time==0: combo_step=0
	recoil=maxf(0,recoil-delta)
	if stage in ["weak","hurt"]:
		model.position.z=-14+sin(recoil/.4*PI)*1.2
	phase=0 if hp>max_hp/2 else 1
	phase_seen[phase]=true
	match stage:
		"intro":
			model.position.z=move_toward(model.position.z,-14,delta*3)
			game.boss_message(tr(game.definition.boss_name))
			if timer<=0: begin_warning()
		"warning":
			game.boss_message(warning_text)
			for m in warnings: m.scale.y=1+absf(sin(timer*10))
			if timer<=0:
				stage="attack"
				timer=1.3
				row_z=-18
				row.position.z=row_z
				for i in 9:
					hazards[i].visible=pattern[i/3]==i%3
					if hazards[i].has_meta("drill"):
						hazards[i].get_child(0).visible=attack_index%2==0
						hazards[i].get_meta("drill").visible=attack_index%2==1
				play("attack")
				game.sfx("boss_attack")
		"attack":
			if boss_key=="giant_drill": model.position.z=lerpf(-14,-11,sin(clampf((1.3-timer)/1.3,0,1)*PI))
			var old:=row_z
			row_z+=22*delta
			row.position.z=row_z
			if row_z> -6 and row_z<1:
				game.boss_message("↑" if pattern==[0,0,0] else "↓" if pattern==[1,1,1] else "←   →")
			if old<.8 and row_z>=-.8:
				for lane in 3:
					if int(pattern[lane])<0: continue
					if absf(game.drill.position.x-(lane-1)*2.5)<1.05 and game.belt.hits(int(pattern[lane]),game.drill.position.y,game.drill.slide_left):
						game.hit()
						return
			if timer<=0:
				for h in hazards: h.hide()
				for w in warnings: w.hide()
				stage="recovery"
				timer=.65
				attacks_done+=1
				attack_count+=1
		"recovery":
			if timer<=0:
				if attacks_done>=int(config.attacks_per_window[phase]): begin_weak()
				else: begin_warning()
		"weak":
			weak_marker.rotation.y+=delta*2
			if timer<=0:
				weak_marker.hide()
				attacks_done=0
				begin_warning()
		"hurt":
			if timer<=0:
				if hp<=0:
					stage="defeat"
					timer=1.6
					play("defeat")
				else:
					attacks_done=0
					begin_warning()
		"defeat":
			model.position.y-=delta*.7
			if timer<=0:
				stage="done"
				defeated.emit()
func begin_warning() -> void:
	play("idle")
	stage="warning"
	timer=float(config.warning[phase])
	var sequence: Array=config.phases[phase]
	pattern=sequence[attack_index%sequence.size()].map(func(v): return int(v))
	attack_index+=1
	for lane in 3: warnings[lane].visible=int(pattern[lane])>=0
	var text: String="←   →"
	if pattern==[0,0,0]: text="↑"
	elif pattern==[1,1,1]: text="↓"
	warning_text=text
	game.boss_message(warning_text)
	game.sfx("warning")
	Profile.buzz()
func begin_weak() -> void:
	play("idle")
	combo_step=0
	combo_time=0
	stage="weak"
	timer=float(config.weak_time)
	weak_lane=(window_index%3)-1
	window_index+=1
	weak_marker.position=Vector3(weak_lane*2.5,1.2,-5)
	weak_marker.show()
	var names: Array=[tr("ЛЕВАЯ"),tr("ЦЕНТР"),tr("ПРАВАЯ")]
	game.boss_message(names[weak_lane+1]+tr(" · БУР ×3"))
	game.sfx("power")
func try_boost() -> bool:
	if stage!="weak" or tap_cooldown>0 or absf(game.drill.position.x-weak_lane*2.5)>.65: return false
	tap_cooldown=.18
	combo_time=1.3
	combo_step+=1
	recoil=.4
	play("hurt")
	if anim: anim.seek(0,true)
	game.comic_hit(Banter.take("impact"))
	game.boss_message(tr("БУР · ")+"●".repeat(combo_step)+"○".repeat(3-combo_step))
	game.sfx("boss_hit")
	Profile.buzz()
	if combo_step<3:
		timer=maxf(timer,1.8)
		return true
	hp-=1
	hit_count+=1
	weak_marker.hide()
	stage="hurt"
	timer=.9
	combo_step=0
	return true
func pause_animation(paused: bool) -> void:
	if anim:
		if paused: anim.pause()
		else: anim.play()
