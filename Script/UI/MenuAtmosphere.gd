extends Control
var time:=0.0
var shade: GradientTexture2D
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	shade=GradientTexture2D.new();shade.width=8;shade.height=512;shade.fill_to=Vector2(0,1)
	shade.gradient=Gradient.new();shade.gradient.offsets=PackedFloat32Array([0,.46,1])
	shade.gradient.colors=PackedColorArray([Color(.02,.08,.12,.3),Color(.02,.08,.12,0),Color(.02,.08,.12,.48)])
func _process(delta: float) -> void:time+=delta;queue_redraw()
func _draw() -> void:
	var h:=size.y
	if shade:draw_texture_rect(shade,Rect2(Vector2.ZERO,size),false)
	for i in 16:
		var p:=Vector2(fposmod(i*137.2+sin(time*.2+i)*30,size.x),fposmod(i*73.1-time*(5+i%3),h))
		draw_circle(p,1.5+i%2,Color(1,.79,.37,.12+.13*sin(time+i)))
