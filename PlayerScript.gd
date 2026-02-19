extends CharacterBody2D

# --- Señales ---
signal health_changed(actual_hp)
const SPEED = 120.0
@onready var sprite = $PlayerSprite
@onready var pivot = $AttackPivot
@onready var attack_sprite = $AttackPivot/AttackSprite
@onready var attack_shape = $AttackPivot/AttackArea/AttackCollision
@onready var attack_area = $AttackPivot/AttackArea

# Proximamente Stats
@export var max_health: int = 6
@export var poise: float = 300
var knockback_velocity = Vector2.ZERO
var current_health: int = max_health
var is_invulnerable = false
var is_attacking = false
var last_direction = "down"

func _ready():
	add_to_group("player")
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	await get_tree().process_frame
	health_changed.emit(current_health)

func _physics_process(_delta):
	if knockback_velocity.length() > 10:
		velocity = knockback_velocity
		knockback_velocity = lerp(knockback_velocity, Vector2.ZERO, 0.1)
	else:
		knockback_velocity = Vector2.ZERO
		if is_attacking:
			return
		if Input.is_action_just_pressed("ui_accept"):
			execute_attack()
			return
		var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		
		if direction != Vector2.ZERO:
			velocity = direction * SPEED
			update_direction_and_pivot(direction)
		else:
			velocity = velocity.move_toward(Vector2.ZERO, SPEED)
			sprite.stop()
			sprite.frame = 1
	move_and_slide()

func take_damage(amount: int = 1, attacker_pos: Vector2 = Vector2.ZERO):
	if is_invulnerable:
		return
	current_health -= amount
	current_health = max(0, current_health)
	health_changed.emit(current_health)
	if current_health <= 0:
		die()
	else:
		if attacker_pos != Vector2.ZERO:
			var knockback_dir = (global_position - attacker_pos).normalized()
			var knockback_strength = max(0.0, 900.0 - poise)
			knockback_velocity = knockback_dir * knockback_strength
		start_invulnerability()

func start_invulnerability():
	is_invulnerable = true
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(2, 0.4, 0.4), 0.1)
	tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.1)
	tween.set_loops(5)
	
	await get_tree().create_timer(1.0).timeout
	is_invulnerable = false

func die():
	if is_inside_tree():
		get_tree().reload_current_scene()

func update_direction_and_pivot(dir):
	if abs(dir.x) > abs(dir.y):
		last_direction = "side"
		sprite.play("side")
		sprite.flip_h = (dir.x < 0)
		pivot.rotation_degrees = 0 if dir.x > 0 else 180
	else:
		if dir.y > 0:
			last_direction = "down"
			sprite.play("down")
			pivot.rotation_degrees = 90
		else:
			last_direction = "up"
			sprite.play("up")
			pivot.rotation_degrees = 270

func execute_attack():
	is_attacking = true
	attack_sprite.visible = true
	attack_sprite.play("swing")
	attack_shape.disabled = false
	
	var bodytouch = attack_area.get_overlapping_bodies()
	for body in bodytouch:
		if body.is_in_group("enemies") and body.has_method("take_damage"):
			body.take_damage(global_position)
	await attack_sprite.animation_finished
	
	attack_shape.disabled = true
	attack_sprite.visible = false
	is_attacking = false

func _on_attack_area_body_entered(body):
	if is_attacking and body.is_in_group("enemies"):
		if body.has_method("take_damage"):
			body.take_damage(global_position)
