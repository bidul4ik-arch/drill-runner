extends Node3D
@onready var drill: Drill = $Drill
@onready var belt = $ChunkSpawner
@onready var camera: Camera3D = $Camera3D
var elapsed := 0.0
var runner_effects: Node3D
var buff_icons: Array[Control] = []
var state := "menu"
var distance := 0.0
var coins := 0
var best := 0
var total_coins := 0
var shield_left := 0.0
var magnet_left := 0.0
var immunity := 0.0
var music_volume := .35
var effects_volume := .65
var music: AudioStreamPlayer
var voices: Array[AudioStreamPlayer] = []
var voice_index := 0
var hud: Label
var coin_hud: Label
var distance_hud: Label
var status: Label
var panel: PanelContainer
var content: VBoxContainer
var overlay: ColorRect
var pause_button: Button
var touch_start := Vector2.ZERO
var touch_id := -1
var fx_left := 0.0
var flash: ColorRect
var save_path := "user://progress.cfg"
const CREAM := Color("f7e7c2")
const CYAN := Color("55e4d1")

func _ready() -> void:
	if "--test" in OS.get_cmdline_user_args(): save_path = "user://test_progress.cfg"
	load_progress()
	get_tree().auto_accept_quit = false
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("cfae81")
	env.fog_enabled = true
	env.fog_light_color = Color("d8b993")
	env.fog_light_energy = .45
	env.fog_density = .0045
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("d5c6ae")
	env.ambient_light_energy = .22
	var reflection_sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("637c85")
	sky_material.sky_horizon_color = Color("d6bc91")
	sky_material.ground_bottom_color = Color("382c21")
	sky_material.ground_horizon_color = Color("ac8559")
	reflection_sky.sky_material = sky_material
	env.sky = reflection_sky
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.1
	env.ssao_enabled = ProjectSettings.get_setting_with_override("rendering/renderer/rendering_method")=="forward_plus"
	env.ssao_radius = .7
	env.ssao_intensity = 1.6
	env.ssao_detail = 1.5
	env.glow_enabled = ProjectSettings.get_setting_with_override("rendering/renderer/rendering_method")!="gl_compatibility"
	env.glow_intensity = .55
	env.glow_bloom = .08
	var world := WorldEnvironment.new()
	world.environment = env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48,-30,0)
	sun.light_color = Color("ffd398")
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	sun.shadow_bias = .10
	sun.shadow_normal_bias = 2.0
	sun.light_angular_distance = .65
	sun.directional_shadow_max_distance = 55.0
	add_child(sun)
	var light := OmniLight3D.new()
	light.position = Vector3(-2.0,3.8,2.5)
	light.omni_range = 9
	light.light_color = Color("a2ddeb")
	light.light_energy = .65
	add_child(light)
	var hero_key := OmniLight3D.new()
	hero_key.position = Vector3(2.3,4.2,3.3)
	hero_key.omni_range = 9.0
	hero_key.light_color = Color("ffe4bb")
	hero_key.light_energy = 2.0
	add_child(hero_key)
	setup_audio()
	setup_ui()
	show_menu()

func setup_audio() -> void:
	music = AudioStreamPlayer.new()
	var stream: AudioStreamWAV = load("res://Audio/music.wav")
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = stream.data.size() / 2
	music.stream = stream
	add_child(music)
	music.play()
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		voices.append(p)
	apply_volume()

func sfx(key: String) -> void:
	if effects_volume <= .001: return
	var p := voices[voice_index]
	voice_index = (voice_index + 1) % voices.size()
	p.stream = load("res://Audio/" + key + ".wav")
	p.volume_db = linear_to_db(effects_volume)
	p.play()

func apply_volume() -> void:
	music.volume_db = linear_to_db(maxf(.0001,music_volume))
	music.stream_paused = music_volume < .001

