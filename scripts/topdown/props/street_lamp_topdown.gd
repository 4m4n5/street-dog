extends Node2D

@export var light_radius: float = 175.0
@export var light_energy: float = 1.55
@export var sodium_color: Color = Color("#F28E42")
@export var pool_alpha: float = 0.22

@onready var _light: PointLight2D = $PointLight2D
@onready var _pool: Polygon2D = $PaintedPool
@onready var _fixture: ColorRect = $Fixture


func _ready() -> void:
	_apply_lamp_settings()


func configure(radius: float, energy: float, color: Color = Color("#F28E42")) -> void:
	light_radius = radius
	light_energy = energy
	sodium_color = color
	if is_inside_tree():
		_apply_lamp_settings()


func _apply_lamp_settings() -> void:
	if _light != null:
		_light.color = sodium_color
		_light.energy = light_energy
		_light.texture = _make_light_texture()
		_light.texture_scale = light_radius / 128.0
		_light.shadow_enabled = true
	if _pool != null:
		_pool.color = Color(sodium_color.r, sodium_color.g, sodium_color.b, pool_alpha)
		_pool.polygon = _make_pool_polygon(light_radius)
	if _fixture != null:
		_fixture.color = sodium_color.lightened(0.12)


func _make_light_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1.0, 0.78, 0.42, 0.95))
	gradient.set_color(1, Color(1.0, 0.58, 0.22, 0.0))

	var texture := GradientTexture2D.new()
	texture.width = 256
	texture.height = 256
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.gradient = gradient
	return texture


func _make_pool_polygon(radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(28):
		var angle := TAU * float(i) / 28.0
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points
