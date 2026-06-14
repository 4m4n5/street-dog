extends Node2D

## Nighttime NYC street — ambient mood and distant skyline shimmer.


func _ready() -> void:
	_shimmer_windows()


func _shimmer_windows() -> void:
	for window in get_tree().get_nodes_in_group("lit_windows"):
		if window is ColorRect:
			_animate_window(window)


func _animate_window(window: ColorRect) -> void:
	var tween := create_tween().set_loops()
	tween.tween_property(window, "modulate:a", 0.45, randf_range(2.0, 5.0))
	tween.tween_property(window, "modulate:a", 1.0, randf_range(2.0, 5.0))
