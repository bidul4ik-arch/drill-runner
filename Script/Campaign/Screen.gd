extends Node3D
@export var screen := "menu"
var scene_camera: Camera3D
var hero: Node3D
var ui: VBoxContainer
var heading: Label
var message: Label
var preview := ""
var rotating := false
var sheet: PanelContainer
var nav_buttons: Dictionary={}
var shop_catalog := false
var page := ""
var menu_music: AudioStreamPlayer
var click_audio: AudioStreamPlayer
func _ready() -> void:
	menu_music=AudioStreamPlayer.new();add_child(menu_music)
	menu_music.stream=preload("res://Audio/music.wav");menu_music.pitch_scale=.85
	menu_music.finished.connect(func(): menu_music.play())
	click_audio=AudioStreamPlayer.new();add_child(click_audio);click_audio.stream=preload("res://Audio/ui.wav")
	Profile.changed.connect(sync_audio)
	sync_audio();menu_music.play()
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
	if screen!="home":
		for i in range(1,4):
			var backdrop=preload("res://Art/Models/track.glb").instantiate()
			backdrop.position.z=-24*i
			add_child(backdrop)
		env.fog_enabled=true;env.fog_density=.022;env.fog_light_color=Color("90704e");env.background_color=Color("90704e")
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
	sun.shadow_enabled=not OS.has_feature("mobile")
	sun.light_angular_distance=.65
	add_child(sun)
	var camera := Camera3D.new()
	scene_camera=camera
	add_child(camera)
	camera.position=Vector3(0,2.3,5.8)
	camera.look_at(Vector3(0,1.05,0))
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
	var atmosphere=preload("res://Script/UI/MenuAtmosphere.gd").new()
	root.add_child(atmosphere)
	atmosphere.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.theme=menu_theme()
	var brand:=Label.new()
	root.add_child(brand)
	brand.text="DRILLDROP"
	brand.position=Vector2(26,26)
	brand.add_theme_font_size_override("font_size",42)
	brand.add_theme_color_override("font_color",Color("ffdb72"))
	brand.add_theme_constant_override("outline_size",8)
	brand.add_theme_color_override("font_outline_color",Color("122a35"))
	var sub:=Label.new()
	root.add_child(sub)
	sub.text=tr("КРИСТАЛЬНЫЙ РЕЙС")
	sub.position=Vector2(29,78)
	sub.add_theme_font_size_override("font_size",14)
	sheet = PanelContainer.new()
	root.add_child(sheet)
	sheet.anchor_top=.46
	sheet.anchor_bottom=1
	sheet.anchor_right=1
	sheet.offset_left=18
	sheet.offset_right=-18
	sheet.offset_bottom=-108
	var style := StyleBoxFlat.new()
	style.bg_color=Color(.035,.10,.12,.91)
	style.border_color=Color("527276")
	style.set_border_width_all(2)
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
	var dock:=HBoxContainer.new()
	root.add_child(dock)
	dock.anchor_top=1;dock.anchor_bottom=1;dock.anchor_right=1
	dock.offset_left=18;dock.offset_right=-18;dock.offset_top=-92;dock.offset_bottom=-18
	dock.add_theme_constant_override("separation",8)
	for item in [["Главная", "menu"],["Уровни","levels"],["Магазин","shop"],["Домик","home"]]:
		var tab:=Button.new();tab.text=tr(item[0]);tab.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		dock.add_child(tab)
		var target: String=item[1]
		nav_buttons[target]=tab
		tab.icon=load("res://Art/UI/Nav/"+target+".svg")
		tab.add_theme_font_size_override("font_size",16)
		tab.pressed.connect(func(): click_audio.play();navigate(target))
	show_page()
func clear() -> void:
	var active: String="home" if page=="wardrobe" else "menu" if page=="settings" else page
	for key in nav_buttons:
		nav_buttons[key].add_theme_stylebox_override("normal",panel_style(Color("32606a") if key==active else Color("204956"),Color("ffdb72") if key==active else Color("507985")))
	sheet.modulate.a=.65
	create_tween().tween_property(sheet,"modulate:a",1.0,.18)
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
	b.pressed.connect(func(): click_audio.play();call.call())
func wallet() -> void:
	text(tr("Монеты: %d") % Profile.data.coins,18)
func show_page() -> void:
	page=screen
	sheet.anchor_top=1.0 if screen=="menu" else .46
	sheet.offset_top=-442 if screen=="menu" else 0
	if scene_camera:
		scene_camera.position=Vector3(0,2.3,5.8)
		scene_camera.look_at(Vector3(0,1.05,0))
	clear()
	wallet()
	match screen:
		"menu":
			text(tr("Твой следующий забег"),20)
			button(tr("Играть")+"  ▶",func():
				var id:=int(Profile.data.checkpoint)
				Flow.start_level(id if id>0 else int(Profile.data.last_level),id>0,true))
			var play_button=ui.get_child(ui.get_child_count()-1)
			play_button.add_theme_color_override("font_color",Color("152f38"))
			play_button.add_theme_stylebox_override("normal",panel_style(Color("ffd467"),Color("ffedaa")))
			play_button.custom_minimum_size.y=72
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
			button(tr("Гардероб"),func(): wardrobe(false))
			button(tr("Магазин"),func(): wardrobe(true))
			button(tr("Следующий уровень"),func(): Flow.go("res://Scenes/Screens/LevelSelect.tscn"))
			button(tr("В меню"),func(): Flow.go("res://Scenes/Screens/MainMenu.tscn"))
