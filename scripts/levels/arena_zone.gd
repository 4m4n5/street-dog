extends Area2D

## Marks a combat arena volume for future encounter triggers.
## collision_layer/mask unused until combat system wires body_entered.

@export var room_id: String = ""
@export var display_name: String = ""
