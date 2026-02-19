extends HBoxContainer

@export var hueso_escena: PackedScene 

func _ready():
	await get_tree().process_frame
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.health_changed.connect(_on_player_health_changed)
		_on_player_health_changed(player.current_health)

func _on_player_health_changed(actual_hp):
	for child in get_children():
		child.queue_free()
	
	for i in range(actual_hp):
		if hueso_escena:
			var nuevo_hueso = hueso_escena.instantiate()
			add_child(nuevo_hueso)
#DEBUG
	confirmar_conteo.call_deferred(actual_hp)

func confirmar_conteo(hp_esperada):
	var conteo_real = get_child_count()
	print("En el HPContainer hay: " + str(conteo_real/2))
	
	if conteo_real == 0 and hp_esperada > 0:
		print("SIGUE SIN FUNCIONAR")
