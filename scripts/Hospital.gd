extends Node2D

const reservaVacuna = 2 # numero de vacunas a guardar, no las tomaran
var nombre = "" # para demoler

func _ready():
	get_node("Quimicox").start(rand_range(3, 4))
	Nombrar()
	var mundo = get_tree().get_nodes_in_group("mundo")[0]
	mundo.SonidoLen([get_node("SPoner")])

func Nombrar():
	if name.count("@") == 0:
		nombre = name
	else:
		nombre = name.split("@", false)[0]

func Jeringas():
	var tot = 0
	for i in range(4):
		if get_node("Imagen/Jeringa" + str(i + 1)).visible:
			tot += 1
	return tot

func TomaJeringa():
	var jeris = range(4)
	jeris.shuffle()
	for j in jeris:
		if get_node("Imagen/Jeringa" + str(j + 1)).visible:
			get_node("Imagen/Jeringa" + str(j + 1)).visible = false
			return true
	return false

func PoneJeringa():
	var jeris = range(4)
	jeris.shuffle()
	for j in jeris:
		if not get_node("Imagen/Jeringa" + str(j + 1)).visible:
			get_node("Imagen/Jeringa" + str(j + 1)).visible = true
			return true
	return false

func _on_Quimicox_timeout():
	get_node("Quimicox").start(rand_range(3, 4))
	if Produccion(false):
		var i
		for _r in range(4):
			i = randi() % 4
			if not get_node("Imagen/Jeringa" + str(1 + i)).visible:
				get_node("Imagen/Jeringa" + str(1 + i)).visible = true
				get_node("Imagen/Comida").visible = randf() > 0.2
				break
	if get_node("Imagen/Camilla1").get_child_count() != 0:
		get_node("Anima").play("Go", -1, 0.75)
	else:
		get_node("Anima").play("RESET")

func Activo():
	return get_node("Imagen/Actividad").pressed

func AbastoFull():
	return Jeringas() == 4

func PoneComida():
	if not get_node("Imagen/Comida").visible:
		get_node("Imagen/Comida").visible = true
		return true
	return false

func EsNeverable():
	if get_node("Imagen/Actividad").pressed:
		return not get_node("Imagen/Comida").visible
	return false

func EspacioComida():
	return 0 if get_node("Imagen/Comida").visible else 1

func ComidaFull():
	return get_node("Imagen/Comida").visible

func PoneCosa():
	return PoneJeringa()

func Produccion(vacante):
	if get_node("Imagen/Actividad").pressed:
		if vacante:
			return get_node("Imagen/Camilla1").get_child_count() == 0
		elif get_node("Imagen/Comida").visible:
			if Jeringas() < 4:
				return get_node("Imagen/Camilla1").get_child_count() != 0
	return false

func WorkOk():
	if Produccion(true):
		return get_node("Imagen/Camilla1")
	return null

func CamillaOk():
	if get_node("Imagen/Actividad").pressed:
		if get_node("Imagen/Camilla1").get_child_count() != 0 or Jeringas() != 0:
			if get_node("Imagen/Camilla2").get_child_count() == 0:
				return get_node("Imagen/Camilla2")
	return null

func SuficienteVacuna():
	if get_node("Imagen/Actividad").pressed:
		return Jeringas() > reservaVacuna
	return false

func _on_Actividad_toggled(button_pressed):
	get_node("Imagen/Actividad/Sonido").play()
	if not button_pressed:
		Sacarlos()

func CuroAlguien(proporcionSalud):
	# 0:nada, 1:solomedico, 2:vacunas, 3:medicaso
	if Jeringas() == 0:
		if get_node("Imagen/Camilla1").get_child_count() == 0:
			return 0
		elif get_node("Imagen/Camilla1").get_child(0).Sabio():
			return 3
		else:
			return 1
	else:
		if get_node("Imagen/Camilla1").get_child_count() == 0:
			if randf() > proporcionSalud * 0.2:
				TomaJeringa()
		else:
			if randf() > proporcionSalud * 0.05:
				TomaJeringa()
		return 2

func Robar():
	if get_node("Imagen/Actividad").pressed:
		if TomaJeringa():
			return "jeringa"
		elif get_node("Imagen/Comida").visible:
			get_node("Imagen/Comida").visible = false
			return "guaro"
	return ""

func Sacarlos():
	for i in range(2):
		if get_node("Imagen/Camilla" + str(i + 1)).get_child_count() != 0:
			get_node("Imagen/Camilla" + str(i + 1)).get_child(0).LiberaEstado()

func TieneAlgo():
	# evita error desde diamante
	return false

func EsJeringable():
	if get_node("Imagen/Actividad").pressed:
		return Jeringas() < 4
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
	buffer.put_u8(Jeringas())
	var c = 1 if get_node("Imagen/Comida").visible else 0
	buffer.put_u8(c)
	var a = 1 if get_node("Imagen/Actividad").pressed else 0
	buffer.put_u8(a)

func Open(buffer):
	position.x = buffer.get_float()
	position.y = buffer.get_float()
	var rep = buffer.get_u8()
	for _r in range(rep):
		PoneJeringa()
	get_node("Imagen/Comida").visible = buffer.get_u8() != 0
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
