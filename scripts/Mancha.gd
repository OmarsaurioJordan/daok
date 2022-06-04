extends Sprite

func _on_Fin_timeout():
	queue_free()

func _on_Tumba_timeout():
	var c = Color(1, 1, 1, get_node("Fin").time_left / get_node("Fin").wait_time)
	modulate = c
