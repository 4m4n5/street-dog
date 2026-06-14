extends Node2D

@onready var _light: PointLight2D = $PointLight2D
@onready var _pool: ColorRect = $LightPool

var _base_energy: float = 1.0


func _ready() -> void:
	if _light:
		_base_energy = _light.energy
		_light.texture = _make_light_texture()
	_schedule_flicker()


func _make_light_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1.0, 0.72, 0.36, 0.82))
	gradient.set_color(1, Color(1.0, 0.72, 0.36, 0.0))

	var texture := GradientTexture2D.new()
	texture.width = 256
	texture.height = 256
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.gradient = gradient
	return texture


func _schedule_flicker() -> void:
	var timer := get_tree().create_timer(randf_range(2.0, 7.0))
	timer.timeout.connect(_on_flicker_timer)


func _on_flicker_timer() -> void:
	if is_instance_valid(_light) and randf() < 0.4:
		var tween := create_tween()
		tween.tween_property(_light, "energy", _base_energy * 0.78, 0.05)
		tween.parallel().tween_property(_pool, "modulate:a", 0.16, 0.05)
		tween.tween_property(_light, "energy", _base_energy, 0.1)
		tween.parallel().tween_property(_pool, "modulate:a", 0.34, 0.1)
	_schedule_flicker()
