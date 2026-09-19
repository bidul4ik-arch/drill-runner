extends "res://Script/Main.gd"
@export var level_id := 1
var definition: Dictionary = {}
var boss: Node3D
var boss_bar: ProgressBar
var boss_label: Label
var boost_button: Button
var resume_state := "run"
var checkpoint := false
var run_id := ""
var rewarded := false
var boost_left := 0.0
var boss_text := ""
var atmosphere: AudioStreamPlayer
func _ready() -> void:
	definition=Profile.level(level_id) if level_id>0 else Profile.level(1).duplicate()
	super._ready()
	Engine.max_fps=60 if int(Profile.data.quality)==1 else 30
	for light in find_children("*","DirectionalLight3D",true,false): light.shadow_enabled=int(Profile.data.quality)==1
	for world in find_children("*","WorldEnvironment",true,false):
		world.environment.ssao_enabled=int(Profile.data.quality)==1 and ProjectSettings.get_setting_with_override("rendering/renderer/rendering_method")=="forward_plus"
		world.environment.fog_light_color=Color(definition.fog)
		world.environment.background_color=Color(definition.fog)
		world.environment.ambient_light_color=Color(definition.ambient)
	music.pitch_scale=float(definition.music_pitch)
	atmosphere=AudioStreamPlayer.new()
	atmosphere.stream=load("res://Audio/"+definition.atmosphere+".wav")
	atmosphere.volume_db=-22
	add_child(atmosphere)
	atmosphere.finished.connect(func(): atmosphere.play())
	atmosphere.play()
	apply_volume()
	var root: Control=pause_button.get_parent()
	boss_label=Label.new()
	root.add_child(boss_label)
	boss_label.position=Vector2(180,88)
	boss_label.custom_minimum_size=Vector2(420,38)
	boss_label.add_theme_font_size_override("font_size",19)
	boss_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	boss_label.add_theme_color_override("font_color",Color("ffe17b"))
	boss_bar=ProgressBar.new()
	root.add_child(boss_bar)
	boss_bar.position=Vector2(24,122)
	boss_bar.size=Vector2(590,8)
	boss_bar.custom_minimum_size.y=8
	boss_bar.show_percentage=false
	boss_bar.add_theme_font_size_override("font_size",1)
	var hp_fill:=StyleBoxFlat.new()
	hp_fill.bg_color=Color("e9a837")
	hp_fill.set_corner_radius_all(4)
	hp_fill.content_margin_top=0
	hp_fill.content_margin_bottom=0
	boss_bar.add_theme_stylebox_override("fill",hp_fill)
	var hp_back:=StyleBoxFlat.new()
	hp_back.bg_color=Color("263b42")
	hp_back.set_corner_radius_all(4)
	hp_back.content_margin_top=0
	hp_back.content_margin_bottom=0
	boss_bar.add_theme_stylebox_override("background",hp_back)
	boss_bar.size.y=8
	boss_bar.hide()
	boost_button=Button.new()
	root.add_child(boost_button)
	boost_button.text=tr("БУР")
	boost_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	boost_button.offset_left=-125
	boost_button.offset_right=-24
	boost_button.offset_top=-100
	boost_button.offset_bottom=-34
	boost_button.pressed.connect(boost)
	boost_button.hide()
	# Respect the platform safe area; the entire HUD uses the same inset.
	if OS.has_feature("mobile"):
		var safe:=DisplayServer.get_display_safe_area()
		var window:=DisplayServer.window_get_size()
		var ratio:=get_viewport().get_visible_rect().size.y/maxf(1,window.y)
		root.offset_top=maxf(0,safe.position.y)*ratio
		root.offset_bottom=-maxf(0,window.y-safe.end.y)*ratio
func show_menu() -> void:
	if definition.is_empty(): return
	state="intro"
	clear_panel()
	label_text(tr(definition.title) if level_id>0 else tr("БЕСКОНЕЧНЫЙ РЕЙС"),30,CYAN)
	checkpoint=level_id>0 and Flow.resume_checkpoint
	Flow.resume_checkpoint=false
	button(tr("Продолжить бой") if checkpoint else tr("Начать уровень"),start_run)
	button(tr("В меню"),func(): Flow.go("res://Scenes/Screens/MainMenu.tscn"))
