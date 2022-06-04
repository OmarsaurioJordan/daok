extends Node2D

const radioComando = 500.0 # distancia para influir en diamantes

var colisiones = 0 # cuenta la cantidad de objetos en colision
var mundo = null # nodo maestro para asceso rapido
var prohibido = false # true si no se puede poner ahi
var conEscudo = false # true si muestra escudo

func _ready():
	mundo = get_tree().get_nodes_in_group("mundo")[0]
	mundo.get_node("GUI").visible = false
	mundo.get_node("GUI").NoSeguir()
	mundo.get_node("GUI")._on_BEyeOn_button_down()
	mundo.Circulo(radioComando)
	mundo.get_node("CircleComand").visible = true
	conEscudo = mundo.comandoEscudo
	Cambio()

func _process(_delta):
	position = get_global_mouse_position()
	mundo.get_node("CircleComand").position = position
	# verificar si se puede poner
	var ok = colisiones == 0
	if ok:
		ok = mundo.EnTierra(position)
	if ok != prohibido:
		prohibido = ok
		if ok:
			get_node("Imagen/Pichirilo").modulate = Color(1, 1, 1, 1)
		else:
			get_node("Imagen/Pichirilo").modulate = Color(1, 1, 1, 0.25)
	# verificar si ha cambiado
	if Input.is_action_just_pressed("ui_hold"):
		conEscudo = not conEscudo
		Cambio()

func _input(event):
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == BUTTON_LEFT:
				MiComando()
			elif event.button_index == BUTTON_MIDDLE:
				Cerrar()
	elif event.is_action_pressed("ui_cancel"):
		Cerrar()

func MiComando():
	if colisiones == 0 and mundo.EnTierra(position):
		var diams = get_tree().get_nodes_in_group("diamante")
		var hayCom = false
		var exclusivo = Input.is_action_pressed("ui_exclusive")
		for d in diams:
			if d.EsManso(exclusivo):
				if d.Armado() == conEscudo:
					if position.distance_to(d.position) < radioComando:
						d.Comandado(position)
						hayCom = true
		if hayCom:
			mundo.get_node("GUI/SOrden").play()

func Cambio():
	get_node("Imagen/Pichirilo/Escudo").visible = conEscudo
	get_node("Imagen/Pichirilo/Mina").visible = not conEscudo

func Cerrar():
	get_tree().get_nodes_in_group("gui")[0].visible = true
	mundo.get_node("CircleComand").visible = false
	mundo.comandoEscudo = conEscudo
	queue_free()

func _on_Libre_area_entered(_area):
	colisiones += 1

func _on_Libre_area_exited(_area):
	colisiones -= 1