func setup_ui() -> void:
	var canvas: CanvasLayer = preload("res://Scenes/UI/GameHUD.tscn").instantiate()
	add_child(canvas)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(root)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var theme := Theme.new()
	theme.default_font_size = 20
	theme.set_color("font_color", "Label", CREAM)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("173b43")
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	theme.set_stylebox("normal", "Button", style)
	var hover := style.duplicate() as StyleBoxFlat
	hover.bg_color = Color("28606a")
	theme.set_stylebox("hover", "Button", hover)
	theme.set_stylebox("pressed", "Button", hover)
	theme.set_color("font_color", "Button", CREAM)
	root.theme = theme
	var score_frame := hud_frame(root, Vector2(16,16), Vector2(184,62))
	hud = Label.new()
	score_frame.add_child(hud)
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hud.add_theme_font_size_override("font_size", 33)
	hud.add_theme_color_override("font_color", Color("fff7e5"))
	var coin_frame := hud_frame(root, Vector2(-245,16), Vector2(150,62), true)
	var token := TextureRect.new()
	coin_frame.add_child(token)
	token.texture = preload("res://Art/UI/token.svg")
	token.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	token.position = Vector2(10,10)
	token.size = Vector2(42,42)
	coin_hud = Label.new()
	coin_frame.add_child(coin_hud)
	coin_hud.position = Vector2(62,8)
	coin_hud.size = Vector2(80,46)
	coin_hud.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	coin_hud.add_theme_font_size_override("font_size", 29)
	distance_hud = Label.new()
	root.add_child(distance_hud)
	distance_hud.position = Vector2(23,82)
	distance_hud.add_theme_font_size_override("font_size",16)
	distance_hud.add_theme_color_override("font_shadow_color",Color("1b2527"))
	distance_hud.add_theme_constant_override("shadow_offset_y",2)
	status = Label.new()
	root.add_child(status)
	status.position = Vector2(23,110)
	status.add_theme_font_size_override("font_size",17)
	status.add_theme_color_override("font_color",CYAN)
	status.add_theme_color_override("font_shadow_color",Color("14252b"))
	status.add_theme_constant_override("shadow_offset_y",2)
	pause_button = Button.new()
	root.add_child(pause_button)
	pause_button.text = "Ⅱ"
	pause_button.add_theme_font_size_override("font_size",32)
	var pause_style := StyleBoxTexture.new()
	pause_style.texture = preload("res://Art/UI/hud-panel.svg")
	pause_style.texture_margin_left = 18
	pause_style.texture_margin_right = 18
	pause_button.add_theme_stylebox_override("normal",pause_style)
	pause_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	pause_button.offset_left = -80
	pause_button.offset_right = -16
	pause_button.offset_top = 16
	pause_button.offset_bottom = 78
	pause_button.pressed.connect(toggle_pause)
	flash = ColorRect.new()
	root.add_child(flash)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.color = Color(1,.7,.15,0)
	overlay = ColorRect.new()
	root.add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(.015,.04,.055,.68)
	var center := CenterContainer.new()
	overlay.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel = PanelContainer.new()
	center.add_child(panel)
	var bg := style.duplicate() as StyleBoxFlat
	bg.bg_color = Color(.025,.09,.115,.97)
	bg.content_margin_left = 36
	bg.content_margin_right = 36
	bg.content_margin_top = 28
	bg.content_margin_bottom = 28
	panel.add_theme_stylebox_override("panel",bg)
	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	panel.add_child(content)

func clear_panel() -> void:
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
	overlay.show()
	pause_button.visible = false

func label_text(text: String, size: int = 20, color: Color = CREAM) -> void:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size",size)
	l.add_theme_color_override("font_color",color)
	content.add_child(l)

