extends Node2D

var line = null # la linea que dice el punto de llegada
var nombre = "" # para demoler

func _ready():
	var mundo = get_tree().get_nodes_in_group("mundo")[0]
	line = get_node("LaLinea")
	remove_child(line)
	mundo.get_node("Lineas").add_child(line)
	PoneLinea()
	Nombrar()

func Nombrar():
	if name.count("@") == 0:
		nombre = name
	else:
		nombre = name.split("@", false)[0]

func PoneLinea(forzar=false):
	if forzar or get_tree().get_nodes_in_group("nodal").empty():
		line.visible = false
	else:
		var puerta = get_node("Puerta")
		var p = puerta.conect.find(2)
		if p == -1:
			line.visible = false
		elif is_instance_valid(puerta.destino[p]):
			line.visible = true
			line.points[0] = position
			line.points[1] = puerta.destino[p].get_parent().position
		else:
			line.visible = false

func Abierto():
	return get_node("Imagen/Actividad").pressed

func _on_Actividad_toggled(button_pressed):
	get_node("Imagen/Actividad/Sonido").play()
	if not button_pressed:
		get_node("Puerta").Resetear()

func TieneAlgo():
	# evita error desde diamante
	return false

func PostSave(buffer):
	buffer.put_u8(1) # es una edificacion terminada
	var mundo = get_tree().get_nodes_in_group("mundo")[0]
	var ind = 255 # extremo inutil
	for i in range(mundo.edifiNames.size()):
		if mundo.edifiNames[i] == nombre:
			ind = i
			break
	buffer.put_u8(ind) # para saber que edificio es

func Save(buffer):
	PostSave(buffer)
	buffer.put_float(position.x)
	buffer.put_float(position.y)
	var a = 1 if get_node("Imagen/Actividad").pressed else 0
	buffer.put_u8(a)

func Open(buffer):
	position.x = buffer.get_float()
	position.y = buffer.get_float()
	get_node("Imagen/Actividad").pressed = buffer.get_u8() != 0

func Destruir(humo=true):
	if humo:
		var mundo = get_tree().get_nodes_in_group("mundo")[0]
		mundo.HumoDemolision(self)
	queue_free()

func Deconstruir():
	var aux = load("res://scenes/andamios/C" + nombre + ".tscn").instance()
	var mundo = get_tree().get_nodes_in_group("mundo")[0]
	mundo.get_node("Objetos").add_child(aux)
	aux.position = position
	aux.ModoDemoler()
	Destruir(false)
