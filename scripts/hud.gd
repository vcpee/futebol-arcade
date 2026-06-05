extends CanvasLayer
class_name HUD

## ============================================================
## HUD — Interface do usuário
## Placar, timer, DOIS joysticks, DOIS botões de chute
## Suporte a 2 jogadores no mesmo device (split controls)
## ============================================================

# --- Referências ---
var match_ref: Match = null

# --- Nodos da UI ---
var score_label: Label
var time_label: Label
var message_label: Label
var charge_bar_p1: ProgressBar
var charge_bar_p2: ProgressBar

# --- Joystick P1 (esquerda) ---
var joystick_p1_base: Control
var joystick_p1_knob: Control
var joystick_p1_active: bool = false
var joystick_p1_touch_id: int = -1
var joystick_p1_center: Vector2 = Vector2.ZERO
var joystick_p1_direction: Vector2 = Vector2.ZERO
const JOYSTICK_RADIUS: float = 70.0

# --- Joystick P2 (direita) ---
var joystick_p2_base: Control
var joystick_p2_knob: Control
var joystick_p2_active: bool = false
var joystick_p2_touch_id: int = -1
var joystick_p2_center: Vector2 = Vector2.ZERO
var joystick_p2_direction: Vector2 = Vector2.ZERO

# --- Botões de chute ---
var kick_button_p1: Button
var kick_button_p2: Button
var kick_label_p1: Label
var kick_label_p2: Label

# --- Referências aos players ---
var player_0: Player = null
var player_1: Player = null

# --- Timer para charge bars ---
var _charge_update_timer: float = 0.0


func _ready() -> void:
	add_to_group("hud")
	_build_ui()
	_find_nodes()


## Construir toda a interface
func _build_ui() -> void:
	# --- Placar (topo central) ---
	score_label = Label.new()
	score_label.text = "0 - 0"
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.position = Vector2(540, 15)
	score_label.add_theme_font_size_override("font_size", 52)
	score_label.add_theme_color_override("font_color", Color.WHITE)
	add_child(score_label)

	# --- Timer (abaixo do placar) ---
	time_label = Label.new()
	time_label.text = "02:00"
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_label.position = Vector2(590, 72)
	time_label.add_theme_font_size_override("font_size", 22)
	time_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	add_child(time_label)

	# --- Mensagem central (gol, etc) ---
	message_label = Label.new()
	message_label.text = ""
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.position = Vector2(340, 280)
	message_label.add_theme_font_size_override("font_size", 72)
	message_label.add_theme_color_override("font_color", Color.YELLOW)
	message_label.visible = false
	add_child(message_label)

	# --- Charge bars ---
	charge_bar_p1 = _create_charge_bar(Vector2(200, 60), Color(0.2, 0.45, 0.95))
	add_child(charge_bar_p1)

	charge_bar_p2 = _create_charge_bar(Vector2(920, 60), Color(0.95, 0.25, 0.2))
	add_child(charge_bar_p2)

	# --- Joystick P1 (lado esquerdo) ---
	joystick_p1_base = _create_joystick(Vector2(100, 480))
	add_child(joystick_p1_base)
	joystick_p1_knob = joystick_p1_base.get_node("Knob")

	# --- Joystick P2 (lado direito) ---
	joystick_p2_base = _create_joystick(Vector2(1080, 480))
	add_child(joystick_p2_base)
	joystick_p2_knob = joystick_p2_base.get_node("Knob")

	# --- Botão de Chute P1 (140x140) ---
	kick_button_p1 = _create_kick_button(Vector2(260, 510), "SEGURE\nPRA CHUTAR", Color(0.2, 0.45, 0.95))
	kick_button_p1.button_down.connect(_on_kick_p1_down)
	kick_button_p1.button_up.connect(_on_kick_p1_up)
	add_child(kick_button_p1)

	# --- Botão de Chute P2 (140x140) ---
	kick_button_p2 = _create_kick_button(Vector2(880, 510), "SEGURE\nPRA CHUTAR", Color(0.95, 0.25, 0.2))
	kick_button_p2.button_down.connect(_on_kick_p2_down)
	kick_button_p2.button_up.connect(_on_kick_p2_up)
	add_child(kick_button_p2)


## Criar barra de charge
func _create_charge_bar(pos: Vector2, color: Color) -> ProgressBar:
	var bar = ProgressBar.new()
	bar.position = pos
	bar.size = Vector2(120, 16)
	bar.max_value = 1.0
	bar.value = 0.0
	bar.show_percentage = false
	bar.modulate = Color(1, 1, 1, 0.3)
	return bar


