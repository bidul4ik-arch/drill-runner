extends Control
var remaining:=0.0
var duration:=1.0
var kind:="shield"
var tint:=Color("58e8ed")
func _ready() -> void:
	custom_minimum_size=Vector2(72,82)
	size=custom_minimum_size
	mouse_filter=Control.MOUSE_FILTER_IGNORE
func update_time(value: float, maximum: float) -> void:
	remaining=value;duration=maximum;visible=value>0;queue_redraw()
func _draw() -> void:
	var c:=Vector2(36,34)
	draw_circle(c,31,Color("152e38"))
	draw_arc(c,30,-PI/2,3*PI/2,64,Color("345563"),3,true)
	draw_arc(c,30,-PI/2,-PI/2+TAU*clampf(remaining/duration,0,1),64,tint,4,true)
	if kind=="shield":
		var p:=PackedVector2Array([c+Vector2(-13,-13),c+Vector2(0,-17),c+Vector2(13,-13),c+Vector2(11,6),c+Vector2(0,16),c+Vector2(-11,6),c+Vector2(-13,-13)])
		draw_colored_polygon(p,Color(tint,.25));draw_polyline(p,tint,3,true)
	else:
		draw_arc(c+Vector2(0,4),11,0,PI,24,tint,7,true)
		draw_line(c+Vector2(-11,4),c+Vector2(-11,-12),tint,7,true)
		draw_line(c+Vector2(11,4),c+Vector2(11,-12),tint,7,true)
		draw_line(c+Vector2(-11,-10),c+Vector2(-11,-16),Color.WHITE,7,true)
		draw_line(c+Vector2(11,-10),c+Vector2(11,-16),Color.WHITE,7,true)
	var text:=tr("%dс") % ceili(remaining)
	var font:=ThemeDB.fallback_font
	draw_string(font,Vector2(36-font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,17).x/2,80),text,HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color.WHITE)
