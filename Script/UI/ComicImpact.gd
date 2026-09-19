extends Control
var word:=tr("БАМ!")
var tint:=Color("ffd752")
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	size=Vector2(190,110);pivot_offset=size/2
	var label:=Label.new();add_child(label)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.text=word;label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size",31)
	label.add_theme_color_override("font_color",Color("fff7d3"));label.add_theme_color_override("font_outline_color",Color("172b35"));label.add_theme_constant_override("outline_size",9)
	rotation=randf_range(-.12,.12);scale=Vector2(.35,.35)
	var tween:=create_tween();tween.tween_property(self,"scale",Vector2(1.12,1.12),.09);tween.tween_property(self,"scale",Vector2.ONE,.1)
	tween.tween_interval(.32);tween.tween_property(self,"modulate:a",0,.20);tween.tween_callback(queue_free)
	var drift:=create_tween();drift.tween_property(self,"position:y",position.y-34,.7)
func _draw() -> void:
	var points:=PackedVector2Array()
	for i in 24:
		var a:=i*TAU/24
		var r:=1.0 if i%2==0 else .72
		points.append(Vector2(95,55)+Vector2(cos(a)*94,sin(a)*53)*r)
	draw_colored_polygon(points,tint);points.append(points[0]);draw_polyline(points,Color("172b35"),3,true)
