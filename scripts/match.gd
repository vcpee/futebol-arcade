extends Node2D
class_name Match

## ============================================================
## MATCH — Lógica da partida
## Timer, placar, detecção de gol, reset de posição
## ============================================================

# --- Configurações ---
@export var match_duration: float = 120.0       # Duração de cada tempo (segundos)
@export var goal_celebration_time: float = 2.5  # Pausa após gol
@export var kickoff_delay: float = 1.5          # Delay antes do kickoff

# --- Estado ---
var score_team_0: int = 0
var score_team_1: int = 0
var time_remaining: float = 0.0
var current_half: int = 1
var is_playing: bool = false
var is_paused: bool = false
var is_goal_celebration: bool = false
var goal_celebration_timer: float = 0.0
var match_ended: bool = false
var kickoff_timer: float = 0.0
var waiting_kickoff: bool = false

# --- Referências (cacheadas) ---
var ball: Ball = null
var player_0: Player = null
var player_1: Player = null
var field: Field = null
var _nodes_ready: bool = false

# --- Posições iniciais ---
var player_0_start: Vector2
var player_1_start: Vector2

# --- Sinais ---
signal score_changed(team_0_score: int, team_1_score: int)
signal time_changed(time_left: int)
signal goal_scored_message(scoring_team: int)
signal match_started()
signal match_ended_signal(winner: int)
signal half_time()
signal kickoff()


func _ready() -> void:
	add_to_group("match")
	# Setup básico imediato (sem await)
	time_remaining = match_duration
	current_half = 1
	score_team_0 = 0
	score_team_1 = 0
	match_ended = false
	is_playing = false
	waiting_kickoff = false

	# Buscar nós (1 frame depois pra garantir que existem)
	await get_tree().process_frame
	_find_nodes()
	_nodes_ready = true

	# Configurar posições iniciais
	if field:
		var bounds = field.get_field_bounds()
		player_0_start = Vector2(bounds.size.x * 0.25, bounds.size.y / 2.0)
		player_1_start = Vector2(bounds.size.x * 0.75, bounds.size.y / 2.0)
	_reset_positions()


func _process(delta: float) -> void:
	if not _nodes_ready or match_ended:
		return

	# Kickoff delay
	if waiting_kickoff:
		kickoff_timer -= delta
		if kickoff_timer <= 0.0:
			waiting_kickoff = false
			is_playing = true
			kickoff.emit()
		return

	if not is_playing or is_paused:
		return

	# Celebração de gol
	if is_goal_celebration:
		goal_celebration_timer -= delta
		if goal_celebration_timer <= 0.0:
			_end_goal_celebration()
		return

	# Timer
	time_remaining -= delta

	# Clamp tempo nunca negativo
	if time_remaining <= 0.0:
		time_remaining = 0.0
		_end_half()
		return

	# Emitir sinal de tempo
	time_changed.emit(int(time_remaining))

	# Verificar gol
	_check_goal()


## Encontrar nós necessários na cena
func _find_nodes() -> void:
	ball = get_tree().get_first_node_in_group("ball")
	field = get_tree().get_first_node_in_group("field")

	var players = get_tree().get_nodes_in_group("player")
	for p in players:
		if p.team_id == 0:
			player_0 = p
		elif p.team_id == 1:
			player_1 = p


## Verificar se bola entrou no gol
func _check_goal() -> void:
	if ball == null or field == null:
		return

	var goal_result: int = field.check_goal(ball.position)
	if goal_result >= 0:
		var scoring_team: int = 1 - goal_result
		_register_goal(scoring_team)


## Registrar gol
func _register_goal(scoring_team: int) -> void:
	if scoring_team == 0:
		score_team_0 += 1
	else:
		score_team_1 += 1

	is_goal_celebration = true
	goal_celebration_timer = goal_celebration_time
	is_playing = false

	score_changed.emit(score_team_0, score_team_1)
	goal_scored_message.emit(scoring_team)


## Fim da celebração de gol
func _end_goal_celebration() -> void:
	is_goal_celebration = false
	_reset_positions()
	waiting_kickoff = true
	kickoff_timer = kickoff_delay


## Resetar posições de todos
func _reset_positions() -> void:
	if ball:
		ball.reset_to_center()
	if player_0:
		player_0.reset_position(player_0_start)
	if player_1:
		player_1.reset_position(player_1_start)


## Fim do tempo
func _end_half() -> void:
	if current_half == 1:
		current_half = 2
		time_remaining = match_duration
		half_time.emit()
		_reset_positions()
		waiting_kickoff = true
		kickoff_timer = kickoff_delay
	else:
		_end_match()


## Fim da partida
func _end_match() -> void:
	is_playing = false
	match_ended = true

	var winner: int = -1
	if score_team_0 > score_team_1:
		winner = 0
	elif score_team_1 > score_team_0:
		winner = 1

	match_ended_signal.emit(winner)


## Pausar/despausar
func toggle_pause() -> void:
	if match_ended:
		return
	is_paused = not is_paused


## Reiniciar partida
func restart_match() -> void:
	time_remaining = match_duration
	current_half = 1
	score_team_0 = 0
	score_team_1 = 0
	match_ended = false
	is_playing = false
	is_goal_celebration = false
	waiting_kickoff = false
	_reset_positions()
	start_match()


## Iniciar partida
func start_match() -> void:
	waiting_kickoff = true
	kickoff_timer = kickoff_delay
	match_started.emit()
	score_changed.emit(score_team_0, score_team_1)
	time_changed.emit(int(time_remaining))


## Obter placar formatado
func get_score_text() -> String:
	return "%d - %d" % [score_team_0, score_team_1]


## Obter tempo formatado (MM:SS)
func get_time_text() -> String:
	var minutes: int = int(time_remaining) / 60
	var seconds: int = int(time_remaining) % 60
	return "%02d:%02d" % [minutes, seconds]
