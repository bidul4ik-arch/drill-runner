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
var lobby: Control
var lobby_art: TextureRect
var wallet_label: Label
var reward_badge: Button
var daily_badge: Button
var reward_modal: PanelContainer
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
	env.ssao_enabled=preload("res://Script/Services/Graphics.gd").renderer()=="forward_plus"
	env.ssao_radius=.5
	env.ssao_intensity=1.5
	env.glow_enabled=preload("res://Script/Services/Graphics.gd").renderer()!="gl_compatibility"
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
	lobby_art=TextureRect.new();root.add_child(lobby_art);root.move_child(lobby_art,0)
	lobby_art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	lobby_art.texture=load("res://Art/UI/Lobby/menu.png")
	lobby_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lobby_art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;lobby_art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	lobby_art.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var top:=HBoxContainer.new();root.add_child(top)
	top.anchor_right=1;top.offset_left=18;top.offset_top=18;top.offset_right=-18;top.offset_bottom=76
	var back:=Button.new();back.icon=preload("res://Art/UI/Nav/menu.svg");back.custom_minimum_size=Vector2(58,58);top.add_child(back)
	back.pressed.connect(func():navigate("menu"))
	var purse_center:=CenterContainer.new();purse_center.size_flags_horizontal=Control.SIZE_EXPAND_FILL;top.add_child(purse_center)
	var purse:=HBoxContainer.new();purse_center.add_child(purse)
	var token:=TextureRect.new();token.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;token.texture=preload("res://Art/UI/token.svg");token.custom_minimum_size=Vector2(32,32);token.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;purse.add_child(token)
	wallet_label=Label.new();wallet_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	wallet_label.add_theme_color_override("font_outline_color",Color("142d3c"));wallet_label.add_theme_font_size_override("font_size",27);wallet_label.add_theme_constant_override("outline_size",6);purse.add_child(wallet_label)
	var gear:=Button.new();gear.icon=preload("res://Art/UI/Nav/settings.svg");gear.custom_minimum_size=Vector2(58,58);top.add_child(gear);gear.pressed.connect(settings)
	Profile.changed.connect(update_lobby);Goals.updated.connect(_goals_updated)
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
	dock.offset_left=18;dock.offset_right=-18;dock.offset_top=-106;dock.offset_bottom=-18
	dock.add_theme_constant_override("separation",8)
	for item in [["Задания", "missions"],["Домик","home"],["Магазин","shop"],["Награды","achievements"]]:
		var tab:=Button.new();tab.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		dock.add_child(tab)
		var target: String=item[1]
		nav_buttons[target]=tab
		var stack:=VBoxContainer.new();tab.add_child(stack);stack.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);stack.offset_top=8;stack.offset_bottom=-6;stack.mouse_filter=Control.MOUSE_FILTER_IGNORE
		var icon:=TextureRect.new();icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.texture=load("res://Art/UI/Nav/"+target+".svg");icon.custom_minimum_size.y=38;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.mouse_filter=Control.MOUSE_FILTER_IGNORE;stack.add_child(icon)
		var caption:=Label.new();caption.text=tr(item[0]);caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;caption.add_theme_font_size_override("font_size",17);caption.mouse_filter=Control.MOUSE_FILTER_IGNORE;stack.add_child(caption)
		tab.add_theme_font_size_override("font_size",16)
		tab.pressed.connect(func(): click_audio.play();navigate(target))
	build_lobby(root)
	if screen=="menu" and not Flow.menu_page.is_empty():screen=Flow.menu_page;Flow.menu_page=""
	show_page()
func clear() -> void:
	if lobby:lobby.visible=page=="menu"
	if lobby_art:lobby_art.visible=page in ["menu","missions","achievements","settings"]
	sheet.visible=page!="menu"
	for model in get_children():
		if model is Node3D and not model is Camera3D:model.visible=not lobby_art.visible
	update_lobby()
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
			pass
		"missions","achievements":
			goals_page(screen=="missions")
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
			button(tr("Играть"),play_next)
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
	button(tr("Выбор уровня"),func():screen="levels";show_page())
	button(tr("Назад"),show_page)