func wardrobe(as_shop: bool = false) -> void:
	page="shop" if as_shop else "wardrobe"
	shop_catalog=as_shop
	sheet.anchor_top=.42
	sheet.offset_top=0
	scene_camera.position=Vector3(0,2.3,7.8)
	scene_camera.look_at(Vector3(0,-1.1,0))
	clear()
	wallet()
	text(tr("Магазин") if shop_catalog else tr("ГАРДЕРОБ"),28)
	button(tr("Без кепки") if Profile.data.cap else tr("Кепка"),func(): Profile.data.cap=not Profile.data.cap;Profile.save();Profile.apply_skin(hero,preview);wardrobe(shop_catalog))
	var grid:=GridContainer.new()
	grid.columns=2
	grid.add_theme_constant_override("h_separation",12)
	grid.add_theme_constant_override("v_separation",12)
	ui.add_child(grid)
	for item in Profile.skins:
		if not shop_catalog and not item.id in Profile.data.owned:continue
		var cell:=VBoxContainer.new()
		grid.add_child(cell)
		var card=preload("res://Script/UI/SkinCard.gd").new()
		card.skin_id=item.id
		cell.add_child(card)
		card.pressed.connect(func(): preview=item.id; Profile.apply_skin(hero,preview); toast(tr(item.name)))
		var caption:=Label.new()
		caption.text=tr(item.name)+("  ✓" if item.id in Profile.data.owned else "")
		caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		cell.add_child(caption)
		var price_tag=preload("res://Script/UI/PriceTag.gd").new()
		price_tag.price=int(item.price)
		cell.add_child(price_tag)
		var choose:=Button.new()
		choose.text=tr("Надето") if item.id==Profile.data.skin else tr("Надеть") if item.id in Profile.data.owned else tr("Купить")
		choose.disabled=item.id==Profile.data.skin
		choose.custom_minimum_size.y=42
		cell.add_child(choose)
		choose.pressed.connect(func():
			if item.id in Profile.data.owned:
				Profile.select_skin(item.id)
				Profile.apply_skin(hero)
				wardrobe(shop_catalog)
			else:
				var result:=Profile.buy_skin(item.id)
				wardrobe(shop_catalog)
				toast(result))
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
					toast(result))
	if Profile.test_store:
		for tx in Profile.data.test_pending:
			button(tr("Подтвердить отложенную (тест)"),func():
				StoreBridge.test_purchase(Profile.data.test_pending[tx],"verified",tx)
				store())
	button(tr("Назад"),wardrobe)
func settings() -> void:
	page="settings"
	sheet.anchor_top=.42
	sheet.offset_top=0
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
	if what==NOTIFICATION_WM_GO_BACK_REQUEST:
		if page in ["settings","shop","wardrobe"]:show_page()
		elif screen!="menu":navigate("menu")
		else:Profile.save()

func navigate(target: String) -> void:
	Profile.apply_skin(hero)
	if target=="shop":wardrobe(true);return
	if target=="home" and screen!="home":Flow.go("res://Scenes/Screens/Home.tscn");return
	if screen=="home" and target!="home":
		Flow.go("res://Scenes/Screens/LevelSelect.tscn" if target=="levels" else "res://Scenes/Screens/MainMenu.tscn");return
	screen=target
	show_page()
func panel_style(color: Color, border: Color) -> StyleBoxFlat:
	var style:=StyleBoxFlat.new()
	style.bg_color=color;style.border_color=border;style.set_border_width_all(2);style.set_corner_radius_all(16)
	style.content_margin_left=12;style.content_margin_right=12;style.content_margin_top=8;style.content_margin_bottom=8
	style.shadow_color=Color(0,0,0,.3);style.shadow_size=4;style.shadow_offset=Vector2(0,4)
	return style
func menu_theme() -> Theme:
	var theme:=Theme.new()
	theme.default_font_size=18
	theme.set_stylebox("normal","Button",panel_style(Color("204956"),Color("507985")))
	theme.set_stylebox("hover","Button",panel_style(Color("2c6571"),Color("6deddf")))
	theme.set_stylebox("pressed","Button",panel_style(Color("173643"),Color("ffce68")))
	theme.set_stylebox("focus","Button",panel_style(Color(0,0,0,0),Color("ffe090")))
	theme.set_color("font_color","Button",Color("fff3d4"))
	return theme

func sync_audio() -> void:
	if menu_music:menu_music.volume_db=linear_to_db(maxf(.0001,float(Profile.data.music)*.32))
	if click_audio:click_audio.volume_db=linear_to_db(maxf(.0001,float(Profile.data.effects)*.5))

func toast(value: String) -> void:
	var previous=sheet.get_parent().get_node_or_null("ShopToast")
	if previous:previous.queue_free();previous.name="ExpiredToast"
	var bubble:=PanelContainer.new();bubble.name="ShopToast";sheet.get_parent().add_child(bubble)
	bubble.mouse_filter=Control.MOUSE_FILTER_IGNORE
	bubble.anchor_top=.32;bubble.anchor_right=1
	bubble.offset_left=64;bubble.offset_right=-64
	bubble.add_theme_stylebox_override("panel",panel_style(Color("173d48"),Color("ffdc7d")))
	var note:=Label.new();note.text=value;note.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;note.custom_minimum_size.y=44
	note.mouse_filter=Control.MOUSE_FILTER_IGNORE;bubble.add_child(note)
	var fade:=bubble.create_tween();fade.tween_interval(1.6);fade.tween_property(bubble,"modulate:a",0.0,.25);fade.tween_callback(bubble.queue_free)
