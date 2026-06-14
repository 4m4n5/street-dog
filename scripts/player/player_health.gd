extends Node
class_name PlayerHealth

signal health_changed(current: int, maximum: int)
signal died


@export var max_health: int = 5

var current_health: int = 5
var _invulnerable := false


func _ready() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)


func take_damage(amount: int = 1) -> bool:
	if _invulnerable or amount <= 0:
		return false
	current_health = maxi(current_health - amount, 0)
	health_changed.emit(current_health, max_health)
	if current_health <= 0:
		died.emit()
	return true


func heal(amount: int = 1) -> void:
	if amount <= 0:
		return
	current_health = mini(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)


func set_invulnerable(enabled: bool) -> void:
	_invulnerable = enabled


func is_alive() -> bool:
	return current_health > 0