func button(text: String, action: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(340,50)
	content.add_child(b)
	b.pressed.connect(func(): sfx("ui"); action.call())

func show_menu() -> void:
	state = "menu"
	drill.play("idle")
	clear_panel()
	label_text("DRILLDROP",46,CYAN)
	label_text(tr("К Р И С Т А Л Ь Н Ы Й   Р Е Й С"),16)
	label_text(tr("Глубже в шахту. Дальше за рекордом."),18)
	label_text(tr("Рекорд  %06d   ·   Монеты  %d") % [best,total_coins],18)
	button(tr("Начать забег  →"),start_run)
	button(tr("Как играть"),show_help)
	button(tr("Звук"),func(): show_settings("menu"))

func show_help() -> void:
	clear_panel()
	label_text(tr("НАЙДИ СВОЙ ПУТЬ"),28,CYAN)
	label_text(tr("← → / A D  —  сменить полосу\n↑ / W / Пробел  —  прыгнуть\n↓ / S  —  подкат    ·    Esc / P  —  пауза"),20)
	label_text(tr("На телефоне — свайпы в четырёх направлениях.\nЯщик: перепрыгни. Балка: скользи под ней.\nВагонетка: обойди по другой полосе.\nГолубой кристалл: щит. Фиолетовый: магнит."),18)
	button(tr("Вперёд!"),start_run)
	button(tr("В меню"),show_menu)

func start_run() -> void:
	elapsed=0
	camera.position.x=0
	distance = 0
	coins = 0
	shield_left = 0
	magnet_left = 0
	immunity = 0
	belt.reset()
	drill.reset()
	state = "run"
	overlay.hide()
	pause_button.show()

func toggle_pause() -> void:
	if state == "run":
		state = "pause"
		if drill.anim: drill.anim.pause()
		clear_panel()
		label_text(tr("ПЕРЕДЫШКА"),34,CYAN)
		button(tr("Продолжить"),resume)
		button(tr("Звук"),func(): show_settings("pause"))
		button(tr("Заново"),start_run)
		button(tr("В меню"),show_menu)
	elif state == "pause": resume()

func resume() -> void:
	state = "run"
	overlay.hide()
	pause_button.show()
	if drill.anim: drill.anim.play()

func show_settings(back: String) -> void:
	clear_panel()
	label_text(tr("ЗВУК"),32,CYAN)
	for key in [tr("Музыка"), tr("Эффекты")]:
		label_text(key + tr("  ·  0 = выключено"),18)
		var slider := HSlider.new()
		slider.max_value = 1
		slider.step = .05
		slider.value = music_volume if key == tr("Музыка") else effects_volume
		slider.custom_minimum_size = Vector2(340,32)
		content.add_child(slider)
		slider.value_changed.connect(func(v):
			if key == tr("Музыка"): music_volume = v
			else: effects_volume = v
			apply_volume()
			save_progress())
	button(tr("Назад"),func():
		if back == "menu": show_menu()
		else:
			_return_to_pause())

func update_presentation(delta: float) -> void:
	fx_left=maxf(0,fx_left-delta)
	flash.color.a=fx_left*.35
	if not runner_effects:
		runner_effects=preload("res://Script/Effects/RunnerEffects.gd").new()
		add_child(runner_effects)
		for key in ["shield","magnet"]:
			var icon=preload("res://Script/UI/BuffIndicator.gd").new()
			icon.kind=key
			icon.tint=Color("55dfff") if key=="shield" else Color("ce6dff")
			pause_button.get_parent().add_child(icon)
			icon.position=Vector2(24+buff_icons.size()*80,128)
			buff_icons.append(icon)
	buff_icons[0].update_time(shield_left,12)
	buff_icons[1].update_time(magnet_left,10)
	runner_effects.tick(delta)
	if state in ["run","boss"]:
		camera.position.x=lerpf(camera.position.x,drill.position.x*.96,1-exp(-12*delta))

func _physics_process(delta: float) -> void:
	if state == "run":
		var speed := run_speed()
		drill.base_speed = speed
		distance += speed * delta
		elapsed += delta
		shield_left = maxf(0,shield_left-delta)
		magnet_left = maxf(0,magnet_left-delta)
		immunity = maxf(0,immunity-delta)
		drill.tick(delta)
		belt.tick(delta,speed)
		camera.fov = lerpf(camera.fov,60+(speed-11)*.35,delta*2)
	hud.text = "%06d" % score()
	coin_hud.text = str(coins)
	distance_hud.text = tr("%d м  ·  Шахта %02d") % [int(distance),1+int(distance/500)]
	status.text = ""
	if state == "run":
		if distance < 65: status.text = tr("← →  полосы    ↑  прыжок    ↓  подкат")

func score() -> int:
	return int(distance * 10) + coins * 50
func collect_coin() -> void:
	coins += 1
	fx_left = .18
	flash.color = Color(1,.75,.2,.08)
	sfx("coin")
func powerup(key: String) -> void:
	var comic=preload("res://Script/UI/ComicImpact.gd").new()
	comic.word=tr("ЩИТ!") if key=="shield" else tr("МАГНИТ!")
	comic.caption=Banter.take(key)
	comic.tint=Color("55dfff") if key=="shield" else Color("d58cff")
	comic.position=Vector2(get_viewport().get_visible_rect().size.x*.5-95,get_viewport().get_visible_rect().size.y*.34)
	var old_comic=pause_button.get_parent().get_node_or_null("ComicCallout")
	if old_comic:
		pause_button.get_parent().remove_child(old_comic)
		old_comic.queue_free()
	comic.name="ComicCallout"
	pause_button.get_parent().add_child(comic)
	if key == "shield": shield_left = 12
	else: magnet_left = 10
	fx_left = .5
	flash.color = Color(.2,1,.9,.2)
	sfx("power")
	if runner_effects: runner_effects.burst(drill.position+Vector3(0,1,0),Color("55dfff") if key=="shield" else Color("ce6dff"))
func hit() -> void:
	if immunity > 0: return
	if shield_left > 0:
		shield_left = 0
		immunity = 1.2
		sfx("power")
		return
	state = "over"
	drill.play("hit")
	sfx("hit")
	fx_left = .8
	flash.color = Color(1,.2,.1,.3)
	best = maxi(best,score())
	total_coins += coins
	save_progress()
	clear_panel()
	label_text(tr("РЕЙС ЗАВЕРШЁН"),30,CYAN)
	label_text("%06d" % score(),46)
	label_text(tr("%d м   ·   %d монет   ·   Рекорд %d") % [int(distance),coins,best],18)
	button(tr("Ещё один рейс  ↻"),start_run)
	button(tr("В меню"),show_menu)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_ESCAPE,KEY_P]: toggle_pause(); return
		if not state in ["run","boss"]: return
		if event.keycode in [KEY_LEFT,KEY_A]: drill.go_left()
		if event.keycode in [KEY_RIGHT,KEY_D]: drill.go_right()
		if event.keycode in [KEY_UP,KEY_W,KEY_SPACE] and drill.jump(): sfx("jump")
		if event.keycode in [KEY_DOWN,KEY_S] and drill.slide(): sfx("slide")
	if not state in ["run","boss"]:
		touch_id=-1
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			touch_start = event.position
			touch_id = event.index
		elif event.index == touch_id: touch_id = -1
	if event is InputEventScreenDrag and event.index == touch_id and state in ["run","boss"]:
		var d: Vector2 = event.position - touch_start
		if d.length() > 45:
			if absf(d.x) > absf(d.y):
				if d.x > 0: drill.go_right()
				else: drill.go_left()
			elif d.y < 0:
				if drill.jump(): sfx("jump")
			else:
				if drill.slide(): sfx("slide")
			touch_id = -1

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and state == "run": toggle_pause()
	if what == NOTIFICATION_WM_CLOSE_REQUEST: shutdown()
