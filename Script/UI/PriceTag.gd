extends Control
var price:=0
var phase:=0.0
func _ready() -> void:
	custom_minimum_size=Vector2(245,38)
	mouse_filter=Control.MOUSE_FILTER_IGNORE
func _process(delta: float) -> void:
	phase+=delta*2.4
	queue_redraw()
func _draw() -> void:
	var font:=ThemeDB.fallback_font
	var text:=str(price)
	var width:=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,21).x
	var center:=Vector2(size.x/2-width/2-18,19)
	var coin:=PackedVector2Array()
	for i in 8:
		var a:=TAU*i/8
		coin.append(center+Vector2(cos(a)*maxf(.12,absf(cos(phase)))*13,sin(a)*13))
	draw_colored_polygon(coin,Color("ffcb45"));coin.append(coin[0]);draw_polyline(coin,Color("f39d20"),2,true)
	draw_string(font,Vector2(center.x+21,26),text,HORIZONTAL_ALIGNMENT_LEFT,-1,21,Color("fff1c9"))
