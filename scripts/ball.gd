extends Node2D
class_name Ball

## ============================================================
## BALL — Física custom da bola
## Sem RigidBody2D — controle total via código
## Inclui proteção anti-duplo-toque (1 tocante por frame)
## ============================================================

# --- Configurações de física ---
@export var max_speed: float = 650.0        # Velocidade máxima (px/s)
@export var friction: float = 0.99           # Fricção por frame (0-1) — mais vivo
@export var kick_force: float = 450.0        # Força base do chute (toque suave)
@export var kick_force_strong: float = 750.0 # Força do chute forte (charge)
@export var kick_upward: float = -120.0      # Componente vertical do chute (arco)
@export var wall_bounce: float = 0.5         # Energia mantida ao bater na parede
@export var ball_radius: float = 12.0        # Raio da bola (colisão)

# --- Estado ---
var velocity: Vector2 = Vector2.ZERO
var position_2d: Vector2 = Vector2.ZERO
var is_moving: bool = false

# --- Anti-duplo-toque ---
var _last_touch_team: int = -1    # Último time que tocou (-1 = ninguém)
var _touch_cooldown: float = 0.0  # Cooldown pra não tocar 2x seguido
const TOUCH_COOLDOWN: float = 0.08  # ~5 frames a 60fps

# --- Referências ---
var field: Node2D = null

# --- Sinais ---
signal ball_reset()


func _ready() -> void:
	position_2d = position
	add_to_group("ball")


func _physics_process(delta: float) -> void:
	if field == null:
		field = get_tree().get_first_node_in_group("field")
		if field == null:
			return

	# Atualizar cooldown de toque
	if _touch_cooldown > 0.0:
		_touch_cooldown -= delta

	# Aplicar fricção
	velocity *= friction

	# Limitar velocidade máxima
	if velocity.length() > max_speed:
		velocity = velocity.normalized() * max_speed

	# Parar se velocidade muito baixa
	if velocity.length() < 3.0:
		velocity = Vector2.ZERO
		is_moving = false
	else:
		is_moving = true

	# Mover bola
	position_2d += velocity * delta

	# Colisão com limites do campo
	_handle_wall_collision()

	# Atualizar posição visual
	position = position_2d


## Aplica força de chute na bola
## direction: direção normalizada do chute
## is_strong: se true, usa força do chute forte
func kick_ball(direction: Vector2, is_strong: bool = false) -> void:
	var force: float = kick_force_strong if is_strong else kick_force
	velocity = direction * force

	# Adicionar componente vertical para arco arcade
	# Chute forte = arco mais fechado (mais reto)
	var arc: float = kick_upward * (0.6 if is_strong else 1.0)
	velocity.y += arc * abs(direction.x)

	is_moving = true


## Aplica força bruta (para colisões com players — toque suave)
func apply_force(force: Vector2) -> void:
	velocity += force
	if velocity.length() > max_speed:
		velocity = velocity.normalized() * max_speed
	is_moving = true


## Verificar se a bola foi tocada recentemente (anti-duplo-toque)
func was_recently_touched() -> bool:
	return _touch_cooldown > 0.0


## Marcar que a bola foi tocada por um time
func mark_touched(team_id: int) -> void:
	_last_touch_team = team_id
	_touch_cooldown = TOUCH_COOLDOWN


## Obter último time que tocou a bola
func get_last_touch_team() -> int:
	return _last_touch_team


## Colisão com as paredes do campo
func _handle_wall_collision() -> void:
	var bounds = field.get_field_bounds()

	# Limites horizontais
	if position_2d.x - ball_radius < bounds.position.x:
		position_2d.x = bounds.position.x + ball_radius
		velocity.x = abs(velocity.x) * wall_bounce
	elif position_2d.x + ball_radius > bounds.position.x + bounds.size.x:
		position_2d.x = bounds.position.x + bounds.size.x - ball_radius
		velocity.x = -abs(velocity.x) * wall_bounce

	# Limites verticais
	if position_2d.y - ball_radius < bounds.position.y:
		position_2d.y = bounds.position.y + ball_radius
		velocity.y = abs(velocity.y) * wall_bounce
	elif position_2d.y + ball_radius > bounds.position.y + bounds.size.y:
		position_2d.y = bounds.position.y + bounds.size.y - ball_radius
		velocity.y = -abs(velocity.y) * wall_bounce


## Resetar bola para o centro do campo
func reset_to_center() -> void:
	var bounds = field.get_field_bounds()
	position_2d = Vector2(
		bounds.position.x + bounds.size.x / 2.0,
		bounds.position.y + bounds.size.y / 2.0
	)
	position = position_2d
	velocity = Vector2.ZERO
	is_moving = false
	_last_touch_team = -1
	_touch_cooldown = 0.0
	ball_reset.emit()


## Verificar se bola está na área do gol
func is_in_goal_area(goal_bounds: Rect2) -> bool:
	return goal_bounds.has_point(position_2d)


## Obter velocidade atual
func get_speed() -> float:
	return velocity.length()