## Criar joystick visual (SEM parâmetro label — corrigido)
func _create_joystick(pos: Vector2) -> Control:
	var base = Control.new()
	base.position = pos
	base.size = Vector2(140, 140)
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Círculo base
	var bg = Control.new()
	bg.size = Vector2(140, 140)
	bg.draw.connect(func():
		bg.draw_circle(Vector2(70, 70), 70, Color(1, 1, 1, 0.12))
		bg.draw_arc(Vector2(70, 70), 70, 0, TAU, 64, Color(1, 1, 1, 0.25), 2.0, true)
	)
	base.add_child(bg)

	# Knob
	var knob = Control.new()
	knob.name = "Knob"
	knob.size = Vector2(50, 50)
	knob.position = Vector2(45, 45)
	knob.draw.connect(func():
		knob.draw_circle(Vector2(25, 25), 25, Color(1, 1, 1, 0.5))
	)
	base.add_child(knob)

	return base


## Criar botão de chute (140x140 — maior pra mobile)
func _create_kick_button(pos: Vector2, text: String, color: Color) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.position = pos
	btn.size = Vector2(140, 140)
	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_stylebox_override("normal", _make_button_style(color, 0.3))
	btn.add_theme_stylebox_override("hover", _make_button_style(color, 0.5))
	btn.add_theme_stylebox_override("pressed", _make_button_style(color, 0.8))
	return btn


## Criar estilo do botão de chute
func _make_button_style(color: Color, alpha: float) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(color.r, color.g, color.b, alpha)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.border_width_bottom = 2
	style.border_width_top = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_color = Color(color.r, color.g, color.b, 0.8)
	return style


## Encontrar nós na cena
func _find_nodes() -> void:
	await get_tree().process_frame

	match_ref = get_tree().get_first_node_in_group("match")

	if match_ref:
		match_ref.score_changed.connect(_on_score_changed)
		match_ref.time_changed.connect(_on_time_changed)
		match_ref.goal_scored_message.connect(_on_goal_scored)
		match_ref.match_ended_signal.connect(_on_match_ended)

	var players = get_tree().get_nodes_in_group("player")
	for p in players:
		if p.team_id == 0:
			player_0 = p
		elif p.team_id == 1:
			player_1 = p


func _process(delta: float) -> void:
	# Atualizar charge bars
	_charge_update_timer += delta
	if _charge_update_timer >= 0.05:
		_charge_update_timer = 0.0
		_update_charge_bars()


func _update_charge_bars() -> void:
	if player_0:
		var p1_level: float = player_0.get_charge_level()
		charge_bar_p1.value = p1_level
		charge_bar_p1.modulate = Color(1, 1, 1, 0.3 + p1_level * 0.7)
	if player_1:
		var p2_level: float = player_1.get_charge_level()
		charge_bar_p2.value = p2_level
		charge_bar_p2.modulate = Color(1, 1, 1, 0.3 + p2_level * 0.7)


## ============================================================
## INPUT TOUCH — Dois joysticks simultâneos
## ============================================================

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_try_activate_joystick(touch.position, touch.finger_id)
		else:
			_try_deactivate_joystick(touch.finger_id)

	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		_update_joystick_by_touch(drag.finger_id, drag.position)


## Tentar ativar um joystick com o toque
func _try_activate_joystick(touch_pos: Vector2, touch_id: int) -> void:
	# Verificar P1 (metade esquerda da tela)
	if touch_pos.x < 640:
		if not joystick_p1_active:
			joystick_p1_active = true
			joystick_p1_touch_id = touch_id
			joystick_p1_center = joystick_p1_base.position + joystick_p1_base.size / 2.0
			_update_joystick(1, touch_pos)
	# Verificar P2 (metade direita da tela)
	else:
		if not joystick_p2_active:
			joystick_p2_active = true
			joystick_p2_touch_id = touch_id
			joystick_p2_center = joystick_p2_base.position + joystick_p2_base.size / 2.0
			_update_joystick(2, touch_pos)


