extends Node2D

const disPorton = 128.0 # longitud maxima del camino edificacion a calle, coincide con Puerta.gd

var indBuild = 0 # identificador de construccion
var colisiones = 0 # cuenta la cantidad de objetos en colision
var mundo = null # nodo maestro para asceso rapido
var prohibido = false # true si no se puede poner ahi
var cambiaValor = false # false:no, true:ver
var miNeto = null # para mantener en GUI el valor actual de dinero
var laLinea = null # para acceso rapido a la linea roja

func _ready():
	mundo = get_tree().get_nodes_in_group("mundo")[0]
	miNeto = get_node("Neto")
	remove_child(miNeto)
	mundo.get_node("Esquina").add_child(miNeto)
	miNeto.position = Vector2(0, 0)
	miNeto.scale = Vector2(1, 1)
	mundo.get_node("GUI").visible = false
	mundo.get_node("GUI").NoSeguir()
	laLinea = mundo.get_node("LineaNodal")
	laLinea.visible = true
	get_node("Value/Valor").text = "$" + str(mundo.Costos(Nombre()))

func Nombre():
	var n = name
	if name.count("@") != 0:
		n = n.split("@", false)[0]
	return n.substr(1)

func _process(_delta):
	position = get_global_mouse_position()
	mundo.get_node("CircleComand").position = position
	miNeto.get_node("Valor").text = "$" + str(mundo.Costos("todo"))
	get_node("Value").scale = mundo.get_node("Esquina").rect_scale
	# ubicar linea en puerta
	var calles = get_tree().get_nodes_in_group("calle")
	var pp = get_node("Imagen/Entrada").global_position
	var minDis = disPorton
	var cll = null
	var dis
	for c in calles:
		dis = c.position.distance_to(pp)
		if dis < minDis:
			minDis = dis
			cll = c
	if cll != null:
		laLinea.visible = true
		laLinea.points[0] = pp
		laLinea.points[1] = cll.position
	else:
		laLinea.visible = false
	# verificar si se puede poner
	var ok = colisiones == 0
	if ok:
		for n in get_node("Cimientos").get_children():
			if not mundo.EnTierra(n.global_position):
				ok = false
				break
	if ok != prohibido:
		prohibido = ok
		if ok:
			modulate = Color(1, 1, 1, 1)
		else:
			modulate = Color(0.25, 0.25, 0.25, 0.5)
	# pintar el valor
	if ok != cambiaValor:
		cambiaValor = ok
		get_node("Value").visible = ok

func _input(event):
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == BUTTON_LEFT:
				Instalar()
			elif event.button_index == BUTTON_MIDDLE:
				Cerrar()
	elif event.is_action_pressed("ui_cancel"):
		Cerrar()

func Instalar():
	if colisiones == 0:
		var ok = true
		for n in get_node("Cimientos").get_children():
			if not mundo.EnTierra(n.global_position):
				ok = false
				break
		if ok and mundo.Comprando(Nombre()):
			var aux = mundo.loadBuilds[1][indBuild].instance()
			mundo.get_node("Objetos").add_child(aux)
			aux.position = position
			mundo.QuitaNaturales()
			mundo.get_node("GUI/SCreaEdificacion").play()
			mundo.EdificacionPuesta(Nombre())
			if not Input.is_action_pressed("ui_hold"):
				Cerrar()

func Cerrar():
	get_tree().get_nodes_in_group("gui")[0].visible = true
	mundo.get_node("CircleComand").visible = false
	laLinea.visible = false
	miNeto.queue_free()
	queue_free()

func _on_Construccion_area_entered(area):
	if not area.get_parent().is_in_group("arbol"):
		colisiones += 1

func _on_Construccion_area_exited(area):
	if not area.get_parent().is_in_group("arbol"):
		colisiones -= 1

func _on_Reserva_area_entered(area):
	if not area.get_parent().is_in_group("arbol"):
		colisiones += 1
	elif not area.get_parent().is_in_group("mina"):
		colisiones += 1

func _on_Reserva_area_exited(area):
	if not area.get_parent().is_in_group("arbol"):
		colisiones -= 1
	elif not area.get_parent().is_in_group("mina"):
		colisiones -= 1
