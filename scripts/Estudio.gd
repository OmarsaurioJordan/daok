extends Node2D

const asientos = 3 # capacidad de guardar diamantes
var nombre = "" # para demoler

func _ready():
	get_node("Lapix").start(rand_range(10, 15))
	Nombrar()
	var mundo = get_tree().get_nodes_in_group("mundo")[0]
	mundo.SonidoLen([get_node("Sonido"), get_node("SonidoLibro"), get_node("SPoner")])

func Nombrar():
	if name.count("@") == 0:
		nombre = name
	else:
		nombre = name.split("@", false)[0]

func Libros():
	var tot = 0
	for i in range(4):
		if get_node("Imagen/Libro" + str(i + 1)).visible:
			tot += 1
	return tot

func Lectores():
	return get_node("Imagen/Salon/Sala").get_child_count()

func Compannia():
	return get_node("Imagen/Salon/Sala").get_child_count()

func TomaLibro():
	var libri = range(4)
	libri.shuffle()
	for l in libri:
		if get_node("Imagen/Libro" + str(l + 1)).visible:
			get_node("Imagen/Libro" + str(l + 1)).visible = false
			return true
	return false

func PoneLibro():
	var libri = range(4)
	libri.shuffle()
	for l in libri:
		if not get_node("Imagen/Libro" + str(l + 1)).visible:
			get_node("Imagen/Libro" + str(l + 1)).visible = true
			return true
	return false

func _on_Lapix_timeout():
	get_node("Lapix").start(rand_range(10, 15))
	if Produccion(false):
		if randf() < 0.5: # produccion lenta
			var i
			for _r in range(4): # probabilidad
				i = randi() % 4
				if not get_node("Imagen/Libro" + str(1 + i)).visible:
					get_node("Imagen/Libro" + str(1 + i)).visible = true
					get_node("Sonido").play()
					break
	if not get_node("Imagen/Actividad").pressed:
		Sacarlos()
	elif Libros() == 4:
		if get_node("Imagen/Ventana").get_child_count() != 0:
			if get_node("Imagen/Ventana").get_child(0).GetIntelecto() == 1:
				Sacarlos()
	if get_node("Imagen/Ventana").get_child_count() != 0:
		get_node("Anima").play("Go", -1, 0.7)
	else:
		get_node("Anima").play("RESET")

func Robar():
	if get_node("Imagen/Actividad").pressed:
		if TomaLibro():
			return "libro"
	return ""

func Produccion(vacante):
	if get_node("Imagen/Actividad").pressed:
		if Libros() < 4:
			if vacante:
				return get_node("Imagen/Ventana").get_child_count() == 0
			else:
				return get_node("Imagen/Ventana").get_child_count() != 0
	return false

func WorkOk():
	if Produccion(true):
		return get_node("Imagen/Ventana")
	return null

func WorkLee():
	if get_node("Imagen/Actividad").pressed:
		if Lectores() < asientos:
			return get_node("Imagen/Salon/Sala")
	return null

func _on_Actividad_toggled(button_pressed):
	get_node("Imagen/Actividad/Sonido").play()
	if not button_pressed:
		Sacarlos()

func EsBodegable():
	if get_node("Imagen/Actividad").pressed:
		return Libros() < 4
	return false

func AbastoFull():
	return Libros() == 4

func GetLibros():
	if get_node("Imagen/Actividad").pressed:
		return Libros() != 0
	return false

func PoneCosa():
	return PoneLibro()

func Sacarlos():
	if get_node("Imagen/Ventana").get_child_count() != 0:
		get_node("Imagen/Ventana").get_child(0).busEmple = false
		get_node("Imagen/Ventana").get_child(0).LiberaEstado()

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
	buffer.put_u8(Libros())
	var a = 1 if get_node("Imagen/Actividad").pressed else 0
	buffer.put_u8(a)

func Open(buffer):
	position.x = buffer.get_float()
	position.y = buffer.get_float()
	var rep = buffer.get_u8()
	for _r in range(rep):
		PoneLibro()
	get_node("Imagen/Actividad").pressed = buffer.get_u8() != 0

func Destruir(humo=true):
	if humo:
		var mundo = get_tree().get_nodes_in_group("mundo")[0]
		mundo.HumoDemolision(self)
	Sacarlos()
	queue_free()

func Deconstruir():
	var aux = load("res://scenes/andamios/C" + nombre + ".tscn").instance()
	var mundo = get_tree().get_nodes_in_group("mundo")[0]
	mundo.get_node("Objetos").add_child(aux)
	aux.position = position
	aux.ModoDemoler()
	Destruir(false)