func save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress","best",best)
	cfg.set_value("progress","coins",total_coins)
	cfg.set_value("audio","music",music_volume)
	cfg.set_value("audio","effects",effects_volume)
	cfg.save(save_path)
func load_progress() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(save_path) == OK:
		best = maxi(0,int(cfg.get_value("progress","best",0)))
		total_coins = maxi(0,int(cfg.get_value("progress","coins",0)))
		music_volume = clampf(float(cfg.get_value("audio","music",.35)),0,1)
		effects_volume = clampf(float(cfg.get_value("audio","effects",.65)),0,1)

func _exit_tree() -> void:
	if is_instance_valid(music):
		music.stop()
		music.stream = null
	for p in voices:
		p.stop()
		p.stream = null

func shutdown() -> void:
	state = "closing"
	_exit_tree()
	await get_tree().create_timer(.1).timeout
	get_tree().quit()

func hud_frame(parent: Control, at: Vector2, dimensions: Vector2, right: bool = false) -> TextureRect:
	var frame := TextureRect.new()
	parent.add_child(frame)
	frame.texture = preload("res://Art/UI/hud-panel.svg")
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if right:
		frame.anchor_left = 1
		frame.anchor_right = 1
	frame.offset_left = at.x
	frame.offset_top = at.y
	frame.offset_right = at.x + dimensions.x
	frame.offset_bottom = at.y + dimensions.y
	return frame

func run_speed() -> float:
	return minf(20,11 + distance / 240)

func _return_to_pause() -> void:
	state="run"
	toggle_pause()