func start_run() -> void:
	if is_instance_valid(boss):
		remove_child(boss)
		boss.queue_free()
		boss=null
	belt.random_enabled=true
	super.start_run()
	run_id=str(Time.get_unix_time_from_system())+"-"+str(randi())
	rewarded=false
	if Flow.resume_run and not Profile.data.suspended_run.is_empty() and int(Profile.data.suspended_run.level)==level_id:
		var snapshot: Dictionary=Profile.data.suspended_run
		distance=float(snapshot.distance)
		coins=int(snapshot.coins)
		run_id=snapshot.run_id
		elapsed=float(snapshot.get("elapsed",distance/float(definition.speed)))
	Flow.resume_run=false
	Profile.data.suspended_run={}
	if level_id>0: Profile.data.last_level=level_id
	Profile.data.checkpoint=level_id if checkpoint else 0
	Profile.data.started=true
	Profile.save()
	belt.random_enabled=true
	boost_left=0
	if boss_label: boss_label.text=""
	if boss_bar: boss_bar.hide()
	if boost_button: boost_button.show()
	if checkpoint: begin_boss()
func _physics_process(delta: float) -> void:
	if state=="run":
		# The common runner remains responsible for movement and pickups.
		var old_distance:=distance
		super._physics_process(delta)
		if state=="run" and level_id>0 and distance>=float(definition.distance): begin_boss()
		if state=="run":
			distance_hud.text=tr("%d / %d м") % [int(distance),int(definition.distance)] if level_id>0 else tr("%d м") % int(distance)
			if old_distance<50: status.text="← →   ↑   ↓"
	elif state=="boss":
		drill.tick(delta)
		belt.tick(delta,12)
		immunity=maxf(0,immunity-delta)
		shield_left=maxf(0,shield_left-delta)
		magnet_left=maxf(0,magnet_left-delta)
		boss.tick(delta)
		if boss_bar: boss_bar.value=boss.hp
		if boss_label: boss_label.text=boss_text
	hud.text="%06d" % score()
	coin_hud.text=str(coins)
	if state=="boss":
		status.text=""
		distance_hud.text=""
	boost_left=maxf(0,boost_left-(delta if state in ["run","boss"] else 0.0))
	if is_instance_valid(drill) and state in ["run","boss"]:
		drill.visual.position.z=lerpf(drill.visual.position.z,-6.0 if boost_left>.45 else 0.0,minf(1,delta*12))
	if boost_button:
		boost_button.visible=state in ["run","boss"]
		boost_button.disabled=(boss.tap_cooldown>0 if state=="boss" else boost_left>0)
	update_presentation(delta)
func begin_boss() -> void:
	checkpoint=true
	Profile.data.checkpoint=level_id
	Profile.save()
	belt.clear_dangers()
	state="boss"
	boss=load("res://Scenes/Bosses/"+definition.boss+".tscn").instantiate()
	add_child(boss)
	boss.configure(self,definition.boss)
	boss.defeated.connect(victory)
	boss_bar.max_value=boss.max_hp
	boss_bar.value=boss.hp
	boss_bar.show()
	status.text=tr("Контрольная точка сохранена")
func boss_message(value: String) -> void:
	boss_text=value
func boost() -> void:
	if not state in ["run","boss"] or (state=="run" and boost_left>0): return
	if state=="boss":
		if not boss.try_boost():
			boss_message(tr("На полосу ядра → БУР ×3"))
			sfx("ui")
			return
		drill.boost_pose()
		boost_left=.85
		sfx("boost")
	else:
		# Short shield-like burst; does not alter campaign distance or boss rules.
		drill.boost_pose()
		boost_left=.85
		immunity=.85
		sfx("boost")
func victory() -> void:
	if state!="victory" and (not is_instance_valid(boss) or boss.hp>0): return
	state="victory"
	drill.play("victory")
	var reward:=int(definition.reward)+coins
	if not rewarded:
		Profile.data.suspended_run={}
		rewarded=Profile.reward(run_id,level_id,reward)
	clear_panel()
	pause_button.hide()
	boost_button.hide()
	boss_label.text=""
	boss_bar.hide()
	sfx("victory")
	label_text(tr("КАМПАНИЯ ПРОЙДЕНА!") if level_id==Profile.levels.size() else tr("УРОВЕНЬ ПРОЙДЕН"),29,CYAN)
	label_text(tr(definition.title)+tr("\nНаграда: %d монет") % reward,22)
	label_text(tr("Следующий уровень открыт") if level_id<Profile.levels.size() else tr("Все три босса побеждены. Спасибо за рейс!"),18)
	button(tr("В домик"),func(): Flow.go("res://Scenes/Screens/Home.tscn"))
