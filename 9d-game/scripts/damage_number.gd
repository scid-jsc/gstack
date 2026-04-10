extends Label3D

var rise_speed: float = 3.0
var lifetime: float = 1.2
var timer: float = 0.0
var h_offset: float = 0.0

func setup(amount: int, is_crit: bool = false, is_heal: bool = false) -> void:
	text = str(amount)
	if is_crit:
		text = str(amount) + " CRI!"
		font_size = 32
		modulate = Color(1.0, 0.3, 0.0)
		outline_modulate = Color.BLACK
	elif is_heal:
		text = "+" + str(amount)
		font_size = 22
		modulate = Color.GREEN
	else:
		font_size = 22
		modulate = Color.RED
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	h_offset = randf_range(-0.5, 0.5)

func _process(delta: float) -> void:
	timer += delta
	position.y += rise_speed * delta
	position.x += h_offset * delta * 0.5
	# Fade out
	var alpha = 1.0 - (timer / lifetime)
	modulate.a = maxf(0.0, alpha)
	if timer >= lifetime:
		queue_free()
