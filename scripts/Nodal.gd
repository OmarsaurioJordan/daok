extends Node2D

const disPorton = 128.0 # longitud maxima del camino edificacion a calle, coincide con Puerta.gd

var colisiones = 0 # cuenta la cantidad de objetos en colision
var anclaMouse = Vector2(0, 0) # para conectar calles
var recCalle = load("res://scenes/otros/Calle.tscn")
var mundo = null # nodo maestro para asceso rapido
var prohibido = false # true si no se puede poner ahi
var cambiaValor = false # false:no, true:ver
var miNeto = null # para mantener en GUI el valor actual de dinero
var laLinea = [null, null] # para acceso rapido a la linea azul y roja

func _ready():
	mundo = get_tree().get_nodes_in_group("mundo")[0]
	mundo.get_node("GUI").visible = false
	mundo.get_node("GUI").NoSeguir()
	mundo.get_node("GUI")._on_BEyeOn_button_down()
	laLinea[0] = mundo.get_node("LineaPuerta")
	laLinea[1] = mundo.get_node("LineaNodal")
	miNeto = get_node("Neto")
	remove_child(miNeto)
	mundo.get_node("Esquina").add_child(miNeto)
	miNeto.position = Vector2(0, 0)
	miNeto.scale = Vector2(1, 1)
	# mostrar pichirilos y lineas
	var pichi = get_tree().get_nodes_in_group("pichirilo")
	for p in pichi:
		p.visible = true
	var puertos = get_tree().get_nodes_in_group("puerto")
	for p in puertos:
		p.PoneLinea()
	get_node("Value/Valor").text = "$" + str(mundo.Costos("calle"))

func _process(_delta):
	position = get_global_mouse_position()
	miNeto.get_node("Valor").text = "$" + str(mundo.Costos("todo"))
	get_node("Value").scale = mundo.get_node("Esquina").rect_scale
	# dibujar linea roja
	var c = false
	var dif = (anclaMouse - get_global_mouse_position()).length()
	if dif > 54 and anclaMouse.length() != 0:
		laLinea[1].visible = true
		laLinea[1].points[0] = anclaMouse
		laLinea[1].points[1] = get_global_mouse_position()
	else:
		c = true
		laLinea[1].visible = false
	# dibujar linea azul
	var puertas = get_tree().get_nodes_in_group("puerta")
	var minDis = disPorton
	var prt = null
	var dis
	for p in puertas:
		dis = p.global_position.distance_to(get_global_mouse_position())
		if dis < minDis:
			if p.get_parent().is_in_group("porton"):
				minDis = dis
				prt = p
	if prt != null:
		laLinea[0].visible = true
		laLinea[0].points[0] = prt.global_position
		laLinea[0].points[1] = get_global_mouse_position()
	else:
		laLinea[0].visible = false
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
			get_node("Imagen/Pichirilo").modulate = Color(1, 1, 1, 1)
		else:
			get_node("Imagen/Pichirilo").modulate = Color(1, 1, 1, 0.25)
	# pintar el valor
	c = c and ok
	if c != cambiaValor:
		cambiaValor = c
		get_node("Value").visible = c

func _input(event):
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == BUTTON_LEFT:
				anclaMouse = get_global_mouse_position()
			elif event.button_index == BUTTON_MIDDLE:
				Cerrar()
		else:
			if event.button_index == BUTTON_LEFT:
				if (anclaMouse - get_global_mouse_position()).length() > 54:
					Conectar()
				else:
					#Debug()
					Instalar()
				anclaMouse = Vector2(0, 0)
	elif event.is_action_pressed("ui_cancel"):
		Cerrar()

func Debug():
	var puerta = null
	var cll = get_tree().get_nodes_in_group("puerta")
	var minDis = 32
	var dis
	for c in cll:
		dis = c.global_position.distance_to(get_global_mouse_position())
		if dis < minDis:
			minDis = dis
			puerta = c
	if puerta != null:
		puerta.Debug()

func Cerrar():
	# esconder pichirilos y lineas
	var pichi = get_tree().get_nodes_in_group("pichirilo")
	for p in pichi:
		p.visible = false
	var puertos = get_tree().get_nodes_in_group("puerto")
	for p in puertos:
		p.PoneLinea(true)
	# desinvocar este objeto
	get_tree().get_nodes_in_group("gui")[0].visible = true
	laLinea[0].visible = false
	laLinea[1].visible = false
	anclaMouse = Vector2(0, 0)
	miNeto.queue_free()
	queue_free()

func Conectar():
	var fin = BuscaNodo(get_global_mouse_position())
	if fin != null:
		fin = fin.get_node("Puerta")
		var ini = BuscaNodo(anclaMouse, "puerto")
		if ini != null:
			var p = ini.get_node("Puerta").conect.find(2)
			var ok = p == -1
			if not ok:
				ok = ini.get_node("Puerta").destino[p] == fin
			if ok:
				ini.get_node("Puerta").Conectar(fin, true, 2)
				fin.Conectar(ini.get_node("Puerta"), true, 2)
				ini.PoneLinea()
				mundo.get_node("GUI/SConectar").play()
		else:
			ini = BuscaNodo(anclaMouse)
			if ini != null and ini != fin:
				var p1 = ini.get_node("Puerta").global_position
				var p2 = fin.global_position
				if mundo.LineaTierra(p1, p1.distance_to(p2), p1.direction_to(p2)):
					ini.get_node("Puerta").Conectar(fin, true)
					fin.Conectar(ini.get_node("Puerta"), true)
					mundo.QuitaNaturales()
					mundo.get_node("GUI/SConectar").play()

func BuscaNodo(pos, tipo="calle"):
	var res = null
	var calles = get_tree().get_nodes_in_group(tipo)
	var dMin = 27
	var dis
	for c in calles:
		dis = c.position.distance_to(pos)
		if dis < dMin:
			dMin = dis
			res = c
	return res

func Instalar():
	if colisiones == 0:
		var ok = true
		for n in get_node("Cimientos").get_children():
			if not mundo.EnTierra(n.global_position):
				ok = false
				break
		if ok and mundo.Comprando("calle"):
			var aux = recCalle.instance()
			mundo.get_node("Objetos").add_child(aux)
			aux.position = position
			aux.get_node("Imagen/Pichirilo").visible = true
			var g = Node.new()
			g.name = "Garantia"
			aux.add_child(g)
			mundo.QuitaNaturales()
			mundo.get_node("GUI/SCalle").play()

func _on_Construccion_area_entered(area):
	if not area.get_parent().is_in_group("arbol"):
		colisiones += 1

func _on_Construccion_area_exited(area):
	if not area.get_parent().is_in_group("arbol"):
		colisiones -= 1
