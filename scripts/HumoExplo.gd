extends Node2D

func _ready():
	get_node("Polvo").emitting = true

func _on_Fin_timeout():
	queue_free()