func _unhandled_input(event: InputEvent) -> void:
	if screen!="home": return
	if event is InputEventScreenDrag and event.position.y<get_viewport().get_visible_rect().size.y*.46: hero.rotation.y+=event.relative.x*.01
	if event is InputEventMouseButton: rotating=event.pressed
	if event is InputEventMouseMotion and rotating: hero.rotation.y+=event.relative.x*.01
func _notification(what: int) -> void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT: Profile.save()
	if what==NOTIFICATION_WM_GO_BACK_REQUEST:
		if is_instance_valid(reward_modal):reward_modal.queue_free();return
		if page in ["settings","shop","wardrobe"]:show_page()
		elif page in ["missions","achievements"]:navigate("menu")
		elif screen!="menu":navigate("menu")
		else:Profile.save()

func navigate(target: String) -> void:
	Profile.apply_skin(hero)
	if target=="shop":wardrobe(true);return
	if target=="home" and screen!="home":Flow.go("res://Scenes/Screens/Home.tscn");return
	if screen=="home" and target!="home":
		Flow.menu_page=target
		Flow.go("res://Scenes/Screens/MainMenu.tscn");return
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
	theme.set_stylebox("disabled","Button",panel_style(Color("516b7b"),Color("718a98")))
	theme.set_color("font_disabled_color","Button",Color("d8e4ec"))
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

func play_next() -> void:
	if Flow.busy:return
	var id:=int(Profile.data.unlocked)
	var saved: Dictionary=Profile.data.suspended_run
	if not saved.is_empty():id=int(saved.level)
	Flow.auto_start=true
	if id==0:Flow.go("res://Scenes/Levels/Endless.tscn")
	else:Flow.start_level(id,int(Profile.data.checkpoint)==id,true)
func build_lobby(root: Control) -> void:
	lobby=Control.new();root.add_child(lobby);lobby.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lobby.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var brand:=Label.new();lobby.add_child(brand);brand.text="DRILLDROP"
	brand.anchor_left=.18;brand.anchor_right=.82;brand.offset_top=90;brand.offset_bottom=132
	brand.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;brand.add_theme_font_size_override("font_size",34)
	brand.add_theme_color_override("font_outline_color",Color("142d3c"));brand.add_theme_color_override("font_color",Color("ffdc83"));brand.add_theme_constant_override("outline_size",8)
	var record:=Label.new();record.name="Best";lobby.add_child(record)
	record.position=Vector2(22,146);record.add_theme_color_override("font_outline_color",Color("142d3c"));record.add_theme_font_size_override("font_size",20);record.add_theme_constant_override("outline_size",6)
	daily_badge=Button.new();lobby.add_child(daily_badge);daily_badge.position=Vector2(20,213);daily_badge.custom_minimum_size=Vector2(142,68)
	daily_badge.icon=preload("res://Art/UI/Nav/missions.svg");daily_badge.pressed.connect(func():navigate("missions"))
	reward_badge=Button.new();lobby.add_child(reward_badge);reward_badge.anchor_left=1;reward_badge.anchor_right=1
	reward_badge.offset_left=-182;reward_badge.offset_right=-20;reward_badge.offset_top=213;reward_badge.offset_bottom=281
	reward_badge.icon=preload("res://Art/UI/Nav/achievements.svg");reward_badge.pressed.connect(func():navigate("achievements"))
	var play:=Button.new();lobby.add_child(play);play.name="Play";play.text=tr("Коснись, чтобы играть")
	play.anchor_top=1;play.anchor_bottom=1;play.anchor_right=1
	play.offset_left=54;play.offset_right=-54;play.offset_top=-260;play.offset_bottom=-178
	play.add_theme_font_size_override("font_size",26);play.add_theme_color_override("font_color",Color("17343c"))
	play.add_theme_stylebox_override("normal",panel_style(Color("ffd36b"),Color("fff2c7")));play.pressed.connect(play_next)
	var endless:=Button.new();lobby.add_child(endless);endless.text=tr("Бесконечный режим")
	endless.anchor_top=1;endless.anchor_bottom=1;endless.anchor_left=.22;endless.anchor_right=.78
	endless.offset_top=-163;endless.offset_bottom=-119
	endless.pressed.connect(func():Flow.auto_start=true;Flow.go("res://Scenes/Levels/Endless.tscn"))
	update_lobby()
