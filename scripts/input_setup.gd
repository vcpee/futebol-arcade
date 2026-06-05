extends Node

## ============================================================
## INPUT SETUP — Configura inputs do P2 via código
## Godot 4 não permite criar InputMap via script facilmente,
## então usamos um approach diferente: o player lê teclas
## diretamente no _process
## ============================================================

func _ready() -> void:
	# Configurar inputs do Player 2 no InputMap
	_add_p2_inputs()


func _add_p2_inputs() -> void:
	# P2: Setas do teclado
	_add_action("p2_move_left", KEY_LEFT)
	_add_action("p2_move_right", KEY_RIGHT)
	_add_action("p2_move_up", KEY_UP)
	_add_action("p2_move_down", KEY_DOWN)
	_add_action("p2_kick", KEY_J)


func _add_action(action_name: String, key: int) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
		var event = InputEventKey.new()
		event.keycode = key
		InputMap.action_add_event(action_name, event)