## Tentar desativar joystick pelo touch_id
func _try_deactivate_joystick(touch_id: int) -> void:
	if touch_id == joystick_p1_touch_id:
		joystick_p1_active = false
		joystick_p1_touch_id = -1
		joystick_p1_direction = Vector2.ZERO
		_reset_knob(1)
		if player_0:
			player_0.set_move_direction(Vector2.ZERO)

	if touch_id == joystick_p2_touch_id:
		joystick_p2_active = false
		joystick_p2_touch_id = -1
		joystick_p2_direction = Vector2.ZERO
		_reset_knob(2)
		if player_1:
			player_1.set_move_direction(Vector2.ZERO)


## Atualizar joystick por drag
func _update_joystick_by_touch(touch_id: int, touch_pos: Vector2) -> void:
	if joystick_p1_active and touch_id == joystick_p1_touch_id:
		_update_joystick(1, touch_pos)
	elif joystick_p2_active and touch_id == joystick_p2_touch_id:
		_update_joystick(2, touch_pos)


## Atualizar posição do joystick (1 ou 2)
func _update_joystick(joystick_id: int, touch_pos: Vector2) -> void:
	var center: Vector2 = joystick_p1_center if joystick_id == 1 else joystick_p2_center
	var knob: Control = joystick_p1_knob if joystick_id == 1 else joystick_p2_knob
	var player: Player = player_0 if joystick_id == 1 else player_1

	var offset: Vector2 = touch_pos - center
	if offset.length() > JOYSTICK_RADIUS:
		offset = offset.normalized() * JOYSTICK_RADIUS

	var direction: Vector2 = offset / JOYSTICK_RADIUS

	# Mover knob visual
	knob.position = Vector2(45, 45) + offset - Vector2(25, 25)

	# Enviar direção ao player
	if player:
		player.set_move_direction(direction)

	# Salvar direção
	if joystick_id == 1:
		joystick_p1_direction = direction
	else:
		joystick_p2_direction = direction


## Resetar knob para o centro
func _reset_knob(joystick_id: int) -> void:
	var knob: Control = joystick_p1_knob if joystick_id == 1 else joystick_p2_knob
	knob.position = Vector2(45, 45)


## ============================================================
## BOTÕES DE CHUTE — com feedback visual de charge
## ============================================================

func _on_kick_p1_down() -> void:
	if player_0:
		player_0.start_charge()
		kick_button_p1.add_theme_stylebox_override("pressed", _make_button_style(Color(1.0, 0.8, 0.1), 0.9))
		kick_button_p1.text = "🔥 CHUTANDO..."

func _on_kick_p1_up() -> void:
	if player_0:
		player_0.release_charge()
	kick_button_p1.add_theme_stylebox_override("pressed", _make_button_style(Color(0.2, 0.45, 0.95), 0.8))
	kick_button_p1.text = "SEGURE\nPRA CHUTAR"

func _on_kick_p2_down() -> void:
	if player_1:
		player_1.start_charge()
		kick_button_p2.add_theme_stylebox_override("pressed", _make_button_style(Color(1.0, 0.8, 0.1), 0.9))
		kick_button_p2.text = "🔥 CHUTANDO..."

func _on_kick_p2_up() -> void:
	if player_1:
		player_1.release_charge()
	kick_button_p2.add_theme_stylebox_override("pressed", _make_button_style(Color(0.95, 0.25, 0.2), 0.8))
	kick_button_p2.text = "SEGURE\nPRA CHUTAR"


## ============================================================
## CALLBACKS DO MATCH
## ============================================================

func _on_score_changed(team_0_score: int, team_1_score: int) -> void:
	score_label.text = "%d - %d" % [team_0_score, team_1_score]


func _on_time_changed(time_left: int) -> void:
	var minutes: int = time_left / 60
	var seconds: int = time_left % 60
	time_label.text = "%02d:%02d" % [minutes, seconds]


func _on_goal_scored(scoring_team: int) -> void:
	message_label.text = "⚽ GOOOL! ⚽"
	message_label.visible = true
	message_label.add_theme_color_override("font_color", Color(0.2, 0.45, 0.95) if scoring_team == 0 else Color(0.95, 0.25, 0.2))

	var timer = get_tree().create_timer(2.0)
	timer.timeout.connect(func():
		message_label.visible = false
	)


func _on_match_ended(winner: int) -> void:
	if winner == -1:
		message_label.text = "EMPATE!"
	elif winner == 0:
		message_label.text = "🔵 TIME AZUL VENCEU! 🔵"
	else:
		message_label.text = "🔴 TIME VERMELHO VENCEU! 🔴"

	message_label.visible = true
	message_label.add_theme_font_size_override("font_size", 48)
