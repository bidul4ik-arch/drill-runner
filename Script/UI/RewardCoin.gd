extends Control
var phase:=0.0
var token:=preload("res://Art/UI/token.svg")
func _ready() -> void:
	custom_minimum_size=Vector2(250,210);mouse_filter=Control.MOUSE_FILTER_IGNORE
func _process(delta: float) -> void:
	phase+=delta;queue_redraw()
func _draw() -> void:
	var center:=size*.5
	for i in 12:
		var a:=i*TAU/12+phase*.12
		var points:=PackedVector2Array([center,center+Vector2.from_angle(a)*145,center+Vector2.from_angle(a+.16)*145])
		draw_colored_polygon(points,Color(1,.87,.4,.10))
	draw_set_transform(center,0,Vector2(.7+.3*cos(phase*2),1))
	draw_texture_rect(token,Rect2(-70,-70,140,140),false)
	draw_set_transform(Vector2.ZERO)
	for i in 8:
		var p:=center+Vector2.from_angle(i*TAU/8+phase*.3)*(94+sin(phase*2+i)*8)
		draw_circle(p,2+sin(phase+i),Color("fff1b0"))
