@tool
extends Node2D


func _draw() -> void:
	draw_dashed_line(
		Vector2(576.0, 116.0),
		Vector2(576.0, 532.0),
		Color("#2A3850"),
		2.0,
		12.0
	)
