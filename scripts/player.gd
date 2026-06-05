extends Node2D
class_name Player

## ============================================================
## PLAYER — Controle do jogador
## Movimentação + chute com charge + colisão com bola
## ============================================================

# --- Configurações ---
@export var move_speed: float = 320.0       # Velocidade de movimento (px/s)
@export var kick_range: float = 55.0        # Distância para interagir com bola
@export var kick_cooldown: float = 0.25     # Tempo entre chutes (segundos)
@export var player_radius: float = 20.0     # Raio do jogador (colisão)
@export var team_id: int = 0                # 0 = time azul, 1 = time vermelho

# --- Chute Charge ---
var is_charging: bool = false
var charge_timer: float = 0.0
var max_charge_time: float = 0.5            # Tempo máximo de charge (segundos)

# --- Estado ---
var can_kick: bool = true
var kick_timer: float = 0.0
var move_direction: Vector2 = Vector2.ZERO
var is_kicking: bool = false
var kick_anim_timer: float = 0.0

# --- Referências (cacheadas) ---
var ball: Ball = null
var match_ref: Match = null
var _field_ref: Node2D = null

# --- Sinais ---
signal charge_started()
signal charge_released(power: float)  # power: 0.0 a 1.0


func _ready() -> void:
	add_to_group("player")
	add_to_group("team_%d" % team_id)
	await get_tree().process_frame
	ball = get_tree().get_first_node_in_group("ball")
	match_ref = get_tree().get_first_node_in_group("match")
	_field_ref = get_tree().get_first_node_in_group("field")


func _physics_process(delta: float) -> void:
	if ball == null:
		return

	# Cooldown do chute
	if not can_kick:
		kick_timer -= delta
		if kick_timer <= 0.0:
			can_kick = true

	# Animação de chute
	if is_kicking:
		kick_anim_timer -= delta
		if kick_anim_timer <= 0.0:
			is_kicking = false

	# Charge do chute
	if is_charging:
		charge_timer += delta
		if charge_timer >= max_charge_time:
			charge_timer = max_charge_time

	# Movimentação
	_move(delta)

	# Toque suave automático (BLOQUEADO durante charge)
	_try_soft_touch()


## Movimentação do jogador
func _move(delta: float) -> void:
	var input_dir := Vector2.ZERO

	# Input por teclado — P1 usa WASD, P2 usa setas
	if team_id == 0:
		input_dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
		input_dir.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	else:
		input_dir.x = Input.get_action_strength("p2_move_right") - Input.get_action_strength("p2_move_left")
		input_dir.y = Input.get_action_strength("p2_move_down") - Input.get_action_strength("p2_move_up")

	# Input por joystick virtual (touch) — sobrescreve teclado
	if move_direction != Vector2.ZERO:
		input_dir = move_direction

	# Normalizar para não ser mais rápido na diagonal
	if input_dir.length() > 1.0:
		input_dir = input_dir.normalized()

	# Aplicar movimento
	position += input_dir * move_speed * delta

	# Limitar ao campo
	_clamp_to_field()


## Toque suave automático — encostou na bola = passe curto
## NÃO dispara durante charge (proteção contra bug de duplo-toque)
func _try_soft_touch() -> void:
	if not can_kick or ball == null or is_charging:
		return

	var distance: float = position.distance_to(ball.position)

	if distance <= kick_range:
		# Proteção: verificar se a bola já foi tocada recentemente
		if ball.was_recently_touched():
			return

		# Toque suave: empurra a bola na direção do movimento
		var touch_dir: Vector2 = (ball.position - position).normalized()
		ball.apply_force(touch_dir * 80.0)
		ball.mark_touched(team_id)

		can_kick = false
		kick_timer = kick_cooldown * 0.5  # Cooldown menor pro toque


## Iniciar charge do chute (botão pressionado)
func start_charge() -> void:
	if not can_kick or ball == null:
		return

	var distance: float = position.distance_to(ball.position)
	if distance > kick_range:
		return

	# Proteção: não iniciar charge se bola foi tocada recentemente
	if ball.was_recently_touched():
		return

	is_charging = true
	charge_timer = 0.0
	charge_started.emit()


## Liberar chute (botão solto) — dispara chute forte
func release_charge() -> void:
	if not is_charging or ball == null:
		is_charging = false
		return

	# Calcular poder do charge (0.0 a 1.0)
	var power: float = clampf(charge_timer / max_charge_time, 0.3, 1.0)

	# Direção do chute
	var kick_dir: Vector2 = (ball.position - position).normalized()

	# Chutar com força baseada no charge
	var is_strong: bool = power > 0.6
	ball.kick_ball(kick_dir, is_strong)
	ball.mark_touched(team_id)

	# Aplicar força extra baseada no power
	if power > 0.8:
		ball.apply_force(kick_dir * 100.0)

	can_kick = false
	kick_timer = kick_cooldown
	is_kicking = true
	kick_anim_timer = 0.25
	is_charging = false

	charge_released.emit(power)


## Definir direção do movimento (para joystick virtual touch)
func set_move_direction(direction: Vector2) -> void:
	move_direction = direction


## Limitar jogador dentro do campo (usa field cachado)
func _clamp_to_field() -> void:
	if _field_ref == null:
		return

	var bounds := _field_ref.get_field_bounds()
	position.x = clampf(position.x, bounds.position.x + player_radius, bounds.position.x + bounds.size.x - player_radius)
	position.y = clampf(position.y, bounds.position.y + player_radius, bounds.position.y + bounds.size.y - player_radius)


## Resetar posição do jogador
func reset_position(start_pos: Vector2) -> void:
	position = start_pos
	move_direction = Vector2.ZERO
	is_charging = false
	charge_timer = 0.0


## Obter nível de charge atual (0.0 a 1.0) — para UI
func get_charge_level() -> float:
	if not is_charging:
		return 0.0
	return clampf(charge_timer / max_charge_time, 0.0, 1.0)


## Verificar se está perto da bola
func is_near_ball() -> bool:
	if ball == null:
		return false
	return position.distance_to(ball.position) <= kick_range
