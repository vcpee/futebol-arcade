extends Node2D
class_name PlayerVisual

## ============================================================
## PLAYER VISUAL — Define a cor/sprite do jogador
## Baseado no team_id
## ============================================================

@export var player_node: Node2D

func _ready() -> void:
	_apply_team_color()


func _apply_team_color() -> void:
	var player = player_node as Player
	if player == null:
		return

	var body: Polygon2D = player.get_node_or_null("Body")
	var outline: Line2D = player.get_node_or_null("Outline")

	if body and outline:
		if player.team_id == 0:
			# Time Azul
			body.color = Color(0.2, 0.45, 0.95, 1)
			outline.default_color = Color(0.1, 0.25, 0.7, 1)
		else:
			# Time Vermelho
			body.color = Color(0.95, 0.25, 0.2, 1)
			outline.default_color = Color(0.7, 0.1, 0.1, 1)