func hit() -> void:
	if not state in ["run","boss"]: return
	if immunity>0: return
	if shield_left>0:
		shield_left=0
		immunity=1.2
		sfx("power")
		return
	checkpoint=false
	Profile.data.checkpoint=0
	state="over"
	drill.play("hit")
	sfx("hit")
	Profile.buzz()
	Profile.data.best=maxi(int(Profile.data.best),score())
	Profile.data.suspended_run={}
	Profile.reward(run_id,0,coins)
	clear_panel()
	if boost_button: boost_button.hide()
	if boss_label: boss_label.text=""
	label_text(tr("РЕЙС ПРЕРВАН"),30,CYAN)
	label_text(tr("%d м · %d монет") % [int(distance),coins],20)
	button(tr("Заново"),restart_level)
	button(tr("В меню"),func(): Flow.go("res://Scenes/Screens/MainMenu.tscn"))
func toggle_pause() -> void:
	if state in ["run","boss"]:
		resume_state=state
		if boss: boss.pause_animation(true)
		state="run"
		super.toggle_pause()
		# Replace old restart/menu callbacks with campaign navigation.
		clear_panel()
		label_text(tr("ПАУЗА"),32,CYAN)
		button(tr("Продолжить"),resume)
		button(tr("Звук"),func(): show_settings("pause"))
		button(tr("Заново"),restart_level)
		button(tr("В меню"),func(): Flow.go("res://Scenes/Screens/MainMenu.tscn"))
		save_snapshot()
	elif state=="pause": resume()
func resume() -> void:
	super.resume()
	state=resume_state
	if boss: boss.pause_animation(false)
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_E: boost();return
	super._unhandled_input(event)
func load_progress() -> void:
	best=int(Profile.data.best)
	total_coins=int(Profile.data.coins)
	music_volume=float(Profile.data.music)
	effects_volume=float(Profile.data.effects)
func save_progress() -> void:
	Profile.data.music=music_volume
	Profile.data.effects=effects_volume
	Profile.save()
func _notification(what: int) -> void:
	if what==NOTIFICATION_WM_GO_BACK_REQUEST:
		if state in ["run","boss","pause"]:toggle_pause()
		elif state=="settings":_return_to_pause()
		else:Flow.go("res://Scenes/Screens/MainMenu.tscn")
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]:
		if state in ["run","boss"]: toggle_pause()
		Profile.save()
	if what==NOTIFICATION_WM_CLOSE_REQUEST: shutdown()

func run_speed() -> float:
	return lerpf(float(definition.speed),float(definition.max_speed),clampf(elapsed/float(definition.get("acceleration_seconds",8)),0,1)) if not definition.is_empty() else 11.0

func apply_volume() -> void:
	super.apply_volume()
	if is_instance_valid(atmosphere): atmosphere.volume_db=linear_to_db(maxf(.0001,effects_volume*.15))
func _return_to_pause() -> void:
	state=resume_state
	toggle_pause()

func save_snapshot() -> void:
	if level_id>0:
		Profile.data.suspended_run={"level":level_id,"distance":distance,"coins":coins,"run_id":run_id,"elapsed":elapsed}
	Profile.save()

func restart_level() -> void:
	checkpoint=false
	Profile.data.checkpoint=0
	Profile.data.suspended_run={}
	start_run()

func comic_hit(word: String) -> void:
	var impact=preload("res://Script/UI/ComicImpact.gd").new()
	impact.word=word
	impact.caption=Banter.take("boss_"+str(level_id))
	impact.position=camera.unproject_position(boss.model.global_position+Vector3(0,2.5,0))-Vector2(95,55)
	impact.position.x=clampf(impact.position.x,20,430)
	impact.position.y=clampf(impact.position.y,180,600)
	var old_comic=pause_button.get_parent().get_node_or_null("ComicCallout")
	if old_comic:
		pause_button.get_parent().remove_child(old_comic)
		old_comic.queue_free()
	impact.name="ComicCallout"
	pause_button.get_parent().add_child(impact)
