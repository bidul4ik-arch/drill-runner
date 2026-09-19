extends Node3D
@export var screen := "menu"
var scene_camera: Camera3D
var hero: Node3D
var ui: VBoxContainer
var heading: Label
var message: Label
var preview := ""
var rotating := false
func _ready() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode=Environment.BG_COLOR
	env.background_color=Color("233d46")
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color=Color("e4d4af")
	env.ambient_light_energy=.4
	env.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	env.ssao_enabled=ProjectSettings.get_setting_with_override("rendering/renderer/rendering_method")=="forward_plus"
	env.ssao_radius=.5
	env.ssao_intensity=1.5
	env.glow_enabled=ProjectSettings.get_setting_with_override("rendering/renderer/rendering_method")!="gl_compatibility"
	world.environment=env
	add_child(world)
	var room: Node3D=load("res://Art/Models/home.glb" if screen=="home" else "res://Art/Models/track.glb").instantiate()
	add_child(room)
	hero=preload("res://Art/Models/explorer.glb").instantiate()
	add_child(hero)
	hero.rotation.y=PI
	Profile.apply_skin(hero)
	var anim: AnimationPlayer=hero.find_child("AnimationPlayer",true,false)
	if anim:
		anim.get_animation("idle").loop_mode=Animation.LOOP_LINEAR
		anim.play("idle")
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-45,-25,0)
	sun.light_energy=.8
	sun.shadow_enabled=true
	sun.light_angular_distance=.65
	add_child(sun)
	var camera := Camera3D.new()
	scene_camera=camera
	add_child(camera)
	camera.position=Vector3(0,3.1,7.4)
	camera.look_at(Vector3(0,.2,0))
	camera.fov=48
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var root := Control.new()
	canvas.add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter=Control.MOUSE_FILTER_IGNORE
	if OS.has_feature("mobile"):
		var safe:=DisplayServer.get_display_safe_area()
		var window:=DisplayServer.window_get_size()
		var ratio:=get_viewport().get_visible_rect().size.y/maxf(1,window.y)
		root.offset_top=maxf(0,safe.position.y)*ratio
		root.offset_bottom=-maxf(0,window.y-safe.end.y)*ratio
	var sheet := PanelContainer.new()
	root.add_child(sheet)
	sheet.anchor_top=.46
	sheet.anchor_bottom=1
	sheet.anchor_right=1
	sheet.offset_left=18
	sheet.offset_right=-18
	sheet.offset_bottom=-24
	var style := StyleBoxFlat.new()
	style.bg_color=Color(.035,.10,.12,.97)
	style.set_corner_radius_all(18)
	style.content_margin_left=24
	style.content_margin_right=24
	style.content_margin_top=16
	style.content_margin_bottom=16
	sheet.add_theme_stylebox_override("panel",style)
	var scroll := ScrollContainer.new()
	sheet.add_child(scroll)
	ui=VBoxContainer.new()
	ui.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	ui.add_theme_constant_override("separation",10)
	scroll.add_child(ui)
	show_page()
func clear() -> void:
	for child in ui.get_children():
		ui.remove_child(child)
		child.queue_free()
func text(value: String, size: int = 22) -> Label:
	var l := Label.new()
	l.text=value
	l.add_theme_font_size_override("font_size",size)
	l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x=300
	ui.add_child(l)
	return l
func button(value: String, call: Callable, disabled: bool = false) -> void:
	var b := Button.new()
	b.text=value
	b.custom_minimum_size.y=54
	b.add_theme_font_size_override("font_size",21)
	b.disabled=disabled
	ui.add_child(b)
	b.pressed.connect(call)
func wallet() -> void:
	text(tr("Монеты: %d") % Profile.data.coins,18)
func show_page() -> void:
	if scene_camera:
		scene_camera.position=Vector3(0,3.1,7.4)
		scene_camera.look_at(Vector3(0,.2,0))
	clear()
	wallet()
	match screen:
		"menu":
			text("DRILLDROP",36)
			button(tr("Продолжить") if Profile.data.started else tr("Начать игру"),func():
				var id:=int(Profile.data.checkpoint)
				Flow.start_level(id if id>0 else int(Profile.data.last_level),id>0,true))
			button(tr("Уровни"),func(): Flow.go("res://Scenes/Screens/LevelSelect.tscn"))
			button(tr("Домик"),func(): Flow.go("res://Scenes/Screens/Home.tscn"))
			button(tr("Бесконечный режим"),func(): Flow.go("res://Scenes/Levels/Endless.tscn"))
			button(tr("Настройки"),settings)
		"levels":
			text(tr("ВЫБОР УРОВНЯ"),28)
			for item in Profile.levels:
				var id:=int(item.id)
				button("%d · %s %s" % [id,tr(item.title),"✓" if id in Profile.data.completed else ""],func(): Flow.start_level(id),id>int(Profile.data.unlocked))
			if int(Profile.data.checkpoint)>0:
				button(tr("Продолжить с босса"),func(): Flow.start_level(int(Profile.data.checkpoint),true))
			button(tr("В меню"),func(): Flow.go("res://Scenes/Screens/MainMenu.tscn"))
		"home":
			text(tr("ДОМИК"),27)
			text("↔",17)
			button(tr("Повернуть героя ↻"),func(): hero.rotation.y+=.5)
			button(tr("Гардероб"),wardrobe)
			button(tr("Следующий уровень"),func(): Flow.go("res://Scenes/Screens/LevelSelect.tscn"))
			button(tr("В меню"),func(): Flow.go("res://Scenes/Screens/MainMenu.tscn"))