func update_lobby() -> void:
	if wallet_label:wallet_label.text="%s"%Profile.data.coins
	if not lobby:return
	lobby.get_node("Best").text=tr("Рекорд")+"  %06d"%int(Profile.data.best)
	daily_badge.text=tr("Задания")+("  ●" if Goals.available(true)>0 else "")
	reward_badge.text=tr("Награды")+("  ●" if Goals.available(false)>0 else "")
func goals_page(daily: bool) -> void:
	page="missions" if daily else "achievements"
	sheet.anchor_top=.20;sheet.offset_top=0;clear()
	text(tr("ЕЖЕДНЕВНЫЕ ЗАДАНИЯ") if daily else tr("ДОСТИЖЕНИЯ"),25)
	if daily:
		var timer:=text(tr("Новые задания каждый день"),16);timer.name="DailyReset"
	for item in Goals.entries(daily):
		var row:=PanelContainer.new();ui.add_child(row)
		row.add_theme_stylebox_override("panel",panel_style(Color("dfebf3"),Color("9bbbd0")))
		var stack:=VBoxContainer.new();row.add_child(stack)
		var title:=Label.new();title.text=tr(item.title);title.add_theme_color_override("font_color",Color("203949"));title.add_theme_font_size_override("font_size",21);stack.add_child(title)
		var bar:=ProgressBar.new();bar.max_value=int(item.target);bar.value=Goals.progress(item,daily);bar.show_percentage=false;bar.custom_minimum_size.y=28;stack.add_child(bar)
		bar.add_theme_stylebox_override("background",panel_style(Color("203c53"),Color("6b899d")))
		bar.add_theme_stylebox_override("fill",panel_style(Color("65b943"),Color("a8e67c")))
		var count:=Label.new();bar.add_child(count);count.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);count.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;count.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
		count.text="%d / %d"%[Goals.progress(item,daily),int(item.target)];count.add_theme_color_override("font_outline_color",Color("203c53"));count.add_theme_constant_override("outline_size",3)
		var claim:=Button.new();stack.add_child(claim);claim.custom_minimum_size.y=42
		claim.text=tr("Получено") if Goals.claimed(item.id,daily) else tr("Забрать")+"   ◈ %d"%int(item.reward)
		claim.disabled=Goals.claimed(item.id,daily) or Goals.progress(item,daily)<int(item.target)
		claim.pressed.connect(func():
			var earned:=Goals.claim(item.id,daily)
			goals_page(daily)
			if earned>0:reward_popup(earned))
	button(tr("Главная"),func():navigate("menu"))
func reward_popup(amount: int) -> void:
	var modal:=PanelContainer.new();reward_modal=modal;sheet.get_parent().add_child(modal)
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_theme_stylebox_override("panel",panel_style(Color("12678b"),Color("76dafa")))
	var center:=CenterContainer.new();modal.add_child(center);var stack:=VBoxContainer.new();center.add_child(stack)
	var coin=preload("res://Script/UI/RewardCoin.gd").new();stack.add_child(coin)
	var title:=Label.new();title.text=tr("НАГРАДА!");title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;title.add_theme_font_size_override("font_size",42);stack.add_child(title)
	var label:=Label.new();label.text=tr("Монеты: %d")%amount;label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.add_theme_font_size_override("font_size",30);stack.add_child(label)
	var done:=Button.new();done.text=tr("Продолжить");done.custom_minimum_size=Vector2(280,64);stack.add_child(done);done.pressed.connect(modal.queue_free)

func _goals_updated() -> void:
	update_lobby()
	if page in ["missions","achievements"]:goals_page(page=="missions")

func _process(_delta: float) -> void:
	if page!="missions" or not ui:return
	var label=ui.get_node_or_null("DailyReset")
	if label:
		var now:=Time.get_datetime_dict_from_system()
		var left:=86400-int(now.hour)*3600-int(now.minute)*60-int(now.second)
		label.text=tr("Обновление через %02d:%02d:%02d")%[left/3600,(left%3600)/60,left%60]
