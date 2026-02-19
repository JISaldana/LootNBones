extends CharacterBody2D

const SPEED = 50.0
const WANDER_SPEED = 30.0
var player = null
var knockback_velocity = Vector2.ZERO 

var wander_direction = Vector2.ZERO
var wander_timer = 0.0
enum State {IDLE, WANDER, CHASE}
var current_state = State.IDLE

@onready var sprite = $EnemySprite

func _physics_process(delta):
	if knockback_velocity.length() > 10:
		velocity = knockback_velocity
		knockback_velocity = lerp(knockback_velocity, Vector2.ZERO, 0.1)
	

	elif player:
		current_state = State.CHASE
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * SPEED
		update_enemy_animations(direction)

	else:
		_update_wander_logic(delta)
	
	move_and_slide()
	
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider.is_in_group("player") and collider.has_method("take_damage"):
			collider.take_damage(1, global_position)

func _update_wander_logic(delta):
	wander_timer -= delta
	
	if wander_timer <= 0:
		if current_state == State.IDLE:
			current_state = State.WANDER
			wander_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
			wander_timer = randf_range(1.0, 3.0)
		else:
			current_state = State.IDLE
			wander_direction = Vector2.ZERO
			wander_timer = randf_range(1.5, 4.0)
	
	if current_state == State.WANDER:
		velocity = wander_direction * WANDER_SPEED
		update_enemy_animations(wander_direction)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, SPEED)
		sprite.stop()
		sprite.frame = 1 

func update_enemy_animations(dir):
	if dir == Vector2.ZERO: return
	
	if abs(dir.x) > abs(dir.y):
		if sprite.sprite_frames.has_animation("side"):
			sprite.play("side")
		sprite.flip_h = (dir.x < 0) 
	else:
		sprite.flip_h = false
		if dir.y > 0:
			if sprite.sprite_frames.has_animation("down"):
				sprite.play("down")
		else:
			if sprite.sprite_frames.has_animation("up"):
				sprite.play("up")

func _on_detector_body_entered(body):
	if body.is_in_group("player"):
		player = body

#func _on_detector_body_exited(body):
#	if body == player:
#		player = null
#		wander_timer = 0

func take_damage(source_position: Vector2):
	var knockback_direction = (global_position - source_position).normalized()
	knockback_velocity = knockback_direction * 300.0 
	
	sprite.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	sprite.modulate = Color.WHITE
