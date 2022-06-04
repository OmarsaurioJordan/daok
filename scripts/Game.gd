extends Node

const version = "1.0.0"
const maxMapa = 15 # mayor indice de mapa posible
var mapa = 1 # guarda el indice del mapa a ser usado 1 a maxMapa

func _ready():
	randomize()
	get_tree().set_auto_accept_quit(false)
	

func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		if has_node("Mundo"):
			if get_node("Mundo").GetDia() != 0:
				get_node("Mundo").Guardar("user://savegame.save")
		get_tree().quit()

func _on_ReEscala_timeout():
	get_node("ReEscala").queue_free()
	OS.window_maximized = true

func CambiaMapa(esMas):
	if esMas:
		mapa += 1
		if mapa > maxMapa:
			mapa = 1
	else:
		mapa -= 1
		if mapa <= 0:
			mapa = maxMapa