func wardrobe() -> void:
	scene_camera.position=Vector3(0,2.3,7.8)
	scene_camera.look_at(Vector3(0,-1.1,0))
	clear()
	wallet()
	text(tr("ГАРДЕРОБ"),28)
	button(tr("Без кепки") if Profile.data.cap else tr("Кепка"),func(): Profile.data.cap=not Profile.data.cap;Profile.save();Profile.apply_skin(hero,preview);wardrobe())
	var grid:=GridContainer.new()
	grid.columns=2
	grid.add_theme_constant_override("h_separation",12)
	grid.add_theme_constant_override("v_separation",12)
	ui.add_child(grid)
	for item in Profile.skins:
		var cell:=VBoxContainer.new()
		grid.add_child(cell)
		var card=preload("res://Script/UI/SkinCard.gd").new()
		card.skin_id=item.id
		cell.add_child(card)
		card.pressed.connect(func(): preview=item.id; Profile.apply_skin(hero,preview))
		var caption:=Label.new()
		caption.text=tr(item.name)+("  ✓" if item.id in Profile.data.owned else "")
		caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		cell.add_child(caption)
		var price_tag=preload("res://Script/UI/PriceTag.gd").new()
		price_tag.price=int(item.price)
		cell.add_child(price_tag)
		var choose:=Button.new()
		choose.text=tr("Надеть") if item.id in Profile.data.owned else tr("Купить")
		choose.custom_minimum_size.y=42
		cell.add_child(choose)
		choose.pressed.connect(func():
			if item.id in Profile.data.owned:
				Profile.select_skin(item.id)
				Profile.apply_skin(hero)
				wardrobe()
			else:
				var result:=Profile.buy_skin(item.id)
				wardrobe()
				text(result,18))
	button(tr("Назад"),func(): Profile.apply_skin(hero); show_page())
func store() -> void:
	clear()
	wallet()
	text(tr("ТЕСТОВЫЙ МАГАЗИН") if Profile.test_store else tr("МАГАЗИН НЕДОСТУПЕН"),26)
	text(tr("Тестовый режим: реальные деньги не списываются.") if Profile.test_store else tr("Не подключены магазин платформы и сервер проверки. Платежи отключены."),18)
	if Profile.test_store:
		for pack in StoreBridge.config.packages:
			for outcome in ["verified","cancelled","pending","failed"]:
				button(tr("%d ◆ · %s (тест)") % [pack.amount,outcome],func():
					var result:=StoreBridge.test_purchase(pack.id,outcome,str(Time.get_unix_time_from_system())+str(randi()))
					store()
					text(result,18))
	if Profile.test_store:
		for tx in Profile.data.test_pending:
			button(tr("Подтвердить отложенную (тест)"),func():
				StoreBridge.test_purchase(Profile.data.test_pending[tx],"verified",tx)
				store())
	button(tr("Назад"),wardrobe)
func settings() -> void:
	clear()
	text(tr("НАСТРОЙКИ"),28)
	for key in ["music","effects"]:
		text(tr("Музыка") if key=="music" else tr("Эффекты"),20)
		var slider:=HSlider.new()
		slider.max_value=1
		slider.step=.05
		slider.value=Profile.data[key]
		slider.custom_minimum_size.y=44
		ui.add_child(slider)
		slider.value_changed.connect(func(v): Profile.data[key]=v; Profile.save())
	button(tr("Вибрация: ")+(tr("вкл") if Profile.data.vibration else tr("выкл")),func(): Profile.data.vibration=not Profile.data.vibration;Profile.save();settings())
	button(tr("Качество: ")+(tr("60 FPS / тени") if int(Profile.data.quality)==1 else tr("30 FPS / экономно")),func(): Profile.data.quality=1-int(Profile.data.quality);Profile.save();settings())
	button(tr("Назад"),show_page)
func _unhandled_input(event: InputEvent) -> void:
	if screen!="home": return
	if event is InputEventScreenDrag and event.position.y<get_viewport().get_visible_rect().size.y*.46: hero.rotation.y+=event.relative.x*.01
	if event is InputEventMouseButton: rotating=event.pressed
	if event is InputEventMouseMotion and rotating: hero.rotation.y+=event.relative.x*.01
func _notification(what: int) -> void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT: Profile.save()
