extends Node2D
class_name Field

## ============================================================
## FIELD — Campo de futebol
## Define limites, goleiras, e desenha o campo
## ============================================================

# --- Configurações do campo ---
@export var field_width: float = 1100.0
@export var field_height: float = 600.0
@export var goal_width: float = 20.0
@export var goal_height: float = 180.0
@export var line_width: float = 3.0

# --- Cores ---
@export var field_color := Color(0.18, 0.55, 0.18)      # Verde campo
@export var field_color_dark := Color(0.14, 0.48, 0.14)  # Verde mais escuro (faixas)
@export var line_color := Color(1, 1, 1, 0.9)             # Branco linhas
@export var goal_color_left := Color(0.9, 0.15, 0.15, 0.4)   # Goleira esquerda (vermelho)
@export var goal_color_right := Color(0.15, 0.15, 0.9, 0.4)  # Goleira direita (azul)

# --- Estado ---
var field_bounds: Rect2
var goal_left_bounds: Rect2
var goal_right_bounds: Rect2


func _ready() -> void:
	add_to_group("field")
	_calculate_bounds()


func _draw() -> void:
	# Fundo do campo com faixa (efeito de corte de grama)
	_draw_field_stripes()

	# Borda do campo
	draw_rect(Rect2(Vector2.ZERO, Vector2(field_width, field_height)), line_color, false, line_width)

	# Linha central
	var center_x: float = field_width / 2.0
	draw_line(Vector2(center_x, 0), Vector2(center_x, field_height), line_color, line_width)

	# Círculo central
	var center: Vector2 = Vector2(center_x, field_height / 2.0)
	draw_arc(center, 60.0, 0, TAU, 64, line_color, line_width, true)

	# Ponto central
	draw_circle(center, 5.0, line_color)

	# Área do gol esquerdo (grande)
	var goal_area_left = Rect2(0, (field_height - goal_height * 1.6) / 2.0, 80, goal_height * 1.6)
	draw_rect(goal_area_left, Color(1, 1, 1, 0.08), true)
	draw_rect(goal_area_left, line_color, false, line_width)

	# Área do gol direito (grande)
	var goal_area_right = Rect2(field_width - 80, (field_height - goal_height * 1.6) / 2.0, 80, goal_height * 1.6)
	draw_rect(goal_area_right, Color(1, 1, 1, 0.08), true)
	draw_rect(goal_area_right, line_color, false, line_width)

	# Goleiras
	var goal_left_rect = Rect2(0, (field_height - goal_height) / 2.0, goal_width, goal_height)
	var goal_right_rect = Rect2(field_width - goal_width, (field_height - goal_height) / 2.0, goal_width, goal_height)

	draw_rect(goal_left_rect, goal_color_left, true)
	draw_rect(goal_right_rect, goal_color_right, true)

	# Moldura goleira esquerda
	draw_rect(goal_left_rect, Color.RED, false, line_width + 2)

	# Moldura goleira direita
	draw_rect(goal_right_rect, Color.BLUE, false, line_width + 2)

	# Rede da goleira (linhas cruzadas sutis)
	_draw_net(goal_left_rect, Color.RED)
	_draw_net(goal_right_rect, Color.BLUE)


## Desenhar faixas do campo (efeito corte de grama)
func _draw_field_stripes() -> void:
	var stripe_width: float = field_width / 10.0
	for i in range(10):
		var color: Color = field_color if i % 2 == 0 else field_color_dark
		var stripe = Rect2(i * stripe_width, 0, stripe_width, field_height)
		draw_rect(stripe, color, true)


## Desenhar rede da goleira (linhas sutis)
func _draw_net(rect: Rect2, color: Color) -> void:
	var net_color = Color(color.r, color.g, color.b, 0.15)
	for i in range(1, 6):
		var x = rect.position.x + rect.size.x * i / 6.0
		draw_line(Vector2(x, rect.position.y), Vector2(x, rect.position.y + rect.size.y), net_color, 1.0)
	for i in range(1, 6):
		var y = rect.position.y + rect.size.y * i / 6.0
		draw_line(Vector2(rect.position.x, y), Vector2(rect.position.x + rect.size.x, y), net_color, 1.0)


## Calcular limites do campo e goleiras
func _calculate_bounds() -> void:
	field_bounds = Rect2(0, 0, field_width, field_height)

	var goal_y: float = (field_height - goal_height) / 2.0
	goal_left_bounds = Rect2(0, goal_y, goal_width * 3, goal_height)
	goal_right_bounds = Rect2(field_width - goal_width * 3, goal_y, goal_width * 3, goal_height)


## Retornar limites do campo
func get_field_bounds() -> Rect2:
	if field_bounds == Rect2():
		_calculate_bounds()
	return field_bounds


## Retornar retângulos das goleiras para detecção de gol
func get_left_goal_rect() -> Rect2:
	return Rect2(0, (field_height - goal_height) / 2.0, goal_width, goal_height)


func get_right_goal_rect() -> Rect2:
	return Rect2(field_width - goal_width, (field_height - goal_height) / 2.0, goal_width, goal_height)


## Verificar qual goleira a bola entrou → retorna team_id do time que SOFREU o gol
func check_goal(ball_pos: Vector2) -> int:
	if get_left_goal_rect().has_point(ball_pos):
		return 1  # Time 1 sofreu gol → ponto pro time 0
	if get_right_goal_rect().has_point(ball_pos):
		return 0  # Time 0 sofreu gol → ponto pro time 1
	return -1  # Sem gol
