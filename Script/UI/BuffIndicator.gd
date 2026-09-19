extends Control
const ICONS={"shield":preload("res://Art/UI/Pickups/shield.svg"),"magnet":preload("res://Art/UI/Pickups/magnet.svg")}
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
	var icon: Texture2D=ICONS[kind]
	draw_texture_rect(icon,Rect2(c-Vector2(23,23),Vector2(46,46)),false)
	var text:=tr("%dс") % ceili(remaining)
	var font:=ThemeDB.fallback_font
	draw_string(font,Vector2(36-font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,17).x/2,80),text,HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color.WHITE)
