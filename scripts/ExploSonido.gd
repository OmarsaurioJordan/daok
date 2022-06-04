extends AudioStreamPlayer2D

func _ready():
	var mundo = get_tree().get_nodes_in_group("mundo")[0]
	mundo.SonidoLen([self])

func _on_ExploSonido_finished():
	queue_free()
