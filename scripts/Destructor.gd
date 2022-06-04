extends Node2D

var colisiones = [] # cuenta la cantidad de objetos en colision
var mundo = null # nodo maestro para asceso rapido
var cambiaValor = 0 # 0:nada, 1:calle, 2:edificios
var miNeto = null # para mantener en GUI el valor actual de dinero

func _ready():
	mundo = get_tree().get_nodes_in_group("mundo")[0]
	mundo.get_node("GUI").visible = false
	mundo.get_node("GUI").NoSeguir()
	mundo.get_node("GUI")._on_BEyeOn_button_down()
	miNeto = get_node("Neto")
	remove_child(miNeto)
	mundo.get_node("Esquina").add_child(miNeto)
	miNeto.position = Vector2(0, 0)
	miNeto.scale = Vector2(1, 1)
	# mostrar pichirilos
	var pichi = get_tree().get_nodes_in_group("pichirilo")
	for p in pichi:
		p.visible = true

func _process(_delta):
	position = get_global_mouse_position()
	miNeto.get_node("Valor").text = "$" + str(mundo.Costos("todo"))
	get_node("Value").scale = mundo.get_node("Esquina").rect_scale
	# pintar el valor
	var c = 0
	if not colisiones.empty():
		if colisiones[-1].is_in_group("calle"):
			c = 1
		else:
			c = 2
	if c != cambiaValor:
		cambiaValor = c
		if c == 0:
			get_node("Value").visible = false
		else:
			get_node("Value").visible = true
			if c == 1:
				get_node("Value/Valor").text = "$" + str(mundo.Costos("calle"))
			else:
				var s = str(mundo.Costos("demoler", colisiones[-1].nombre))
				get_node("Value/Valor").text = "$" + s

func _input(event):
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == BUTTON_LEFT:
				Eliminar()
			elif event.button_index == BUTTON_MIDDLE:
				Cerrar()
	elif event.is_action_pressed("ui_cancel"):
		Cerrar()

func Cerrar():
	# esconder pichirilos
	var pichi = get_tree().get_nodes_in_group("pichirilo")
	for p in pichi:
		p.visible = false
	# cerrar
	get_tree().get_nodes_in_group("gui")[0].visible = true
	miNeto.queue_free()
	queue_free()

func Eliminar():
	if not colisiones.empty():
		var quien = colisiones[-1]
		if quien.is_in_group("calle"):
			if mundo.Comprando("calle"):
				if quien.has_node("Garantia"):
					quien.get_node("Garantia").free()
				quien.Destruir()
				mundo.get_node("GUI/SDestruir").play()
		else:
			if quien.is_in_group("ediAndamios"):
				if quien.Avance() <= quien.Andamios().size():
					quien.Destruir(false)
				else:
					quien.Deconstruir()
				mundo.get_node("GUI/SDestruir").play()
			elif mundo.Comprando("demoler", quien.nombre):
				quien.Deconstruir()
				mundo.get_node("GUI/SDestruir").play()
			if not Input.is_action_pressed("ui_hold"):
				Cerrar()

func _on_Destruccion_area_entered(area):
	if area.get_parent().is_in_group("ediffice"):
		colisiones.append(area.get_parent())
	elif area.get_parent().is_in_group("calle"):
		colisiones.append(area.get_parent())

func _on_Destruccion_area_exited(area):
	if area.get_parent().is_in_group("ediffice"):
		colisiones.erase(area.get_parent())
	elif area.get_parent().is_in_group("calle"):
		colisiones.erase(area.get_parent())
